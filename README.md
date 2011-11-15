# MagicalRecord for Core Data

In software engineering, the active record pattern is a design pattern found in software that stores its data in relational databases. It was named by Martin Fowler in his book Patterns of Enterprise Application Architecture. The interface to such an object would include functions such as Insert, Update, and Delete, plus properties that correspond more-or-less directly to the columns in the underlying database table.

>	Active record is an approach to accessing data in a database. A database table or view is wrapped into a class; thus an object 	instance is tied to a single row in the table. After creation of an object, a new row is added to the table upon save. Any object	loaded gets its information from the database; when an object is updated, the corresponding row in the table is also updated. The	wrapper class implements accessor methods or properties for each column in the table or view.

>	*- [Wikipedia]("http://en.wikipedia.org/wiki/Active_record_pattern")*

Magical Record for Core Data was inspired by the ease of Ruby on Rails’ Active Record fetching. The goals of this code are to:

* Clean up my Core Data related code.
* Allow for clear, simple, one-line fetches.
* Still allow the modification of the `NSFetchRequest` when request optimizations are needed.

# Installation

1. In your Xcode Project, add all the `.h` and `.m` files from the *Source* folder into your project. 
2. Add *CoreData+MagicalRecord.h* file to your `.pch` file or your `AppDelegate` file.
3. Start writing code! There is no step 3!

# ARC Support

MagicalRecord will not directly support ARC at this time. However, MagicalRecord will work with ARC enabled, by adding the *-fno-objc-arc* flag to the following files:

* *NSManagedObjectContext+MagicalRecord.m*
* *NSManagedObject+MagicalDataImport.m*
* *MagicalRecordHelpers.m*

# Usage

## Setting up the Core Data Stack

To get started, first, import the header file *CoreData+MagicalRecord.h* in your project’s `.pch` file. This will allow a global include of all the required headers. If you don’t want auto migration, an in-memory store, or a special name for your stack, simply start working! Otherwise, somewhere in your app delegate, in either the `-applicationDidFinishLaunching:withOptions:` method, or `-awakeFromNib`, use **one** of the following setup calls with the MagicalRecordHelpers class:

	+ (void) setupAutoMigratingDefaultCoreDataStack;
	+ (void) setupCoreDataStackWithInMemoryStore;
	+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName;
	+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;

Each call instantiates one of each piece of the Core Data stack, and provides getter and setter methods for these instances. These well known instances to MagicalRecord, and are recognized as “defaults”.

And, before your app exits, you can use the clean up method:

	[MagicalRecordHelpers cleanUp];

### Default Managed Object Context 

When using Core Data, you will deal with two types of objects the most: `NSManagedObject` and `NSManagedObjectContext`. MagicalRecord for Core Data gives you a place for a default NSManagedObjectContext for use within your app. This is great for single threaded apps. If you need to create a new Managed Object Context for use in other threads, based on your single persistent store, use:

	NSManagedObjectContext *myNewContext = [NSManagedObjectContext context];

This default context will be used for all fetch requests, unless otherwise specified in methods ending in `inContext:`.
If you want to make `myNewContext` the default for all fetch requests on the main thread:

	[NSManagedObjectContext setDefaultContext:myNewContext];

This will use the same object model and persistent store, but create an entirely new context for use with threads other than the main thread. 

**It is *highly* recommended that the default context is created and set using the main thread**

### Fetching

#### Basic Finding

Most methods in MagicalRecord return an `NSArray` of results. So, if you have an Entity called *Person*, related to a *Department* (as seen in various Apple Core Data documentation), to get all the *Person* entities from your persistent store:

	NSArray *people = [Person findAll];

Or, to have the results sorted by a property:

	NSArray *peopleSorted = [Person findAllSortedByProperty:@"LastName" ascending:YES];

If you have a unique way of retrieving a single object from your data store, you can get that object directly:

	Person *person = [Person findFirstByAttribute:@"FirstName" withValue:@"Forrest"];

#### Advanced Finding

If you want to be more specific with your search, you can send in a predicate:

	NSArray *departments = [NSArray arrayWithObjects:dept1, dept2, ..., nil];
	NSPredicate *peopleFilter = [NSPredicate predicateWithFormat:@"Department IN %@", departments];

	NSArray *people = [Person findAllWithPredicate:peopleFilter];

#### Returning an `NSFetchRequest`

	NSPredicate *peopleFilter = [NSPredicate predicateWithFormat:@"Department IN %@", departments];

	NSArray *people = [Person fetchAllWithPredicate:peopleFilter];

For each of these single line calls, a full stack of `NSFetchRequest`, `NSSortDescriptor`s, and a simple default error handling scheme (i.e., logging to the console) is created.

#### Customizing the Request

	NSPredicate *peopleFilter = [NSPredicate predicateWithFormat:@"Department IN %@", departments];

	NSFetchRequest *peopleRequest = [Person requestAllWithPredicate:peopleFilter];
	[peopleRequest setReturnsDistinctResults:NO];
	[peopleRequest setReturnPropertiesNamed:[NSArray arrayWithObjects:@"FirstName", @"LastName", nil]];
	...

	NSArray *people = [Person executeFetchRequest:peopleRequest];

#### Find the Number of Entities

You can also perform a count of entities in your store, that will be performed on the Store

	NSNumber *count = [Person numberOfEntities];

Or, if you’re looking for a count of entities based on a predicate or some filter:

	NSNumber *count = [Person numberOfEntitiesWithPredicate:...];
	
There are also counterpart methods which return `NSUInteger` rather than `NSNumber`s:

    - (NSUInteger) countOfEntities
    - (NSUInteger) countOfEntitiesWithContext:(NSManagedObjectContext *)
    - (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)
    - (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *) inContext:(NSManagedObjectContext *)

#### Finding from a different context

All find, fetch and request methods have an inContext: method parameter

	NSManagedObjectContext *someOtherContext = ...;

	NSArray *peopleFromAnotherContext = [Person findAllInContext:someOtherContext];

	...

	Person *personFromContext = [Person findFirstByAttribute:@"lastName" withValue:@"Gump" inContext:someOtherContext];

	...

	NSUInteger count = [Person numberOfEntitiesWithContext:someOtherContext];


## Creating new Entities

When you need to create a new instance of an Entity, use:

	Person *myNewPersonInstance = [Person createEntity];

or, to specify a context:

	NSManagedObjectContext *otherContext = ...;
	Person *myPerson = [Person createInContext:otherContext];

## Deleting Entities

To delete a single entity:

	Person *p = ...;
	[p deleteEntity];

or, to specify a context:

	NSManagedObjectContext *otherContext = ...;
	Person *deleteMe = ...;

	[deleteMe deleteInContext:otherContext];

There is no *truncate* (delete all entities) operation in core data, so one is provided for you with Active Record for Core Data:

	[Person truncateAll];

or, with a specific context:

	NSManagedObjectContext *otherContext = ...;
	[Person truncateAllInContext:otherContext];

## Performing Core Data operations on Threads

Available only on iOS 4.0 and Mac OS X 10.6.

Paraphrasing the [Apple documentation on Core Data and Threading]("http://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/Articles/cdConcurrency.html#//apple_ref/doc/uid/TP40003385-SW1"), you should always:

* Use a new, dedicated `NSManagedObjectContext` instance for every thread.
* Use an instance of your `NSManagedObjects` that is local for the new `NSManagedObjectContext`.
* Notify other contexts that the background is updated or saved.

The Magical Record library is trying to make these steps more reusable with the following methods:

	+ (void) performSaveDataOperationWithBlock:(CoreDataBlock)block;
	+ (void) performSaveDataOperationInBackgroundWithBlock:(CoreDataBlock)block;

`CoreDataBlock` is typedef’d as:

	typedef void (^CoreDataBlock)(NSManagedObjectContext *);
	
All the boilerplate operations that need to be done when saving are done in these methods. To use this method from the *main thread*:

	Person *person = ...;
	[MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext){
		Person *localPerson = [person inContext:localContext];

		localPerson.firstName = @"Chuck";
		localPerson.lastName = @"Smith";
	}];
	
In this method, the `CoreDataBlock` provides you with the proper context in which to perform your operations, you don’t need to worry about setting up the context so that it tells the default context that it’s done, and should update because changes were performed on another thread.

All `MRCoreDataAction`s have a dedicated GCD queue on which they operate. This means that throughout your app, you only really have 2 queues (somewhat like threads) performing Core Data actions at any one time: one on the main queue, and another on this dedicated GCD queue.

# Data Import

*Experimental*

MagicalRecord will now import data from `NSDictionary`s into your Core Data store. This feature is currently under development, and is undergoing updates. Feel free to try it out, add tests and send in your feedback.
	
# Extra Bits

This Code is released under the MIT License by [Magical Panda Software, LLC.](http://www.magicalpanda.com)
