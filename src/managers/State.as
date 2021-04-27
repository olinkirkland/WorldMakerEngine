package managers
{
    import events.StateEvent;

    import flash.events.Event;
    import flash.events.EventDispatcher;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;

    public class State
    {
        public static const STATE_CHANGED:String = "stateChanged";

        public static var callbackSave:Function = standaloneSave;

        private static var currentState:Object;

        public static var dispatcher:EventDispatcher = new EventDispatcher();
        public static var loaded:Boolean = false;

        public static function write(id:String, value:*, check:Boolean = true):*
        {
            if (check)
            {
                // Ignore if it's the same
                if (JSON.stringify(read(id)) == JSON.stringify(value))
                    return;

                if (getPropertyByPath(id))
                    trace("@State: (" + id + ") " + JSON.stringify(getPropertyByPath(id)) + " >> " + JSON.stringify(value));
                else
                    trace("@State: (" + id + ") >> " + JSON.stringify(value));
            }
            // Sets a property in the current state
            setPropertyByPath(id, value);

            dispatcher.dispatchEvent(new StateEvent(STATE_CHANGED, id));

            return value;
        }

        public static function read(id:String):*
        {
            // Gets a property in the current state
            return getPropertyByPath(id);
        }

        private static function getPropertyByPath(path:String):*
        {
            // Paths are delimited by dot notation
            var obj:* = currentState;
            var arr:Array = path.split(".");
            for each (var key:String in arr)
            {
                if (!obj.hasOwnProperty(key))
                    return null;

                obj = obj[key];
            }

            return obj;
        }

        private static function setPropertyByPath(path:String, value:*):void
        {
            // Paths are delimited by dot notation
            var obj:* = currentState;
            var arr:Array = path.split(".");
            for (var i:int = 0; i < arr.length; i++)
            {
                var key:String = arr[i];

                if (i == arr.length - 1)
                    obj[key] = value;

                if (!obj.hasOwnProperty(key))
                    obj[key] = {};

                obj = obj[key];
            }
        }

        public static function save():void
        {
            if (callbackSave != null)
                callbackSave.apply(null, [currentState]);
        }

        private static function standaloneSave(u:Object):void
        {
            // Only triggered in standalone mode
            var fileStream:FileStream = new FileStream();
            fileStream.open(File.applicationStorageDirectory.resolvePath("localSave.json"), FileMode.WRITE);
            fileStream.writeUTFBytes(JSON.stringify(u));
            fileStream.close();
        }

        public static function load(u:Object):void
        {
            currentState = u;
            loaded = true;

            dispatcher.dispatchEvent(new Event(State.STATE_CHANGED));
        }

        public static function loadLocal():void
        {
            // Only triggered in standalone mode
            var file:File = File.applicationStorageDirectory.resolvePath("localSave.json");
            if (!file.exists)
            {
                currentState = {};
                return;
            }

            var fileStream:FileStream = new FileStream();
            fileStream.open(file, FileMode.READ);
            var json:String = fileStream.readUTFBytes(fileStream.bytesAvailable);
            fileStream.close();

            currentState = JSON.parse(json);

            dispatcher.dispatchEvent(new Event(State.STATE_CHANGED));
        }
    }
}