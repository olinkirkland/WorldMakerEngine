package game.controllers
{
    import game.graph.Cell;

    import managers.State;

    public class Tectonics
    {
        public function Tectonics()
        {
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

            var plate:Object = {id: nextId + 1, cells: []};
            plates[plate.id] = plate;

            State.write("plates", plates, false);
            return plate;
        }

        public static function addCellToPlate(cell:Cell, id:String):void
        {
            var plate:Object = getPlate(id);
            if (!plate)
                return;

            if (!cell.plate)
                removeCellFromPlate(cell, cell.plate);

            plate.cells.push(cell.index);
            cell.plate = id;
        }

        public static function removeCellFromPlate(cell:Cell, id:String):void
        {
            cell.plate = null;

            var plate:Object = getPlate(id);
            if (!plate)
                return;

            plate.cells.removeAt(plate.cells.indexOf(cell));
        }
    }
}
