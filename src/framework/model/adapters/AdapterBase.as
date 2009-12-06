package framework.model.adapters 
{
	import flash.events.*;
	
	import framework.cache.*;
	import framework.net.*;
	import framework.model.*;
	import framework.utils.*;
	
	public class AdapterBase extends EventDispatcher
	{
		internal var assets:Assets
		internal var model:ModelBase
		internal var models:Models
		internal var cache:Cache
		
		public function AdapterBase( model:ModelBase, cache:Cache, models:Models )
		{
			super();

			this.model = model;
			this.cache = cache;
			this.models = models;
			assets = new Assets( cache );
		}
		
		public function export( id:int=-1, params:Object=null ) : String
		{
			var clazz:* = models.getModel( model.className );
			return clazz["all"]().toString();
		}
		
		/* // Adapters should have a load method as well.
		public function load(path:String):void {}
		*/
	}
}