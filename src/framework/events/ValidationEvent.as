package framework.events 
{
	import flash.events.Event;

	public class ValidationEvent extends Event 
	{
		public static const ERROR:String = "error";
		public static const SUCCESS:String = "success";
		
		public var message:Object;
	
		public function ValidationEvent( type:String, message:Object, bubbles:Boolean=true, cancelable:Boolean=false )
		{
			this.message = message;
			super(type, bubbles, cancelable);
		}
	
		override public function clone():Event
		{
			return new ValidationEvent(type, message, bubbles, cancelable);
		}
	}
}