package com.company.project.model
{
	import framework.model.*;
	import framework.model.adapters.*;

	dynamic public class Character extends ModelBase
	{
		include "../../../../framework/model/ModelUtils.as";
		
		public function Character( params:Object=null )
		{
			super( params );
			setAdapter( CSVAdapter ); // || JSONAdapter || XMLAdapter || YourCustomAdapter
			hasMany( User );
		}
	}
}