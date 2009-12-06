package framework.model 
{
	import flash.events.*;
	
	import framework.cache.*;
	import framework.utils.*;
	
	public class Models extends EventDispatcher
	{
		// Models by name
		private var _byName:Object = {};
		private var _adaptersByModel:Object = {};
		private var _modelColumns:Object = {};
		private var _modelColumnsLocked:Object = {};
		private var _cache:Cache;
		private var _associations:Array;
		private var _loadingModels:Boolean;
		private var _loadingQue:Array = [];
		
		/**
		 *	@constructor
		 *	@param	cache	 Optional reference to the object that all of your model data will be stored
		 */
		public function Models( cache:Cache=null )
		{
			super();
			_cache = cache||new Cache();
			_associations = _cache["associations"] = [];
			addEventListener("modelLoaded", onLoad);
		}
		
		/**
		 *	Add many model Class objects to this models object,
		 *	a model can not be added to 
		 *	@param	...classes	 A rest param of classes to be added
		 */
		public function register( ...classes ):void
		{
			for each( var clazz:Class in classes ) {
				add( clazz );
			}
		}
		
		/**
		 *	Add one model class to this Models object
		 *	@param	clazz	The class that you want to have added to
		 */
		public function add( clazz:Class ):void
		{
			var name:String = StringUtils.className( clazz );
			_byName[ name ] = clazz;
			ModelBase.init( this );
			var instance:* = new clazz();
			_adaptersByModel[ name ] = instance.getAdapter();
			_cache[ name ] = [];
			_modelColumns[ name ] = [];
		}
		
		/**
		 *	Load data and convert to native objects, your adapter should define the datas format
		 *	@param	name	 The models names that you are loading data into
		 *	@param	path	 The url that this data is going to be loaded from
		 */
		public function load( name:String, path:String ):void
		{
			if( !_loadingModels ){
				_loadingModels = true;
				_adaptersByModel[ name ].load( path );
			}else{
				_loadingQue.push( { name:name, path:path } );
			}
		}
		
		/**
		 *	The cache is where all of your model information is saved.
		 *	This includes association and model instances
		 *	@return		Returns a Cache 
		 */
		public function get cache() : Cache
		{
			return _cache;
		}
		
		/**
		 *	If you need a models Class of a certain type this method will return that
		 *	@param	name	 The models names that you are loading data into
		 *	@return	Returns the Class object for a model with this name, the name is case sensitive
		 */
		public function getModel( name:String ) : Class
		{
			return _byName[ name ];
		}
		
		/**
		 *	Add a instance of a model into the cache
		 *	@param	name	 The models names that you are loading data into
		 *	@param	obj	 	 The models instance that you are saving into the model Array
		 *	@return		Returns the index within the Array that the model has beed added at
		 */
		public function push( name:String, obj:* ):int
		{
			return _cache[ name ].push( obj );
		}
		
		/**
		 *	Get all of the columns within a model as an Array
		 *	@param	name	 The models name that you are interfacing with
		 *	@return		Returns an Array of all of the columns with in this model
		 */
		public function columns( name:String ):Array
		{
			if( _modelColumns[ name ] == null ){
				_modelColumns[ name ] = [];
			}
			return _modelColumns[ name ];
		}
		
		/**
		 *	@private
		 *	@param	name	 The models name that you are interfacing with
		 *	@return	Returns a Boolean or null if value has not been set
		 */
		public function columnsLocked( name:String ):Boolean
		{
			return _modelColumnsLocked[ name ];
		}
		
		/**
		 *	Create an instance of a model
		 *	@param	name	 The models name that you are interfacing with
		 *	@return		Return the instance that has been create
		 */
		public function create( name:String, params:Object=null ) : *
		{
			var result:* = new _byName[ name ];
			if( !params ) params = {};

			var index:int = _cache[name].push( result );
			var columns:Array = _modelColumns[ name ];
			
			for(var prop:String in params ){
				if( params[prop] is Array ) {
					var associatedObjects:Array = []
					if( isAssociatedProperty( name, prop ) ) {
						for each(var item:Object in params[prop]){
							item[ name.toLowerCase() + "_id" ] = index;
							if( item is ModelBase ) {
								associatedObjects.push( item );
							}else{
								associatedObjects.push( getAssociationForProperty( name, prop ).create( item ) );
							}
						}
						result[prop] = associatedObjects;
					}else{
						trace( name, "is not associated with", prop );
					}
				}else{
					if( params[prop] is ModelBase ) {
						if( columns.indexOf( prop + "_id" ) != -1 ) {
							result[prop] = params[prop];
							result[prop + "_id"] = params[prop].index;
							result[prop][name.toLowerCase()] = result;
							result[prop][name.toLowerCase() + "_id"] = index;
						}else{
							trace( name, "is not associated with", prop );
						}
					}else if( typeof( params[prop] ) == "object" ){
						result[prop] = _byName[prop][create]( params[prop] );
					}else{
						result[prop] = params[prop];
					}
				}
			}
			
			result.index = index;
			if( columns.indexOf("id") != -1 ){
				result.id = index;
			}
			return result;
		}
		
		/**
		 *	Find models within the cache relative to the condistions passed in
		 *	@param	name	 The models names that you are loading data into
		 *	@param	args	 The Array of arguments that will be sent to the find method
		 *	@return		Return the model object(s) returned, either as an Array or the instance
		 */
		public function find( name:String, args:Array ) : *
		{
			var result:*
			var type:String = args[0]
			var a:Array = [name];
			args.shift(); 
			a.push.apply(null,args);
			switch(type){
				case "first": 			
					result = first.apply(null, a); 
					break;
				case "last":  
					result = last.apply(null, a); 
					break;
				case "all":   
					result = all.apply(null, a); 
					break;
				default : 	  
					result = findById.apply(null, a); 
					break;
			}
			return result
		}
		
		/**
		 *	Find all the models within the cache relative to the condistions passed in
		 *	@param	name	 	 The models names that you are loading data into
		 *	@param	conditions	 An object of name value pairs that must be equal to the instances that are found
		 *	@param	limit	 	 The max number of enteries that can be returned
		 *	@param	offset	 	 The index that the results will start at
		 *	@param	sortOnFields The columns that you want to sort by in the order priority, ["a", "b", "c"]
		 *	@param	sortOptions  The way that you would like to sort these values, [Array.DESCENDING, Array.NUMERIC, Array.CASEINSENSITIVE]
		 *	@return	Returns the model object(s) as an Array
		 */
		public function all( name:String, conditions:Object=null, limit:int=0, offset:int=0, sortOnFields:Object=null, sortOptions:Object=null ):Array
		{
			var all:Array = _cache[name];
			var result:Array = []
			var length:int = limit||all.length
			for( var i:int=offset; i < length; i+= 1 ){
				var item:Object = all[i];
				var conditionLength:int = 0;
				var matchLength:int = 0;
				if(conditions != null){
					for( var condition:String in conditions ){
						if( item[condition] && conditions[condition] && item[condition] == conditions[condition] ) {
							matchLength++;
						}
						conditionLength++;
					}
					if( matchLength == conditionLength ){
						result.push( item );
					}
				}else{
					result.push( item );
				}
			}
			if( (!conditionLength || result.length) && sortOnFields ){
				result = result.sortOn(sortOnFields, sortOptions);
			}
			return result
		}
		
		/**
		 *	Find the first model within the cache relative to the condistions passed in
		 *	@param	name	 	 The models names that you are loading data into
		 *	@param	conditions	 An object of name value pairs that must be equal to the instances that are found
		 *	@param	limit	 	 The max number of enteries that can be returned
		 *	@param	offset	 	 The index that the results will start at
		 *	@param	sortOnFields The columns that you want to sort by in the order priority, ["a", "b", "c"]
		 *	@param	sortOptions  The way that you would like to sort these values, [Array.DESCENDING, Array.NUMERIC, Array.CASEINSENSITIVE]
		 *	@return	Returns the model object instance
		 */
		public function first( name:String, conditions:Object=null, limit:int=0, offset:int=0, sortOnFields:Object=null, sortOptions:Object=null ) : *
		{	
			var result:Array = all( name, conditions, limit, offset, sortOnFields, sortOptions );
			return result[ 0 ];
		}
		
		/**
		 *	Find the last model within the cache relative to the condistions passed in
		 *	@param	name	 	 The models names that you are loading data into
		 *	@param	conditions	 An object of name value pairs that must be equal to the instances that are found
		 *	@param	limit	 	 The max number of enteries that can be returned
		 *	@param	offset	 	 The index that the results will start at
		 *	@param	sortOnFields The columns that you want to sort by in the order priority, ["a", "b", "c"]
		 *	@param	sortOptions  The way that you would like to sort these values, [Array.DESCENDING, Array.NUMERIC, Array.CASEINSENSITIVE]
		 *	@return	Returns the model object instance
		 */
		public function last( name:String, conditions:Object=null, limit:int=0, offset:int=0, sortOnFields:Object=null, sortOptions:Object=null ) : *
		{	
			var result:Array = all( name, conditions, limit, offset, sortOnFields, sortOptions );
			return result[ result.length-1 ];
		}
		
		/**
		 *	Find the model within the cache that has a spacific id
		 *	@param	name The models names that you are loading data into
		 *	@param	id	 The id of the model objecs instace
		 *	@return	Returns the model object instance
		 */
		public function findById( name:String, id:int ) : *
		{
			var result:Object
			for each( var item:Object in _cache[name] ){
				if( item.id == id ) result = item;
			}
			return result
		}
		
		/**
		 *	A dynamic find method that is called internally if something like this,
		 *	
		 *	@param	name 	The models names that you are loading data into
		 *	@param	type	The the column that you are trying to find by
		 *	@param	...rest	A rest param that gets past to the find all method
		 *	@return	Returns the model object(s) as an Array
		 */
		public function findBy( name:String, type:String, ...rest ) : Array
		{
			var a:Array = [name];
			var results:Object = all.apply( null, a.push.apply( null, rest ) );
			var result:Array = [];
			for each( var item:Object in results ){
				if( item[type] == rest[0] ) result.push( item );
			}
			return result;
		}
		
		/**
		 *	Get an association object for a given model name
		 *	@param	name 	The models names that you are loading data into
		 *	@param	prop 	The property on this model that might have an association
		 *	@return		Returns the association object for a given model name
		 */
		public function getAssociationForProperty( name:String, prop:String ) : Object
		{
			return _associations[ (name +"_"+ prop as String).toLowerCase() ];
		}
		
		/**
		 *	Check if this model has an association for a given model name
		 *	@param	name 	The models names that you are loading data into
		 *	@param	prop 	The property on this model that might have an association
		 *	@return	Returns Boolean of true if given model has association for property
		 */
		public function isAssociatedProperty( name:String, prop:String ) : Boolean
		{
			return _associations.hasOwnProperty( (name +"_"+ prop as String).toLowerCase() );
		}
		
		/**
		 *	Export the data from all of the model objects of this type in the models adapter type
		 *	@param	name 	The models names that you are loading data into
		 *	@return	Returns a String formated relative to the models adapter type
		 */
		public function export( name:String, params:Object=null ):String
		{
			return _adaptersByModel[ name ].export( 0, params );
		}
		
		/**
		 *	Delete a object from the cache
		 *	@param	name 	The models names that you are loading data into
		 *	@param	object 	The instance that you want to delete
		 */
		public function destroy( name:String, object:* ):void
		{
			var index:int = _cache[ name ].indexOf( object );
			if( index != -1 ) {
				_cache[ name ].splice( index, 1 );
			}
		}
		
		/**
		 *	@private
		 */
		internal function addAssociation( targetName:String, kind:String, name:String, clazz:Class ) : void
		{
			var columns:Array = _modelColumns[ targetName ];
			if( columns.indexOf( name.toLowerCase() ) == -1 && columnsLocked( targetName ) != true ){
				columns.push( name.toLowerCase() );
			}
			_associations[ (targetName +"_"+ name as String).toLowerCase() ] = { name:name, kind:kind, "class":clazz }
		}
		
		/**
		 *	@private
		 */
		private function onLoad( event:Event ):void
		{
			if( _loadingQue.length == 0 ){
				_loadingModels = false;
				dispatchEvent( new Event( Event.COMPLETE ) );
			}else{
				var obj:Object = _loadingQue.shift();
				_adaptersByModel[ obj.name ].load( obj.path );
			}
		}
	}
}