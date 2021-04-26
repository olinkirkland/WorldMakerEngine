package game
{
    import game.task.Task;

    import managers.State;

    import mx.collections.ArrayCollection;
    import mx.events.CollectionEvent;

    import spark.primitives.Graphic;

    public class Map
    {
        public var layers:ArrayCollection = new ArrayCollection();
        public var layersById:Object = {};

        private static var _instance:Map;
        private var defaultLayerOrder:Array = [Layer.POINTS, Layer.VORONOI, Layer.TECTONIC_PLATES];

        public function Map()
        {
            if (_instance)
                throw new Error("Singletons can only have one instance");
            _instance = this;

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

            layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayersChange);
        }

        public static function get instance():Map
        {
            if (!_instance)
                new Map();
            return _instance;
        }

        public function resetLayers():void
        {
            for (var i:int = 0; i < defaultLayerOrder.length; i++)
            {
                var id:String = defaultLayerOrder[i];
                trace("finding " + i + " (" + id + ")");
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

        public function draw(g:Graphic, layerId:String):void
        {
            // Draws the content of a layer onto a graphic
        }
    }
}
