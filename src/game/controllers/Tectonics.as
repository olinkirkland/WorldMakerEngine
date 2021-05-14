package game.controllers
{
    import game.Map;
    import game.graph.Cell;

    import global.Color;

    import managers.State;

    import mx.collections.ArrayCollection;

    public class Tectonics
    {
        public static const CHOOSE_PLATE:String = "choosePlate";

        public function Tectonics()
        {
        }

        public static function loadPlates():void
        {
            var plates:Object = State.read("plates");
            var cells:Vector.<Cell> = Map.instance.cells;

            for each (var plate:Object in plates)
                for each (var i:int in plate.cells)
                    cells[i].plate = plate.id;
        }

        public static function getPlate(id:String):Object
        {
            var plates:Object = State.read("plates");
            var plate:Object = plates[id];
            return plate;
        }

        public static function removePlate(id:String):void
        {
            var plates:Object = State.read("plates");
            if (!plates[id])
                return;

            delete plates[id];

            State.write("plates", plates, false);
        }

        public static function addPlate():Object
        {
            var plates:Object = State.read("plates");
            if (!plates)
                plates = {};

            var nextId:Number = -1;
            for (var id:String in plates)
                if (Number(id) > nextId)
                    nextId = Number(id);

            var plate:Object = {
                id: nextId + 1,
                cells: [],
                color: Color.stringToLightColor("foo" + Math.random() * 999),
                strength: 3
            };
            plates[plate.id] = plate;

            State.write("plates", plates, false);
            return plate;
        }

        public static function setPlateOrigin(cell:Cell, id:String):void
        {
            var plate:Object = getPlate(id);
            if (!plate)
                return;

            plate.origin = cell.index;

            State.invalidate("plates");
        }

        public static function addCellToPlate(cell:Cell, id:String):void
        {
            var plate:Object = getPlate(id);
            if (!plate)
                return;

            if (cell.plate)
                removeCellFromPlate(cell, cell.plate);

            plate.cells.push(cell.index);
            cell.plate = id;

            State.invalidate("plates");
        }

        public static function removeCellFromPlate(cell:Cell, id:String):void
        {
            cell.plate = null;

            var plate:Object = getPlate(id);
            if (!plate)
                return;

            plate.cells.removeAt(plate.cells.indexOf(cell));

            State.invalidate("plates");
        }

        public static function calculate():void
        {
            var plates:Object = State.read("plates");
            var arr:Array = [];
            for each (var plate:Object in plates)
                arr.push(plate);

            for each (plate in arr)
                trace(plate.id);
            trace("######");
            arr = arr.sortOn("id");
            for each (plate in arr)
                trace(plate.id);
        }

        public static function plateByOrigin(cell:Cell):Object
        {
            var plates:Object = State.read("plates");
            for each (var plate:Object in plates)
                if (plate.origin == cell.index)
                    return plate;
            return null;
        }
    }
}
