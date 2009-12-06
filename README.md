# Models

This project is a way to handle Models within an ActionScript project. It's based loosely on rails ActiveRecord classes which is based on a design pattern called ActiveRecord. 


## Why is Models different

Model objects within ActionScript MVC frameworks often are simply structures to cordon off your models objects. This project try to help you out and handle the standard cases and gives you to structure to handle all types of data and the things that you might need to do to it.


## Key Features

* Model adapters are planed for every data format including synchronous and asynchronous communication with the server.
* Build relationships between your models with associations, belongsTo, hasOne, and hasMany relationships currently supported. 
* Validations and data modifiers using before and after filters on each column of each model.
* Look for and build collections of model objects with powerful find methods including dynamic find methods giving you very fine grain control for looking things up.
* Internal model object registration without any other code. Simply create objects the normal way with the new keyword and a model can use all of the helper methods to find it or modify it later.
* Change events are fired any time a model object value is changed.
* No singletons used for flexibility and testing in mind.


## Basic Usage

Somewhere in your project you need to create an instance of Models and register the models that you are going to use.

	var models:Models = new Models();
	models.register( User, Character );
	models.addEventListener( Event.COMPLETE, onLoad );

Here is a sample model object. You can think of this object as a single item within your model.

	package com.company.project.model
	{
		import framework.model.*;
		import framework.model.adapters.*;

		dynamic public class User extends ModelBase
		{
			include "../../../../framework/model/ModelUtils.as";

			public function User( params:Object=null )
			{
				super( params );
				setAdapter( CSVAdapter ); // || XMLAdapter || JSONAdapter || AMFAdapter || YourCustomAdapter
				hasMany( Character );
			}
		}
	}

After your model is created you can interface with it in many ways.
	
	var user:User = new User(); // This will create a new User object and store it automaticly with any other object that have been created.
	user.name = "Tyler Larson"; // You can set any value on theses object unless you lock the columns
	trace( user.createdAt ); // createdAt, modifiedAt and index columns are automaticly generated

Also if you have data in an external location you can load it all into your model in whatever format your adapter is set to. The complete event that we defined on our Models instance will be fired when they are loaded.

	User.load("/data.xml");

Once you have a few model objects you can use the find methods:

    User.find("all",{name:"Tyler Larson"}, limit, offset, ["createdAt"], [Array.DESCENDING]);
	User.first({name:"Tyler Larson"});
	User.last();
	User.findById(1);

If at any point you need to export your models we provide methods to help with that.
	
	User.findById(1).export(); // Export the user with id 1
	User.export(); // Export all user data

When you are done with your model object you can call destroy to clean everything up.

	User.findById(1).destroy();


## What's next

Please download and give it a try, if you find any bugs please tell me I will fix them as soon as I can. If you would like to help contribute your help is more than welcome.
	