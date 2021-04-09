package game.task
{
    import game.Layer;

    import managers.State;

    import ui.toolbars.Toolbar;

    public class Task
    {
        public static var tasks:Array;

        public var id:String;
        public var index:int;
        public var toolbar:Class;
        public var layers:Array;

        public function Task()
        {
        }

        public static function get current():Task
        {
            return byId(State.read("task"));
        }

        private static function populateTasks():void
        {
            tasks = [];
            var t:Task;

            // Read Introduction
            tasks.push(t = new Task());
            t.id = TaskId.READ_INTRODUCTION;
            t.index = tasks.length - 1;
            t.toolbar = Toolbar;
            t.layers = [];

            // Make Voronoi Points
            tasks.push(t = new Task());
            t.id = TaskId.MAKE_VORONOI_POINTS;
            t.index = tasks.length - 1;
            t.toolbar = Toolbar;
            t.layers = [Layer.POINTS, Layer.VORONOI];

            // Make Tectonic Plates
            tasks.push(t = new Task());
            t.id = TaskId.MAKE_TECTONIC_PLATES;
            t.index = tasks.length - 1;
            t.toolbar = Toolbar;
            t.layers = [Layer.POINTS, Layer.VORONOI, Layer.TECTONIC_PLATES];
        }

        public static function byId(id:String):Task
        {
            if (!tasks)
                populateTasks();

            for each (var task:Task in tasks)
                if (id == task.id)
                    return task;

            throw new Error("TaskId '" + id + "' not found");
            return null;
        }

        public static function byIndex(i:int):Task
        {
            return tasks[i];
        }
    }
}
