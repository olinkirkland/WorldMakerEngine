package game
{
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.display.Graphics;
    import flash.display.Sprite;
    import flash.geom.Point;

    import game.graph.*;

    import global.Color;

    import global.Color;

    import global.Draw;

    import mx.core.UIComponent;

    public class Artist
    {
        public function Artist()
        {
        }

        public static function draw():void
        {
            for each (var layer:Layer in Map.instance.layers)
            {
                if (!layer.allowed)
                    continue;

                switch (layer.id)
                {
                    case Layer.POINTS:
                        drawPoints();
                        break;
                    case Layer.VORONOI:
                        drawVoronoi();
                        break;
                    case Layer.DELAUNAY:
                        drawDelaunay();
                        break;
                    case Layer.TECTONIC_PLATES:
                        drawTectonicPlates();
                        break;
                }

            }
        }

        public static function drawPoints():void
        {
            var c:UIComponent = Map.instance.canvas.getLayer(Layer.POINTS);
            while (c.numChildren > 0)
                c.removeChildAt(0);
            var spr:Sprite = new Sprite();
            c.addChild(spr);
            var g:Graphics = spr.graphics;

            for each (var p:Point in Map.instance.points)
            {
                g.beginFill(0xffffff);
                g.drawCircle(p.x, p.y, 2);
                g.endFill();
            }

            cacheLayer(c);
        }

        public static function drawVoronoi():void
        {
            var c:UIComponent = Map.instance.canvas.getLayer(Layer.VORONOI);
            while (c.numChildren > 0)
                c.removeChildAt(0);
            var spr:Sprite = new Sprite();
            c.addChild(spr);
            var g:Graphics = spr.graphics;

            for each (var cell:Cell in Map.instance.cells)
                for each (var edge:Edge in cell.edges)
                    if (edge.v0 && edge.v1)
                        Draw.drawLine(g, edge.v0.point, edge.v1.point, Color.white);

            cacheLayer(c);
        }

        public static function drawDelaunay():void
        {
            var c:UIComponent = Map.instance.canvas.getLayer(Layer.DELAUNAY);
            while (c.numChildren > 0)
                c.removeChildAt(0);
            var spr:Sprite = new Sprite();
            c.addChild(spr);
            var g:Graphics = spr.graphics;

            for each (var cell:Cell in Map.instance.cells)
                for each (var edge:Edge in cell.edges)
                    if (edge.d0 && edge.d1)
                        Draw.drawLine(g, edge.d0.point, edge.d1.point, Color.pacificBlue);

            cacheLayer(c);
        }

        public static function drawTectonicPlates():void
        {
            var c:UIComponent = Map.instance.canvas.getLayer(Layer.TECTONIC_PLATES);
            while (c.numChildren > 0)
                c.removeChildAt(0);
            var spr:Sprite = new Sprite();
            c.addChild(spr);
            var g:Graphics = spr.graphics;

            for each (var cell:Cell in Map.instance.cells)
                Draw.fillCell(g, cell, Color.stringToColor(String(cell.plate)));

            cacheLayer(c);
        }

        private static function cacheLayer(c:UIComponent):void
        {
            var bmpd:BitmapData = new BitmapData(2000, 1000, true, 0x000000);
            bmpd.draw(c);
            var bmp:Bitmap = new Bitmap(bmpd);
            bmp.name = "bmp";
            bmp.smoothing = true;

            c.addChild(bmp);
        }
    }
}
