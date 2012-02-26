//
//  NSManagedObject+MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MagicalRecord.h"

@interface NSManagedObject (MagicalRecord) <NSCoding>

#pragma mark - Instance Methods

- (id) inContext: (NSManagedObjectContext *) otherContext;
- (id) inThreadContext;

- (void) delete;
- (void) deleteInContext: (NSManagedObjectContext *) context;

- (void) reload;

- (id) objectWithMinValueFor: (NSString *) property;
- (id) objectWithMinValueFor: (NSString *) property inContext: (NSManagedObjectContext *) context;

- (id) objectWithMaxValueFor: (NSString *) property;
- (id) objectWithMaxValueFor: (NSString *) property inContext: (NSManagedObjectContext *) context;

@property (nonatomic, readonly) NSURL *URI;

#pragma mark - Default Batch Size

+ (NSUInteger) defaultBatchSize;
+ (void) setDefaultBatchSize: (NSUInteger) newBatchSize;

#pragma mark - Fetch Request Helpers

+ (NSFetchRequest *) createFetchRequest;
+ (NSFetchRequest *) createFetchRequestInContext: (NSManagedObjectContext *) context;

+ (NSArray *) executeFetchRequest: (NSFetchRequest *) request;
+ (NSArray *) executeFetchRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context;

+ (id) executeFetchRequestAndReturnFirstObject: (NSFetchRequest *) request;
+ (id) executeFetchRequestAndReturnFirstObject: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context;

+ (NSArray *) ascendingSortDescriptors: (NSArray *) attributesToSortBy;
+ (NSArray *) descendingSortDescriptors: (NSArray *) attributesToSortBy;
+ (NSArray *) sortAscending: (BOOL) ascending attributes: (NSArray *) attributesToSortBy;

#pragma mark - Entity Description

+ (NSArray *) propertiesNamed: (NSArray *) properties;

+ (NSEntityDescription *) entityDescription;
+ (NSEntityDescription *) entityDescriptionInContext: (NSManagedObjectContext *) context;

#pragma mark - Entity Creation

+ (id) create;
+ (id) createInContext: (NSManagedObjectContext *) context;

#pragma mark - Entity Deletion

+ (BOOL) deleteAllMatchingPredicate: (NSPredicate *) predicate;
+ (BOOL) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

+ (BOOL) truncateAll;
+ (BOOL) truncateAllInContext: (NSManagedObjectContext *) context;

#pragma mark - Entity Count

+ (BOOL) hasAtLeastOneEntity;
+ (BOOL) hasAtLeastOneEntityInContext: (NSManagedObjectContext *) context;

+ (NSUInteger) countOfEntities;
+ (NSUInteger) countOfEntitiesWithContext: (NSManagedObjectContext *) context;
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter;
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter inContext: (NSManagedObjectContext *) context;

+ (NSNumber *) numberOfEntities;
+ (NSNumber *) numberOfEntitiesWithContext: (NSManagedObjectContext *) context;
+ (NSNumber *) numberOfEntitiesWithPredicate: (NSPredicate *) searchTerm;
+ (NSNumber *) numberOfEntitiesWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (NSNumber *) aggregateOperation: (NSString *) function onAttribute: (NSString *) attributeName withPredicate: (NSPredicate *) predicate;
+ (NSNumber *) aggregateOperation: (NSString *) function onAttribute: (NSString *) attributeName withPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context;

#pragma mark - Singleton-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestFirst;
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue;
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark - Array-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestAll;
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value;
+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm;
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark - Singleton-fetching Fetch Request Convenience Methods

+ (id) findFirst;
+ (id) findFirstInContext: (NSManagedObjectContext *) context;

+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm;
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm andRetrieveAttributes: (NSArray *) attributes;
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm andRetrieveAttributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue;
+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue inContext: (NSManagedObjectContext *) context;
+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm;
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm andRetrieveAttributes: (id) attributes, ... NS_REQUIRES_NIL_TERMINATION;
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context andRetrieveAttributes: (id) attributes, ... NS_REQUIRES_NIL_TERMINATION;

+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm attributesToRetrieve: (NSArray *) attributes;
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm attributesToRetrieve: (NSArray *) attributes inContext: (NSManagedObjectContext *) context;

#pragma mark - Array-fetching Fetch Request Convenience Methods

+ (NSArray *) findAll;
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm;
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value;
+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value inContext: (NSManagedObjectContext *) context;
+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm;
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

#pragma mark - Fetched Results Controller Convenience Methods

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

+ (void) performFetch: (NSFetchedResultsController *) controller;

+ (NSFetchedResultsController *) fetchAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm groupBy: (NSString *) groupingKeyPath;
+ (NSFetchedResultsController *) fetchAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm groupBy: (NSString *) groupingKeyPath inContext: (NSManagedObjectContext *) context;

+ (NSFetchedResultsController *) fetchRequest: (NSFetchRequest *) request groupedBy: (NSString *) group;
+ (NSFetchedResultsController *) fetchRequest: (NSFetchRequest *) request groupedBy: (NSString *) group inContext: (NSManagedObjectContext *) context;

+ (NSFetchedResultsController *) fetchRequestAllGroupedBy: (NSString *) group withPredicate: (NSPredicate *) searchTerm sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSFetchedResultsController *) fetchRequestAllGroupedBy: (NSString *) group withPredicate: (NSPredicate *) searchTerm sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

#endif

@end
