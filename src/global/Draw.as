package global
{
    import flash.display.Graphics;
    import flash.geom.Point;

    public class Draw
    {
        public static function drawLine(graphics:Graphics, point1:Point, point2:Point, color:uint, weight:Number = 1):void
        {
            graphics.lineStyle(weight, color);
            graphics.moveTo(point1.x, point1.y);
            graphics.lineTo(point2.x, point2.y);
            graphics.lineStyle();
        }
    }
}
