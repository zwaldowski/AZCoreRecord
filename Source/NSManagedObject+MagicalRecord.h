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

#pragma mark - Specific Entity

+ (id)existingObjectWithURI:(id)URI;
+ (id)existingObjectWithURI:(id)URI inContext:(NSManagedObjectContext *)context;

+ (id)existingObjectWithID:(NSManagedObjectID *)objectID;
+ (id)existingObjectWithID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context;

#pragma mark - Entity Count

+ (NSUInteger) countOfEntities;
+ (NSUInteger) countOfEntitiesInContext: (NSManagedObjectContext *) context;
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter;
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter inContext: (NSManagedObjectContext *) context;

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

#pragma mark - Array-fetching Fetch Request Convenience Methods

+ (NSArray *) findAll;
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm;
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value;
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context;
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;

+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending;
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context;
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm;
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context;

@end
