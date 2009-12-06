package com.company.project.model
{
	import framework.model.*;
	import framework.model.adapters.*;
	import framework.utils.*;

	dynamic public class User extends ModelBase
	{
		include "../../../../framework/model/ModelUtils.as";
		
		public function User( params:Object=null )
		{
			super( params );
			setAdapter( XMLAdapter ); // CSVAdapter || JSONAdapter || YourCustomAdapter
			belongsTo( Character ); // Associations

			// Validation
			beforeFilter("username", Validate.email );
			beforeFilter("username", Validate.length, { min:5, max:12 } );
		}
		
		public function get fullName():String
		{ 
			return this.first + " " + this.last; 
		}
	}
}