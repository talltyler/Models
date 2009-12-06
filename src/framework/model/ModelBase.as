package framework.model 
{
	import flash.events.*;
	import flash.utils.*;
	
	import framework.cache.*;
	import framework.events.*;
	import framework.model.adapters.*;
	import framework.utils.*;
	
	dynamic public class ModelBase extends Proxy implements IEventDispatcher
	{     
		public static const DESTROYED:String = "destroyed";
		public static var models:Models;
		
		public var className:String;		
		public var errors:Array = [];

		private var _adapter:AdapterBase;
		private var _data:Object = {};
		private var _dispatcher:EventDispatcher;
		private var _cache:Cache;
		private var _listenerManager:ListenerManager;
		private var _beforeFilters:Object = {};
		private var _afterFilters:Object = {};
		
		/**
		 *	@constructor
		 *	@param	name	 The name of the model object, this is normally the name of the class
		 */
		public function ModelBase( params:Object=null )
		{	
			super();
			className = StringUtils.className( this );
			_cache = models.cache;
			_dispatcher = new EventDispatcher();
			_listenerManager = new ListenerManager( _dispatcher );
			if( params != null ) {
				create( params );
			}
		}
		
		/**
		 *	Setter for the models data conversion class, an adapter allows different data formats to interface commonly
		 *	@param	value	 A adapter Class
		 */
		public function setAdapter(value:Class):void
		{
			_adapter = new value( this, _cache||new Cache(), models );
			_adapter.addEventListener( Event.COMPLETE, onLoad );
		}
		
		/**
		 *	Getter for the models data conversion class, an adapter allows different data formats to interface commonly
		 *	@return		Returns an instance of the models adapter 
		 */
		public function getAdapter():AdapterBase
		{ 
			return _adapter; 
		}
		
		/**
		 *	Export data within this objects instance as a 
		 *	@return		Returns String formated relative to the models adapter
		 */
		public function export( params:Object = null ):String
		{
			return _adapter.export(this.id , params );
		}
		
		/**
		 *	Destroy this object, clear any listener added to it and take it out of the cache
		 *	When finished it will dispatch a ModelBase.DESTROYED event
		 */
		public function destroy( event:Event=null ):void 
		{
			_listenerManager.destroy();
			models.destroy( className, this );
			_dispatcher.dispatchEvent( new Event( DESTROYED ) );
		}
		
		/**
		 *	Add a before filter to a column, these methods will be called in order before the change 
		 *	of the value of this column is made. These methods have a specific signature, 
		 *	see framework.utils.Validate for examples on how this works.
		 *	@param	column	 Name of the column as a String
		 *	@param	method	 The Function object that will be used to process this changed value
		 *	@param	params	 A Object filled with any items that might need to be used for processing
		 */
		public function beforeFilter( column:String, method:Function, params:Object=null ):void
		{
			if( !_beforeFilters.hasOwnProperty(column) ){
				_beforeFilters[column] = [];
			}
			_beforeFilters[column].push({ method:method, params:params });
		}
		
		/**
		 *	Add a after filter to a column, these methods will be called in order after the change 
		 *	of the value of this column is made. These methods have a specific signature, 
		 *	see framework.utils.Validate for examples on how this works.
		 *	@param	column	 Name of the column as a String
		 *	@param	method	 The Function object that will be used to process this changed value
		 *	@param	params	 A Object filled with any items that might need to be used for processing
		 */
		public function afterFilter( column:String, method:Function, params:Object=null ):void
		{
			if( !_afterFilters.hasOwnProperty(column) ){
				_afterFilters[column] = [];
			}
			_afterFilters[column].push({ method:method, params:params });
		}
		
		//---------------------------------------
		//	EventDispature methods
		//---------------------------------------
		/**
		 *	@see	flash.events.EventDispatcher|#addEventListener Same as EventDispatcher
		 */
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
			_dispatcher.addEventListener(type, listener, useCapture, priority, useWeakReference);
			_listenerManager.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		/**
		 *	@see	flash.events.EventDispatcher|#removeEventListener Same as EventDispatcher
		 */
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
			_dispatcher.removeEventListener(type, listener, useCapture);
			_listenerManager.removeEventListener(type, listener, useCapture);
		}
		
		/**
		 *	@see	flash.events.EventDispatcher|#dispatchEvent Same as EventDispatcher
		 */
		public function dispatchEvent(event:Event):Boolean
		{
			return _dispatcher.dispatchEvent(event);
		}
		
		/**
		 *	@see	flash.events.EventDispatcher|#hasEventListener Same as EventDispatcher
		 */
		public function hasEventListener(type:String):Boolean
		{
			return _dispatcher.hasEventListener(type);
		}
		
		/**
		 *	@see	flash.events.EventDispatcher|#willTrigger Same as EventDispatcher
		 */
		public function willTrigger(type:String):Boolean
		{
			return _dispatcher.willTrigger(type);
		}
		
		/**
		 *	@private 
		 *	  TODO: impliment save to external source
		 */
		public function save():void
		{	
			if( errors.length == 0 ){}
		}
		
		/**
		 *	Used to setup scope to Models, this makes a lot of the magic posible
		 *	@private
		 */
		public static function init( models:Models ):void
		{
			ModelBase.models = models;
		}
		
		//---------------------------------------
		// MODEL ASSOCIATIONS
		//---------------------------------------
		/**
		 *	This method gives you the ability to say that the model that you are working with 
		 *	belongs to another model. This relationship is facilitated with the use of id columns.
		 *	The foreign key should be on the model with the belongsTo association defined.
		 *	If you would like a better understanding of these associations try looking here
		 *	http://guides.rubyonrails.org/association_basics.html
		 */
		protected function belongsTo( clazz:Class ) : void
		{
			var name:String = ( StringUtils.className( clazz ) + "_id" as String).toLowerCase();
			addAssociation( name, "belongsTo", clazz );
		}
		
		/**
		 *	This method gives you the ability to say that the model that you are working is  
		 *	associated with many models of another type. This relationship is facilitated with 
		 *	the use of foreign key columns placed on the associated model.
		 *	If you would like a better understanding of these associations try looking here
		 *	http://guides.rubyonrails.org/association_basics.html
		 */
		protected function hasMany( clazz:Class ) : void
		{
			var name:String = StringUtils.pluralize( StringUtils.className( clazz ) ).toLowerCase();
			addAssociation( name, "hasMany", clazz );
		}
		
		/**
		 *	This method gives you the ability to say that the model that you are working is  
		 *	associated with one model of another type. This relationship is facilitated with 
		 *	the use of foreign key columns placed on the associated model.
		 *	If you would like a better understanding of these associations try looking here
		 *	http://guides.rubyonrails.org/association_basics.html
		 */
		protected function hasOne( clazz:Class ) : void
		{
			var name:String = StringUtils.singularize( StringUtils.className( clazz ) ).toLowerCase();
			addAssociation( name, "hasOne", clazz );
		}
		
		/* // We dont have scope to whatever this join table would be so I dont think this is possible, 
			// will have to find a different way
		protected function hasManyAndBelongsTo( clazz:Class ) : void
		{
			var name:String = StringUtils.singularize( StringUtils.className( clazz ) ).toLowerCase();
			addAssociation( name, "hasManyAndBelongsTo", clazz );
		}
		*/
		
		// TODO: hasMany through relationships
		
		/**
		 *	@private
		 *	If params are sent into the constructor of this object create it and pass the instance to models
		 */
		private function create( params:Object ):void
		{
			var result:* = this;
			var index:int = models.push( className, result );
			var columns:Array = models.columns( className );
			for(var prop:String in params ){
				if( params[prop] is Array ) {
					var associatedObjects:Array = [];
					if( models.isAssociatedProperty( className, prop ) ) {
						for each(var item:Object in params[prop]){
							item[ className.toLowerCase() + "_id" ] = index;
							if( item is ModelBase ) {
								associatedObjects.push( item );
							}else{
								associatedObjects.push( models.getAssociationForProperty( className, prop ).create( item ) );
							}
						}
						result[prop] = associatedObjects;
					}else{
						trace( className, "is not associated with", prop );
					}
				}else{
					if( params[prop] is ModelBase ) {
						if( columns.indexOf( prop + "_id" ) != -1 ) {
							result[prop] = params[prop];
							result[prop + "_id"] = params[prop].index;
							result[prop][className.toLowerCase()] = result;
							result[prop][className.toLowerCase() + "_id"] = index;
						}else{
							trace( className, "is not associated with", prop );
						}
					}else if( typeof( params[prop] ) == "object" ){
						result[prop] = models.getModel(prop)[create]( params[prop] );
					}else{
						result[prop] = params[prop];
					}
				}
			}
			result.index = index;
			if( columns.indexOf("id") != -1 ){
				result.id = index;
			}
		}
		
		/**
		 *	@private
		 *	After an adapter as loaded it's data it will dispatch an event that calls this method, 
		 *	this event is passed on and dispatched from this model
		 */
		private function onLoad(event:Event):void
		{
			dispatchEvent( event );
		}
		
		/**
		 *	@private
		 *	This is just a method to simplify the creation of the other associations above,
		 *	belongsTo, hasOne, and hasMany all call this method
		 */
		private function addAssociation( name:String, type:String, clazz:Class ) : void
		{
			var columns:Array = models.columns( className );
			if( columns.indexOf( name ) == -1 && models.columnsLocked( className ) != true ) {
				columns.push( name );
			}
			models.addAssociation( className, type, name, clazz )
		}
		
		/**
		 *	@private
		 *	Any method that isn't defined on the model will be sent here.
		 */
		private function methodMissing( method:*, args:Array ) : Object
		{
			if( method.substring(0,6) == "findBy" ){
				return models.findBy( className, method.split("findBy")[1], args );
			}
			trace("methodMissing", method, args)
			return null;
		}
		
		/**
		 *	@private
		 *	After a setProperty is finished it calls this method to set the property and call the after filters 
		 */
		private function setPropertyComplete( name:String, value:*, result:Object, errors:Array):void
		{
			if( errors.length == 0 ) {
				if( flash_proxy::isAttribute(name) ){
					this[name] = value;
				}else{
					_data[name] = value;
				}
				if( _afterFilters.hasOwnProperty(name) ){
					for each( var filter:Object in _afterFilters[name] ){
						filter.method( this, name, value, filter.params );
					}
				}
				_dispatcher.dispatchEvent( new Event( Event.CHANGE ) );
			}else{
				this.errors.apply(null,errors); // apply the errors to the models errors array
				_dispatcher.dispatchEvent( new ValidationEvent( ValidationEvent.ERROR, errors ) );
			}
		}
		
		/**
		 *	@private
		 */
		private function onFilterFinished( event:ValidationEvent ):void 
		{
			setPropertyComplete( event.message.name, event.message.value, event.message.result, event.message.errors);
		}
		
		//---------------------------------------
		// flash_proxy methods
		//---------------------------------------
		/**
		 *	Call before filters set property and then call after filters
		 *	@inheritDoc
		 *	
		 */
		override flash_proxy function setProperty(name:*, value:*):void 
		{	
			var errors:Array = [];
			var filter:Object;
			var result:Object;
			var hasDispatcher:Boolean;
			if( _beforeFilters.hasOwnProperty(name) ){
				for each( filter in _beforeFilters[name] ){
					result = filter.method( this, name, value, filter.params );
					if( result != null ){
						if( result.dispatcher != null ) {
							result.dispatcher.addEventListener( Event.COMPLETE, onFilterFinished );
							hasDispatcher = true;
						}else{
							if( result.errors != null ) {
								errors.push(result.errors);
							}
							if( result.value != null ) {
								value = result.value;
							}
						}
					}
				}
				if( !hasDispatcher ) {
					setPropertyComplete( name, value, result, errors);
				}
			}else{
				setPropertyComplete( name, value, result, errors);
			}
        }
		
		/**
		 *	@inheritDoc
		 */
        override flash_proxy function getProperty(name:*):* 
		{	
			if( flash_proxy::isAttribute(name) ){
				return this[name];
			}else if( _data.hasOwnProperty(name) ){
				return _data[name];
			}
			trace( name, "could not be found on", className );
            return null;
        }
		
		/**
		 *	@inheritDoc
		 */
        override flash_proxy function hasProperty(name:*):Boolean 
		{
            return _data.hasOwnProperty(name); //trace("hasProperty", name);
        }
		
		/**
		 *	@inheritDoc
		 */
		override flash_proxy function deleteProperty(name:*):Boolean 
		{
			_dispatcher.dispatchEvent( new Event( Event.CHANGE ) );
            return delete _data[name];
        }	
		
		/**
		 *	@inheritDoc
		 */
		override flash_proxy function callProperty(method:*, ...args) : * 
		{
			try { 		 
				var clazz : Class = getDefinitionByName(getQualifiedClassName(this)) as Class;
				return clazz.prototype[method].apply(method, args);
		   	}catch (e : Error) {
				return methodMissing(method, args);
		   	}
		}
	}
}