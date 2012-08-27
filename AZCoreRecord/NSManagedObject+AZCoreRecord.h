//
//  NSManagedObject+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "AZCoreRecordManager.h"

@interface NSManagedObject (AZCoreRecord)

#pragma mark - Instance Methods

- (instancetype) inContext: (NSManagedObjectContext *) otherContext;
- (instancetype) inThreadContext;

- (void) reload;

@property (nonatomic, readonly) NSURL *URI;

#pragma mark - Default Batch Size

+ (NSUInteger) defaultBatchSize;
+ (void) setDefaultBatchSize: (NSUInteger) newBatchSize;

#pragma mark - Entity Description

+ (NSArray *) propertiesNamed: (NSArray *) properties;

+ (NSEntityDescription *) entityDescription;
+ (NSEntityDescription *) entityDescriptionInContext: (NSManagedObjectContext *) context;

#pragma mark - Entity Creation

+ (instancetype) create;
+ (instancetype) createInContext: (NSManagedObjectContext *) context;

#pragma mark - Entity Deletion

- (void) delete;
- (void) deleteInContext: (NSManagedObjectContext *) context;

+ (void) deleteAll;
+ (void) deleteAllInContext: (NSManagedObjectContext *) context;

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate;
+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

#pragma mark - Entity Count

+ (NSUInteger) count;
+ (NSUInteger) countInContext: (NSManagedObjectContext *) context;
+ (NSUInteger) countWithPredicate: (NSPredicate *) searchFilter;
+ (NSUInteger) countWithPredicate: (NSPredicate *) searchFilter inContext: (NSManagedObjectContext *) context;

#pragma mark - Deduplication

+ (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler includeSubentities: (BOOL) includeSubentities;

#pragma mark -
/** @name Creating Fetch Requests For Single Objects */

/** Requests the first model object for the receiving entity.

 This class method is a member of the `requestFirst` group of methods.

 @return A fetch request for the first object.
 @see requestFirstWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestFirst;

/** Requests the first model object in a managed object context for the receiving entity.

 This class method is a member of the `requestFirst` group of methods.

 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object.
 @see requestFirstWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context;

/** Requests the first model object matching a predicate for the receiving entity.

 This class method is a member of the `requestFirst` group of methods.

 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object matching the predicate.
 @see requestFirstWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm;

/** Requests the first model object matching a predicate in a managed object context for the receiving entity.

 This class method is the base of the `requestFirst` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object matching the predicate.
 @see requestFirst
 @see requestFirstInContext:
 @see requestFirstWithPredicate:
 */
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests the first model object where an attribute is equal to a given value for the receiving entity.

 This class method is a member of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @return A fetch request for the first object matching the predicate.

 @see requestFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value;

/** Requests the first model object in a managed object context where an attribute is equal to a given value for the receiving entity.

 This class method is a member of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object matching the predicate.

 @see requestFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests the first model object, when sorted ascending or descending by a key path, where an attribute is equal to a given value for the receiving entity.

 This class method is a member of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return A fetch request for the first object matching the predicate when sorted.

 @see requestFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests the first model object, when sorted ascending or descending by a key path, in a managed object context where an attribute is equal to a given value for the receiving entity.

 This class method is the base of the `requestFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object matching the predicate when sorted.

 @see requestFirstWhere:equals:
 @see requestFirstWhere:equals:inContext:
 @see requestFirstWhere:equals:sortedBy:ascending:
 */
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests the first model object, when sorted ascending or descending by a key path, for the receiving entity.

 This class method is a member of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return A fetch request for the first object when sorted.
 @see requestFirstSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests the first model object, when sorted ascending or descending by a key path, in a managed object context for the receiving entity.

 This class method is a member of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object when sorted.
 @see requestFirstSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests the first model object, when sorted ascending or descending by a key path, matching a given predicate for the receiving entity.

 This class method is the base of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return A fetch request for the first object matching the predicate when sorted.
 @see requestFirstSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests the first model object, when sorted ascending or descending by a key path, in a managed object context matching a given predicate for the receiving entity.

 This class method is the base of the `requestFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request for the first object matching the predicate when sorted.
 @see requestFirstSortedBy:ascending:
 @see requestFirstSortedBy:ascending:inContext:
 @see requestFirstSortedBy:ascending:predicate:
 */
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Creating Fetch Requests */

/** Requests instances of all model objects.

 This class method is a member of the `requestAll` group of methods.

 @return A fetch request.
 @see requestAll
 @see requestAllInContext:
 @see requestAllWithPredicate:
 */
+ (NSFetchRequest *) requestAll;

/** Requests instances of all model objects in a managed object context.

 This class method is a member of the `requestAll` group of methods.

 @param context The managed object context in which to search for objects.
 @return A fetch request.
 @see requestAll
 @see requestAllInContext:
 @see requestAllWithPredicate:
 */
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects in a managed object context matching a given predicate for the recieving entity.

 This class method is a member of the `requestAll` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return A fetch request matching the given predicate.
 @see requestAllWithPredicate:inContext:
 */
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm;

/** Requests instances of all model objects in a managed object context matching a given predicate for the recieving entity.

 This class method is the base of the `requestAll` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request matching the given predicate.
 @see requestAll
 @see requestAllInContext:
 @see requestAllWithPredicate:
 */
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @return A fetch request matching the given value.
 @see requestAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value;

/** Requests instances of all model objects in a managed object context where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param context The managed object context in which to search for objects.
 @return A fetch request matching the given value.
 @see requestAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects where an attribute is equal to a given value for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return A fetch request matching the given value sorted by the given specifiers.
 @see requestAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests instances of all model objects in a managed object context where an attribute is equal to a given value for the recieving entity, sorted ascending or descending by a key path.

 This class method is the base of the `requestAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request matching the given value sorted by the given specifiers.
 @see requestAllWhere:equals:
 @see requestAllWhere:equals:inContext:
 @see requestAllWhere:equals:sortedBy:ascending:
 */
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return A fetch request sorted by the given specifiers.
 @see requestAllSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests instances of all model objects in a managed object context for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return A fetch request sorted by the given specifiers.
 @see requestAllSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests instances of all model objects matching a given predicate for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return A fetch request with the given predicate sorted by the given specifiers.
 @see requestAllSortedBy:ascending:predicate:inContext:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests instances of all model objects in a managed object context matching a given predicate for the recieving entity, sorted ascending or descending by a key path.

 This class method is the base of the `requestAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return A fetch request with the given predicate sorted by the given specifiers.
 @see requestAllSortedBy:ascending:
 @see requestAllSortedBy:ascending:inContext:
 @see requestAllSortedBy:ascending:predicate:
 */
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Fetching Single Objects */

/** Requests and returns the first model object for the recieving entity.

 This class method is a member of the `findFirst` group of methods.

 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirst;

/** Requests and returns the first model object in a managed object context for the recieving entity.

 This class method is a member of the `findFirst` group of methods.

 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstInContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object matching a predicate for the recieving entity.

 This class method is a member of the `findFirst` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm;

/** Requests and returns the first model object matching a predicate in a managed object context for the recieving entity.

 This class method is a member of the `findFirst` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object matching a predicate for the recieving entity with specific attributes.

 This class method is a member of the `findFirst` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param attributes An array of property descriptions representing attributes to fetch.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstWithPredicate:attributes:inContext:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes;

/** Requests and returns the first model object matching a predicate in a managed object context for the recieving entity with specific attributes.

 This class method is the base of the `findFirst` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param attributes An array of property descriptions representing attributes to fetch.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirst
 @see findFirstInContext:
 @see findFirstWithPredicate:
 @see findFirstWithPredicate:inContext:
 @see findFirstWithPredicate:attributes:
 */
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @return The first result for the fetch, or `nil` if no results.

 @see findFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue;

/** Requests and returns the first model object in a managed object context where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.

 @see findFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return The first result for the fetch, or `nil` if no results.

 @see findFirstWhere:equals:sortedBy:ascending:inContext:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, in a managed object context where an attribute is equal to a given value for the recieving entity.

 This class method is the base of the `findFirstWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 
 @see findFirstWhere:equals:
 @see findFirstWhere:equals:inContext:
 @see findFirstWhere:equals:sortedBy:ascending:
 */
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, for the recieving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, in a managed object context for the recieving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, matching a given predicate for the recieving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, in a managed object context matching a given predicate for the recieving entity.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, matching a given predicate for the recieving entity with specific attributes.

 This class method is a member of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param attributes An array of property descriptions representing attributes to fetch.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:predicate:attributes:inContext:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes;

/** Requests and returns the first model object, when sorted ascending or descending by a key path, in a managed object context matching a given predicate for the recieving entity with specific attributes.
 
 This class method is the base of the `findFirstSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param attributes An array of property descriptions representing attributes to fetch. 
 @param context The managed object context in which to search for objects.
 @return The first result for the fetch, or `nil` if no results.
 @see findFirstSortedBy:ascending:
 @see findFirstSortedBy:ascending:inContext:
 @see findFirstSortedBy:ascending:predicate:
 @see findFirstSortedBy:ascending:predicate:inContext:
 @see findFirstSortedBy:ascending:predicate:attributes:
 */
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

#pragma mark -
/** @name Fetching Object Arrays */

/** Requests and returns instances of all model objects.

 This class method is a member of the `findAll` group of methods.

 @return An array of results.
 @see findAllWithPredicate:inContext:
 */
+ (NSArray *) findAll;

/** Requests and returns instances of all model objects in a managed object context..

 This class method is a member of the `findAll` group of methods.

 @param context The managed object context in which to search for objects.
 @return An array of results.
 @see findAllWithPredicate:inContext:
 */
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects matching a given predicate for the recieving entity.

 This class method is a member of the `findAll` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return An array of results matching the given predicate.
 @see findAllWithPredicate:inContext:
 */
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm;

/** Requests and returns instances of all model objects in a managed object context matching a given predicate for the recieving entity.

 This class method is the base of the `findAll` group of methods.

 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return An array of results matching the given predicate.
 @see findAll
 @see findAllInContext:
 @see findAllWithPredicate:
 */
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @return An array of results matching the given value.
 @see findAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value;

/** Requests and returns instances of all model objects in a managed object context where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param context The managed object context in which to search for objects.
 @return An array of results matching the given value.
 @see findAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects where an attribute is equal to a given value for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return An array of results matching the given value sorted by the given specifiers.
 @see findAllWhere:equals:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns instances of all model objects in a managed object context where an attribute is equal to a given value for the recieving entity, sorted ascending or descending by a key path.

 This class method is the base of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return An array of results matching the given value sorted by the given specifiers.
 @see findAllWhere:equals:
 @see findAllWhere:equals:inContext:
 @see findAllWhere:equals:sortedBy:ascending:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return An array of results sorted by the given specifiers.
 @see findAllSortedBy:ascending:predicate:inContext:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;

/** Requests and returns instances of all model objects in a managed object context for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param context The managed object context in which to search for objects.
 @return An array of results sorted by the given specifiers.
 @see findAllSortedBy:ascending:predicate:inContext:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects matching a given predicate for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllSortedBy` group of methods.

 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @return An array of results sorted by the given specifiers.
 @see findAllSortedBy:ascending:predicate:inContext:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;

/** Requests and returns instances of all model objects in a managed object context matching a given predicate for the recieving entity, sorted ascending or descending by a key path.
 
 This class method is the base of the `findAllSortedBy` group of methods.
 
 @param sortTerm A key path for an attribute on the entity to sort by. 
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @param searchTerm An instance of a predicate representing conditions for which to include an object.
 @param context The managed object context in which to search for objects.
 @return An array of results matching the given predicate sorted by the given specifiers.
 @see findAllSortedBy:ascending:
 @see findAllSortedBy:ascending:inContext:
 @see findAllSortedBy:ascending:predicate:
 */
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

@end
