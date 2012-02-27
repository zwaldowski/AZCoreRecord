//
//  NSFetchedResultsController+MagicalRecord.m
//  Magical Record
//
//  Created by Zachary Waldowski on 2/27/12.
//  Copyright (c) 2012 Magical Panda Software LLC. All rights reserved.
//

#import "NSFetchedResultsController+MagicalRecord.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED

@implementation NSFetchedResultsController (MagicalRecord)

- (void)performFetch {
	NSError *error = nil;
    [self performFetch: &error];
    [MagicalRecord handleError: error];
}

+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request {
	return [self fetchedResultsControllerForRequest: request inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context {
	return [self fetchedResultsControllerForRequest: request groupedBy: nil inContext: context];
}

+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group {
	return [self fetchedResultsControllerForRequest: request groupedBy: group inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (id) fetchedResultsControllerForRequest: (NSFetchRequest *) request groupedBy: (NSString *) group inContext: (NSManagedObjectContext *) context {
	NSString *cacheName = nil;
#if !TARGET_IPHONE_SIMULATOR
	NSString *entityName = [[self entityDescriptionInContext: context] name];
	NSString *cacheName = [NSString stringWithFormat: @"MRCache-%@", entityName];
#endif
	
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest: request managedObjectContext: context sectionNameKeyPath: group cacheName: cacheName];
	[controller performFetch];
	return controller;
}

+ (id) fetchedResultsControllerForEntity: (Class) entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy:(NSString *) keyPath {
	return [self fetchedResultsControllerForEntity: entityClass sortedBy: sortTerm ascending: ascending predicate: searchTerm groupedBy: keyPath inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (id) fetchedResultsControllerForEntity: (Class)entityClass sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm groupedBy:(NSString *) keyPath inContext: (NSManagedObjectContext *) context{
	NSParameterAssert([entityClass isSubclassOfClass:[NSManagedObject class]]);
	NSFetchRequest *request = [entityClass requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: context];
	return [self fetchedResultsControllerForRequest: request groupedBy: keyPath inContext: context];
}

@end

#endif