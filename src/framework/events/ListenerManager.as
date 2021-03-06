package framework.events  
{	
	import flash.events.*;
	
	public class ListenerManager
	{
		protected var _events:Array;
		protected var _eventDispatcher:EventDispatcher;
		protected var _blockRequest:Boolean;
		
		public function ListenerManager(dispatcher:EventDispatcher) 
		{
			super();
			_eventDispatcher = dispatcher;
			_events = new Array();
		}
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void 
		{
			var info:EventInfo = new EventInfo(type, listener, useCapture);
			
			var l:int = _events.length;
			while (l--)
				if (_events[l].equals(info))
					return;
			
			_events.push(info);
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void 
		{
			if (this._blockRequest)
				return;
			
			var info:EventInfo = new EventInfo(type, listener, useCapture);
			
			var l:int = _events.length;
			while (l--)
				if (_events[l].equals(info))
					_events.splice(l,1);
		}
		/*
		public function removeEventsForType(type:String):void 
		{
			this._blockRequest = true;
			
			var l:int = this._events.length;
			var eventInfo:EventInfo;
			while (l--) {
				eventInfo = this._events[l];
				
				if (eventInfo.type == type) {
					this._events.splice(l, 1);
					
					this._eventDispatcher.removeEventListener(eventInfo.type, eventInfo.listener, eventInfo.useCapture);
				}
			}
			
			this._blockRequest = false;
		}
		
		public function removeEventsForListener(listener:Function):void 
		{
			this._blockRequest = true;
			
			var l:int = this._events.length;
			var eventInfo:EventInfo;
			while (l--) {
				eventInfo = this._events[l];
				
				if (eventInfo.listener == listener) {
					this._events.splice(l, 1);
					
					this._eventDispatcher.removeEventListener(eventInfo.type, eventInfo.listener, eventInfo.useCapture);
				}
			}
			
			this._blockRequest = false;
		}
		*/
		public function removeEventListeners():void 
		{
			_blockRequest = true;
			
			var l:int = _events.length;
			var eventInfo:EventInfo;
			while (l--) {
				eventInfo = _events.splice(l,1)[0];
				_eventDispatcher.removeEventListener(eventInfo.type, eventInfo.listener, eventInfo.useCapture);
			}
			
			_blockRequest = false;
		}
		
		public function destroy():void 
		{
			removeEventListeners();
		}
	}
}

class EventInfo 
{
	public var type:String;
	public var listener:Function;
	public var useCapture:Boolean;

	public function EventInfo(type:String, listener:Function, useCapture:Boolean) 
	{
		super();
		
		this.type       = type;
		this.listener   = listener;
		this.useCapture = useCapture;
	}
	
	public function equals(eventInfo:EventInfo):Boolean 
	{
		return this.type == eventInfo.type && this.listener == eventInfo.listener && this.useCapture == eventInfo.useCapture;
	}
}