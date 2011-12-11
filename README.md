# Magical Record for Core Data

In software engineering, the active record pattern is a design pattern found in software that stores its data in relational databases. It was named by Martin Fowler in his book Patterns of Enterprise Application Architecture. The interface to such an object would include functions such as Insert, Update, and Delete, plus properties that correspond more-or-less directly to the columns in the underlying database table.

>	Active record is an approach to accessing data in a database. A database table or view is wrapped into a class; thus an object 	instance is tied to a single row in the table. After creation of an object, a new row is added to the table upon save. Any object	loaded gets its information from the database; when an object is updated, the corresponding row in the table is also updated. The	wrapper class implements accessor methods or properties for each column in the table or view.

>	*- [Wikipedia]("http://en.wikipedia.org/wiki/Active_record_pattern")*

Magical Record for Core Data was inspired by the ease of Ruby on Rails’ Active Record fetching. The goals of this code are to:

* Clean up my Core Data related code.
* Allow for clear, simple, one-line fetches.
* Still allow the modification of the `NSFetchRequest` when request optimizations are needed.

Magical Record requires iOS 4.0 or Mac OS 10.6.

# Installation

1. In your Xcode Project, add all the `.h` and `.m` files from the *Source* folder into your project. 
2. Add *MagicalRecord.h* file to your `.pch` file or your `AppDelegate` file.
3. Start writing code! There is no step 3!

# Usage

## Setting up the Core Data Stack

To get started, first, import the header file *MagicalRecord.h* in your project’s `.pch` file. This will allow a global include of all the required headers. If you don’t want auto migration, an in-memory store, or a special name for your stack, simply start working! Otherwise, somewhere in your app delegate, in either the `-applicationDidFinishLaunching:withOptions:` method, or `-awakeFromNib`, use any combination of the following setup calls from the `MagicalRecord` metaclass:

	+ (void)setStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
	+ (void)setStackShouldUseInMemoryStore: (BOOL) inMemory;
	+ (void)setStackStoreName: (NSString *) name;
	+ (void)setStackStoreURL: (NSURL *) name;
	+ (void)setStackModelName: (NSString *) name;
	+ (void)setStackModelURL: (NSURL *) name;

Each call configures a piece of your Core Data stack, and will automatically get used whenever your app tries to use a Magical Record method.

### Default Managed Object Context 

When using Core Data, you will deal with two types of objects the most: `NSManagedObject` and `NSManagedObjectContext`. Magical Record gives you a place for a default `NSManagedObjectContext` for use within your app. This is great for single threaded apps. You can easily get to this default context by calling:

	NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];

This context will be used if a find or request method (described below) is not specifying a specific context using the **inContext:** method overload.

	NSManagedObjectContext *myNewContext = [NSManagedObjectContext context];

This will use the same object model and persistent store, but create an entirely new context for use with threads other than the main thread. 

	[NSManagedObjectContext contextForCurrentThread];

### Fetching

#### Basic Finding

Most methods in Magical Record return an `NSArray` of results. So, if you have an Entity called *Person*, related to a *Department* (as seen in various Apple Core Data documentation), to get all the *Person* entities from your persistent store:

	NSArray *people = [Person findAll];

Or, to have the results sorted by a property:

	NSArray *peopleSorted = [Person findAllSortedByProperty:@"LastName" ascending:YES];

Or, to have the results sorted by multiple properties:

	NSArray *peopleSorted = [Person findAllSortedByProperty:@"LastName,FirstName" ascending:YES];

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

#### Aggregate Operations

    NSPredicate *prediate = [NSPredicate predicateWithFormat:@"diaryEntry.date == %@", today];
    int totalFat = [[CTFoodDiaryEntry aggregateOperation:@"sum:" onAttribute:@"fatColories" withPredicate:predicate] intValue];
    int fattest  = [[CTFoodDiaryEntry aggregateOperation:@"max:" onAttribute:@"fatColories" withPredicate:predicate] intValue];

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

There is also a *truncate* (delete all entities) operation  provided for you by Magical Record:

	[Person truncateAll];

or, with a specific context:

	NSManagedObjectContext *otherContext = ...;
	[Person truncateAllInContext:otherContext];

## Performing Core Data operations on Threads

Available starting on iOS 4.0 and Mac OS X 10.6.

Paraphrasing the [Apple documentation on Core Data and Threading]("http://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/CoreData/Articles/cdConcurrency.html#//apple_ref/doc/uid/TP40003385-SW1"), you should always:

* Use a new, dedicated `NSManagedObjectContext` instance for every thread.
* Use an instance of your `NSManagedObject` that is local for the new `NSManagedObjectContext`.
* Notify other contexts that the background is updated or saved.

Magical Record library is trying to make these steps more reusable with the following methods:

	+ (void) saveDataWithBlock: (MRContextBlock)block;
	+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block;

An `MRContextBlock` is a non-returning block that has an automatically-generated `NSManagedObjectContext` passed as an argument.
	
All the boilerplate operations that need to be done when saving are done in these methods. To use this method from the *main thread*:

	Person *person = ...;
	[MagicalRecord saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext){
		Person *localPerson = [person inContext:localContext];

		localPerson.firstName = @"Chuck";
		localPerson.lastName = @"Smith";
	}];
	
In this method, the block provides you with the proper context in which to perform your operations, you don’t need to worry about setting up the context so that it tells the default context that it’s done, and should update because changes were performed on another thread.

To perform an action after this save block is completed, you can fill in a completion block:

	Person *person = ...;
	[MagicalRecord saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext){
		Person *localPerson = [person inContext:localContext];

		localPerson.firstName = @"Chuck";
		localPerson.lastName = @"Smith";
	} completion:^{
		self.everyoneInTheDepartment = [Person findAll];
	}];
	
This completion block is called on the main thread (queue), so this is also safe for triggering UI updates.

Magical Record has a dedicated GCD queue on which it operates. This means that throughout your app, you only really have 2 queues (somewhat like threads) performing Core Data actions at any one time: one on the main queue, and another on this dedicated GCD queue.

# Data Import


Magical Record can now import data from `NSDictionary` into your Core Data store. This feature is currently under development, and is undergoing updates. Feel free to try it out, add tests and send in your feedback.
	
# Extra Bits

This Code is released under the MIT License by [Magical Panda Software, LLC.](http://www.magicalpanda.com)
