package managers
{
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

        public static function write(id:String, data:*):void
        {
            // Sets a property in the current state
            trace(id + " was changed from " + currentState[id] + " to '" + data + "'");
            currentState[id] = data;

            dispatcher.dispatchEvent(new Event(STATE_CHANGED));
        }

        public static function read(id:String):*
        {
            // Gets a property in the current state
            return currentState[id];
        }

        public static function save():void
        {
            if (callbackSave)
                callbackSave.apply(null, [currentState]);
        }

        private static function standaloneSave(u:Object):void
        {
            // Only triggered in standalone mode
            var fileStream:FileStream = new FileStream();
            fileStream.open(File.applicationStorageDirectory.resolvePath("localSave.json"), FileMode.WRITE);
            fileStream.writeUTFBytes(JSON.stringify(u, null, " "));
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