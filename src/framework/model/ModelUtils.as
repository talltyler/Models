// This file should be included into every model in your application like so...
// 	 include "../../../../framework/model/ModelUtils.as";

import framework.utils.*;
private static var name:String;

/** Create a new model object
 */
public static function create( params:Object=null ) : * {
	return models.create( getName(), params );
}

/** Export all items as a String formated relative to the models adapter
 */
public static function export( params:Object=null ) : String {
	return models.export( getName(), params );
}

/** Load data and convert to native objects, your adapter should define the datas format
 */
public static function load( path:String ) : void {
	models.load( getName(), path );
}

/** Find model objects of this models type
 */
public static function find( ...args ) : * {
	return models.find( getName(), args );
}

/** Return an Array of all of the models of this models type that meet all of the parameters conditions
 */
public static function all( conditions:Object=null, limit:int=0, offset:int=0, sortOnFields:Object=null, sortOptions:Object=null ) : Array {	
	return models.all( getName(), conditions, limit, offset, sortOnFields, sortOptions );
}

/** Return the first model of this models type that meet all of the parameters conditions
 */
public static function first( conditions:Object=null, limit:int=0, offset:int=0, sortOnFields:Object=null, sortOptions:Object=null ) : * {	
	return models.first( getName(), conditions, limit, offset, sortOnFields, sortOptions );
}

/** Return the last model of this models type that meet all of the parameters conditions
 */
public static function last( conditions:Object=null, limit:int=0, offset:int=0, sortOnFields:Object=null, sortOptions:Object=null ) : * {
	return models.last( getName(), conditions, limit, offset, sortOnFields, sortOptions );
}

/** Return the model of this models type that has this id
 */
public static function findById( id:int ) : * {
	return models.findById( getName(), id );
}

/**	Return the name of the class
 */
public static function getName() : String {
	if( name == null ) {
		name = StringUtils.className( prototype.constructor );
	}
	return name;
}