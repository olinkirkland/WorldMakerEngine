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

        public function Map()
        {
            var arr:Array = State.read("layers");
            if (arr)
            {
                // Custom layer order
                for each(var l:Object in arr)
                {
                    var layer:Layer = new Layer();
                    layer.id = l.id;
                    layer.visible = l.visible;
                    layersById[l.id] = layer;
                    layers.addItem(layer);
                }
            } else
            {
                // Default layer order
                var layerOrder:Array = [Layer.POINTS, Layer.VORONOI, Layer.TECTONIC_PLATES];
                for each (var id:String in layerOrder)
                {
                    var layer:Layer = new Layer();
                    layer.id = id;
                    layersById[id] = layer;
                    layers.addItem(layer);
                }
            }

            layers.addEventListener(CollectionEvent.COLLECTION_CHANGE, onLayersChange);
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
