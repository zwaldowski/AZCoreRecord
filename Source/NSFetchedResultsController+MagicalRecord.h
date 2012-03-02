//
//  NSFetchedResultsController+MagicalRecord.h
//  Magical Record
//
//  Created by Zachary Waldowski on 2/27/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecord.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

@interface NSFetchedResultsController (MagicalRecord)

- (BOOL)performFetch;

+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request;
+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context;

+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group;
+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group inContext: (NSManagedObjectContext *) context;

+ (id) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath;
+ (id) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath inContext: (NSManagedObjectContext *) context;

@end

#endif