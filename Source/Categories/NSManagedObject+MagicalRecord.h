//
//  NSManagedObject+MagicalRecord.h
//  MagicalRecord
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObject (MagicalRecord) <NSCoding>

/** @name Instance methods */

- (id) inContext:(NSManagedObjectContext *)otherContext;
- (id) inThreadContext;

- (BOOL) deleteEntity;
- (BOOL) deleteInContext:(NSManagedObjectContext *)context;

- (id)objectWithMinValueFor:(NSString *)property;
- (id)objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context;

@property (nonatomic, readonly) NSURL *uri;

/** @name Default batch size */

+ (NSUInteger) defaultBatchSize;
+ (void) setDefaultBatchSize:(NSUInteger)newBatchSize;

/** @name Fetch request helpers */

+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request;
+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;
+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request;
+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context;

+ (NSFetchRequest *)createFetchRequest;
+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context;

+ (NSArray *) ascendingSortDescriptors:(NSArray *)attributesToSortBy;
+ (NSArray *) descendingSortDescriptors:(NSArray *)attributesToSortBy;

/** @name Entity description */

+ (NSEntityDescription *)entityDescription;
+ (NSEntityDescription *)entityDescriptionInContext:(NSManagedObjectContext *)context;
+ (NSArray *)propertiesNamed:(NSArray *)properties;

/** @name Entity creation */

+ (id) createEntity;
+ (id) createInContext:(NSManagedObjectContext *)context;

/** @name Entity deletion */

+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate;
+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

+ (BOOL) truncateAll;
+ (BOOL) truncateAllInContext:(NSManagedObjectContext *)context;

/** @name Counting entities */

+ (NSNumber *) numberOfEntities;
+ (NSNumber *) numberOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSUInteger) countOfEntities;
+ (NSUInteger) countOfEntitiesWithContext:(NSManagedObjectContext *)context;
+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter inContext:(NSManagedObjectContext *)context;

+ (BOOL) hasAtLeastOneEntity;
+ (BOOL) hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context;

/** @name Fetch requests for groups of items */

+ (NSFetchRequest *) requestAll;
+ (NSFetchRequest *) requestAllInContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value;
+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

/** @name Fetch requests for single items */

+ (NSFetchRequest *) requestFirst;
+ (NSFetchRequest *) requestFirstInContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue;
+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue DEPRECATED_ATTRIBUTE;
+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;

/** @name Fetching groups */

+ (NSArray *)findAll;
+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm;
+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value;
+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context;
+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue DEPRECATED_ATTRIBUTE;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending DEPRECATED_ATTRIBUTE;
+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;

/** @name Fetching single objects */

+ (id)findFirst;
+ (id)findFirstInContext:(NSManagedObjectContext *)context;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;
+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue;
+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue inContext:(NSManagedObjectContext *)context;
+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;
+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm;
+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context;

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context;

+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(id)attributes, ...;
+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ...;

+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm attributesToRetrieve:(NSArray *)attributes;
+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm attributesToRetrieve:(NSArray *)attributes inContext:(NSManagedObjectContext *)context;

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)attributes, ... DEPRECATED_ATTRIBUTE;
+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)attributes, ... DEPRECATED_ATTRIBUTE;
+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue DEPRECATED_ATTRIBUTE;
+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;
+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending DEPRECATED_ATTRIBUTE;
+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context DEPRECATED_ATTRIBUTE;

/** @name Fetched results controllers */

#if (TARGET_OS_IPHONE)

+ (void) performFetch:(NSFetchedResultsController *)controller;

+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath;
+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath inContext:(NSManagedObjectContext *)context;

+ (NSFetchedResultsController *) fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group;
+ (NSFetchedResultsController *) fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group inContext:(NSManagedObjectContext *)context;

+ (NSFetchedResultsController *) fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending;
+ (NSFetchedResultsController *) fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

#endif

@end