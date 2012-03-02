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

+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request;
+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context;

+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group;
+ (NSFetchedResultsController *) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group inContext: (NSManagedObjectContext *) context;

+ (NSFetchedResultsController *) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath;
+ (NSFetchedResultsController *) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy: (NSString *) keyPath inContext: (NSManagedObjectContext *) context;

@end

#endif