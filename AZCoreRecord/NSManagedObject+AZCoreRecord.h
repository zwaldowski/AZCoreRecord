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

#pragma mark - Singleton-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestFirst;
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value;
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark - Array-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestAll;
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) predicate;
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value;
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark - Singleton-fetching Fetch Request Convenience Methods

+ (instancetype) findFirst;
+ (instancetype) findFirstInContext: (NSManagedObjectContext *) context;

+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm;
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes;
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue;
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context;
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes;
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
 @see findAllWhere:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value;

/** Requests and returns instances of all model objects in a managed object context where an attribute is equal to a given value for the recieving entity.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param context The managed object context in which to search for objects.
 @return An array of results matching the given value.
 @see findAllWhere:sortedBy:ascending:inContext:
 */
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;

/** Requests and returns instances of all model objects where an attribute is equal to a given value for the recieving entity, sorted ascending or descending by a key path.

 This class method is a member of the `findAllWhere` group of methods.

 @param property A key path for an attribute on the entity to be matched with.
 @param value Any object that can be parsed as part of a predicate to be matched with.
 @param sortTerm A key path for an attribute on the entity to sort by.
 @param ascending If YES, the return values will be sorted in low-to-high order according to sortTerm, otherwise high-to-low.
 @return An array of results matching the given value sorted by the given specifiers.
 @see findAllWhere:sortedBy:ascending:inContext:
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
 @see findAllWhere:sortedBy:ascending:
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
