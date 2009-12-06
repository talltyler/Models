package {

	import flash.events.*;
	import flash.display.*;
	
	import com.company.project.model.*;
	
	import framework.*;
	import framework.model.*;
	import framework.utils.*;

	/**
	 *  This is an example of how to handle the model
	 *	It is loosly based off of the ideas of ActiveRecord
	 */
	public class Main extends Sprite 
	{
		
		public function Main()
		{
			super();

			var models:Models = new Models();
			models.register( User, Character );
			models.addEventListener( Event.COMPLETE, onLoad );
			
			// Importing data into your model
			Character.load( 'assets/data/characters.csv' );
			User.load( 'assets/data/users.xml' ); // notice they are different types of data
		}

		private function onLoad( event:Event ):void
		{
			/*
			// Finding objects
			//  All find methods have these arguments besides findById()
			//	 conditions, limit, offset, sortOnFields, sortOptions
			user = User.find("first", { id:2 });
			users = User.find("all", { character_id:1 }, 10, 1, ["id"]);
			var user34:User = User.findById(2);
			users = User.all({name:'Tyler Larson'});
			user = User.first();
			user = User.last(); */
			var user:Array = User.find("all", {character_id:1}, 10, 0, ["id"], [Array.DESCENDING]);
			
			// Creating new objects
			var users:Array = User.all();
			var character:Character = new Character( { first:"first1", last:"last1", users:users } );
			//trace(character.users, "character.users");
			
			// Export data to adpter format as a String
			trace( User.export({exclude:["character_id"]}) ); //  Export all User objects as String excluding last column
			trace("----------------------------")
			trace( character.export() ); // Export single object.
			
			// Deleting
			user.destroy();	
		}
	}
}