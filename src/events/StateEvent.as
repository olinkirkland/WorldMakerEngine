package events
{
    import flash.events.Event;

    public class StateEvent extends Event
    {
        public var id:String;

        public function StateEvent(type:String, id:String = null, bubbles:Boolean = false, cancelable:Boolean = false)
        {
            super(type, bubbles, cancelable);
            this.id = id;
        }
    }
}
