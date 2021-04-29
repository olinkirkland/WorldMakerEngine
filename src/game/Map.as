package game
{
    import events.StateEvent;

    import flash.display.Graphics;

    import flash.geom.Rectangle;

    import game.graph.QuadTree;

    import game.task.Task;

    import geom.Coord;

    import global.Rand;
    import global.Util;

    import managers.State;

    import mx.collections.ArrayCollection;
    import mx.events.CollectionEvent;

    import spark.primitives.Graphic;

    import ui.components.Canvas;

    public class Map
    {
        public var layers:ArrayCollection = new ArrayCollection();
        public var layersById:Object = {};

        public var invalid:Object = {};

        private var bounds:Rectangle;
        private var points:Vector.<Coord>;
        private var quad:QuadTree;

        private static var _instance:Map;
        private var defaultLayerOrder:Array = [Layer.POINTS, Layer.VORONOI, Layer.TECTONIC_PLATES];
        private var categories:Array = ["dragArea", "points"];
        private var canvas:Canvas;

        public function Map(canvas:Canvas)
        {
            if (_instance)
                throw new Error("Singletons can only have one instance");
            _instance = this;

            this.canvas = canvas;

            defaultLayerOrder.reverse();

            var arr:Array = State.read("layers");
            var layer:Layer;
            if (arr)
            {
                // Custom layer order
                for each(var l:Object in arr)
                {
                    layer = new Layer();
                    layer.id = l.id;
                    layer.visible = l.visible;
                    layersById[l.id] = layer;
                    layers.addItem(layer);
                }
            } else
            {
                // Default layer order
                for each (var id:String in defaultLayerOrder)
                {
                    layer = new Layer();
                    layer.id = id;
                    layer.visible = true;
                    layersById[id] = layer;
                    layers.addItem(layer);
                }
            }

            State.dispatcher.addEventListener(State.STATE_CHANGED, onStateChanged);
            layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayersChange);

            calculate(true);
        }

        public function getNearestPoint(p:Coord):Coord
        {
            // Only return a point within a reasonable range
            var arr:Vector.<Coord> = quad.queryFromPoint(p, 5);
            return (arr.length == 0) ? null : arr[0];
        }

        private function onStateChanged(event:StateEvent):void
        {
            var category:String = event.id.split(".")[0];
            if (categories.indexOf(category) >= 0)
                invalid[category] = true;
        }

        public function calculate(force:Boolean = false):void
        {
            // The force argument recalculates every category
            if (force)
                for each (var str:String in categories)
                    invalid[str] = true;

            // Loop through all invalidated categories and reload them
            for (var category:String in invalid)
            {
                trace("@Map, calculate: " + category);

                switch (category)
                {
                    case "dragArea":
                        drawDragArea();
                        break;
                    case "points":
                        makePoints();
                        drawPoints();
                        break;
                    default:
                        break;
                }
            }

            invalid = [];
        }

        private function drawDragArea():void
        {
            var g:Graphics = canvas.getLayer("dragArea").graphics;
            g.clear();
            g.lineStyle(1, 0xff0000);
            g.beginFill(0xff0000, .2);
            g.drawRect(0, 0, 2000, 1000);
            g.endFill();
        }

        private function makePoints():void
        {
            bounds = new Rectangle(0,
                    0,
                    2000,
                    1000);
            points = new Vector.<Coord>();
            quad = new QuadTree(bounds);

            var type:String = State.read("points.type");
            switch (type)
            {
                case "poissonDisc":
                    break;
                case "square":
                    break;
                case "hex":
                    break;
                case "random":
                    makeRandomPoints();
                    break;
            }

            State.write("points.points", points, false);
        }

        private function addPoint(p:Coord):void
        {
            points.push(p);
            quad.insert(p);
        }

        private function makeRandomPoints():void
        {
            var rand:Rand = new Rand(Util.stringToSeed(State.read("points.seed")));
            var amount:int = State.read("points.amount");
            for (var i:int = 0; i < amount; i++)
            {
                // Add a random point
                var p:Coord = new Coord(int(rand.between(0, bounds.width)), int(rand.between(0, bounds.height)));
                addPoint(p);
            }
        }

        private function drawPoints():void
        {
            var g:Graphics = canvas.getLayer("points").graphics;
            g.clear();
            g.lineStyle(1, 0xffffff);
            for each (var p:Coord in points)
                g.drawCircle(p.x, p.y, 3);
        }

        public static function get instance():Map
        {
            if (!_instance)
                new Map(null);
            return _instance;
        }

        public function resetLayers():void
        {
            for (var i:int = 0; i < defaultLayerOrder.length; i++)
            {
                var id:String = defaultLayerOrder[i];
                for (var j:int = 0; j < layers.length; j++)
                {
                    var l:Layer = layers[j];
                    if (l.id != id)
                        continue;

                    l.visible = true;
                    layers.addItemAt(layers.removeItemAt(j), i);
                }
            }
        }

        private function onLayersChange(event:CollectionEvent):void
        {
            var arr:Array = [];
            for each (var layer:Layer in layers)
                arr.push({
                    id: layer.id,
                    visible: layer.visible
                });

            State.write("layers", arr);
        }

        public function validateAllowedLayers():void
        {
            for each (var layer:Layer in layers)
            {
                var b:Boolean = Task.current.layers.indexOf(layer.id) >= 0;
                if (layer.allowed != b)
                {
                    layer.allowed = b;
                    layers.itemUpdated(layer);
                }
            }
        }
    }
}