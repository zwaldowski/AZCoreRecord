//
//  NSManagedObject+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObject+AZCoreRecord.h"
#import "AZCoreRecordManager+Private.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSPersistentStore+AZCoreRecord.h"

static NSUInteger defaultBatchSize = 20;
static NSString *const kURICodingKey = @"AZCoreRecordManagedObjectURI";

@interface NSManagedObject (AZCoreRecord_MOGenerator)

+ (NSEntityDescription *) entityInManagedObjectContext: (NSManagedObjectContext *) context;
+ (id) insertInManagedObjectContext: (NSManagedObjectContext *) context;

@end

@implementation NSManagedObject (AZCoreRecord)

#pragma mark - NSCoding

- (instancetype) initWithCoder: (NSCoder *) decoder
{
	NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	NSURL *URI = [decoder decodeObjectForKey: kURICodingKey];
	NSManagedObjectID *objectID = [psc managedObjectIDForURIRepresentation: URI];
	
	NSError *error = nil;
	id ret = [[NSManagedObjectContext defaultContext] existingObjectWithID:objectID error:&error];
	[AZCoreRecord handleError:error];
	
	return ret;
}
- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeObject: self.URI forKey: kURICodingKey];
}

#pragma mark - Instance Methods

- (instancetype) inContext: (NSManagedObjectContext *) context
{
	NSParameterAssert(context);
	
	NSManagedObjectContext *myContext = self.managedObjectContext;
	if (!myContext)
		myContext = [NSManagedObjectContext defaultContext];
	
	if ([self.objectID isTemporaryID])
	{
		NSError *error = nil;
		[myContext obtainPermanentIDsForObjects: [NSArray arrayWithObject: self] error: &error];
		[AZCoreRecord handleError: error];
	}
	
	if ([context isEqual:self.managedObjectContext])
		return self;

	NSError *error = nil;
	NSManagedObject *inContext = [context existingObjectWithID: self.objectID error: &error];
	[AZCoreRecord handleError: error];
	
	return inContext;
}
- (instancetype) inThreadContext 
{
	NSManagedObject *weakSelf = self;
	return [weakSelf inContext: [NSManagedObjectContext contextForCurrentThread]];
}

- (void) reload
{
	[self.managedObjectContext refreshObject:self mergeChanges:NO];
}

- (NSURL *) URI
{
	NSManagedObjectID *objectID = self.objectID;
	
	if (objectID.isTemporaryID)
	{
		NSError *error;
		if ([self.managedObjectContext obtainPermanentIDsForObjects: [NSArray arrayWithObject: self] error: &error])
			objectID = self.objectID;
		
		[AZCoreRecord handleError: error];
	}
	
	return objectID.URIRepresentation;
}

#pragma mark - Default batch size

+ (NSUInteger) defaultBatchSize
{
	return defaultBatchSize;
}
+ (void) setDefaultBatchSize: (NSUInteger) newBatchSize
{
	defaultBatchSize = newBatchSize;
}

#pragma mark - Entity Description

+ (NSArray *) propertiesNamed: (NSArray *) properties
{
	if (!properties.count)
		return nil;
	
	NSDictionary *propertyDescriptions = self.entityDescription.propertiesByName;
	return [propertyDescriptions objectsForKeys: properties notFoundMarker: [NSNull null]];
}

+ (NSEntityDescription *) entityDescription
{
	return [self entityDescriptionInContext: nil];
}
+ (NSEntityDescription *) entityDescriptionInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	if ([self respondsToSelector: @selector(entityInManagedObjectContext:)]) 
		return [self performSelector: @selector(entityInManagedObjectContext:) withObject: context];

	NSString *entityName = NSStringFromClass([self class]);
	return [NSEntityDescription entityForName: entityName inManagedObjectContext: context];
}

#pragma mark - Entity Creation

+ (instancetype) create
{	
	return [self createInContext: nil];
}
+ (instancetype) createInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	if ([self respondsToSelector: @selector(insertInManagedObjectContext:)]) 
		return [self insertInManagedObjectContext: context];

	NSString *entityName = NSStringFromClass([self class]);
	return [NSEntityDescription insertNewObjectForEntityForName: entityName inManagedObjectContext: context];
}

#pragma mark - Entity deletion

- (void) delete
{
	[self.managedObjectContext deleteObject: self];
}
- (void) deleteInContext: (NSManagedObjectContext *) context
{
	[context deleteObject: [self inContext: context]];
}

+ (void) deleteAll
{
	[self deleteAllInContext: nil];
}
+ (void) deleteAllInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSArray *objects = [self findAllInContext: context];
	[objects makeObjectsPerformSelector:@selector(deleteInContext:) withObject:context];
}

+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate
{
	[self deleteAllMatchingPredicate: predicate inContext: [NSManagedObjectContext defaultContext]];
}
+ (void) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWithPredicate: predicate inContext: context];
	request.includesPropertyValues = NO;
	
	NSArray *objects = [context executeFetchRequest: request error: NULL];
	[objects makeObjectsPerformSelector:@selector(deleteInContext:) withObject:context];
}

#pragma mark - Specific Entity

+ (id)existingObjectWithURI:(id)URI {
	return [self existingObjectWithURI: URI inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (id)existingObjectWithURI:(id)URI inContext:(NSManagedObjectContext *)context {
	NSParameterAssert(URI);
	
	if ([URI isKindOfClass:[NSString class]])
		URI = [NSURL URLWithString:URI];
	
	if ([URI isKindOfClass:[NSURL class]])
		URI = [context.persistentStoreCoordinator managedObjectIDForURIRepresentation:URI];
	
	if (!URI || ![URI isKindOfClass:[NSManagedObjectID class]])
		return nil;
	
	return [self existingObjectWithID: URI inContext: context];
}

+ (id)existingObjectWithID:(NSManagedObjectID *)objectID {
	return [self existingObjectWithID: objectID inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (id)existingObjectWithID:(NSManagedObjectID *)objectID inContext:(NSManagedObjectContext *)context {
	NSError *error = nil;
	id ret = [context existingObjectWithID: objectID error: &error];
	[AZCoreRecord handleError: error];
	return ret;
}

#pragma mark - Entity Count

+ (NSUInteger) countOfEntities
{
	return [self countOfEntitiesWithPredicate: nil inContext: nil];
}
+ (NSUInteger) countOfEntitiesInContext: (NSManagedObjectContext *) context
{
	return [self countOfEntitiesWithPredicate: nil inContext: context];
}

+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter
{
	return [self countOfEntitiesWithPredicate: searchFilter inContext: nil];
}
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSError *error = nil;
	NSFetchRequest *request = [self requestAllWithPredicate: searchFilter inContext: context];
	NSUInteger count = [context countForFetchRequest: request error: &error];
	[AZCoreRecord handleError: error];
	return count;
}

#pragma mark - Singleton-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestFirst
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: nil];
}
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self requestFirstSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue
{
	return [self requestFirstWhere: property equals: searchValue sortedBy: nil ascending: NO];
}
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	return [self requestFirstWhere: property equals: searchValue sortedBy: nil ascending: NO inContext: context];
}

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestFirstWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending predicate: nil];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending predicate: nil inContext: context];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: nil];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: context];
	request.fetchLimit = 1;
	return request;
}

#pragma mark - Array-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestAll
{
	return [self requestAllSortedBy: nil ascending: NO predicate: nil];
}
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) predicate
{
	return [self requestAllSortedBy: nil ascending: NO predicate: predicate];
}
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: nil ascending: NO predicate: predicate inContext: context];
}

+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value
{
	return [self requestAllWhere: property equals: value sortedBy: nil ascending: NO];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context
{
	return [self requestAllWhere: property equals: value sortedBy: nil ascending: NO inContext: context];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestAllWhere: property equals: value sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, value];
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: predicate inContext: context];
}

+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: nil];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: nil inContext: context];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: nil];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	NSFetchRequest *request = [NSFetchRequest new];
	request.entity = [self entityDescriptionInContext: context];
	request.predicate = searchTerm;
	request.fetchBatchSize = self.defaultBatchSize;

	if (sortTerm.length) {
		NSSortDescriptor *sortBy = [NSSortDescriptor sortDescriptorWithKey: sortTerm ascending: ascending];
		request.sortDescriptors = [NSArray arrayWithObject: sortBy];
	}
	
	return request;
}

#pragma mark - Singleton-fetching Fetch Request Convenience Methods

+ (instancetype) findFirst
{
	return [self findFirstSortedBy: nil ascending: NO predicate: nil];
}
+ (instancetype) findFirstInContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm attributes: attributes];
}
+ (instancetype) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm attributes: attributes inContext: context];
}

+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue
{
	return [self findFirstWhere: property equals: searchValue sortedBy: nil ascending: NO];
}
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	return [self findFirstWhere: property equals: searchValue sortedBy: nil ascending: NO inContext: context];
}
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (instancetype) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, searchValue];
	return [self findFirstSortedBy: property ascending: NO predicate: predicate inContext: context];
}

+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: nil attributes: nil];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: nil attributes: nil inContext: context];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm attributes: nil];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm attributes: nil inContext: context];
}

+ (instancetype) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes
{
	return [self findFirstSortedBy: sortBy ascending: ascending predicate: searchTerm attributes: attributes inContext: nil];
}
+ (instancetype) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestFirstSortedBy: sortBy ascending: ascending predicate: searchTerm inContext: context];
	request.propertiesToFetch = attributes;
	NSArray *results = [context executeFetchRequest: request error: NULL];
	if (!results.count)
		return nil;
	return [results lastObject];
}

#pragma mark - Array-fetching Fetch Request Convenience Methods

+ (NSArray *) findAll
{
	return [self findAllSortedBy: nil ascending: NO predicate: nil];
}
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context
{
	return [self findAllSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm
{
	return [self findAllSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findAllSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value
{
	return [self findAllWhere: property equals: value sortedBy: nil ascending: NO];
}
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value inContext: (NSManagedObjectContext *) context
{
	return [self findAllWhere: property equals: value sortedBy: nil ascending: NO inContext: context];
}
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findAllWhere: property equals: value sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (NSArray *) findAllWhere: (NSString *) property equals: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, value];
	return [self findAllSortedBy: nil ascending: NO predicate: predicate inContext: context];
}

+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findAllSortedBy: sortTerm ascending: ascending predicate: nil];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self findAllSortedBy: sortTerm ascending: ascending predicate: nil inContext: context];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self findAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: nil];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllSortedBy: sortTerm ascending: ascending predicate: searchTerm inContext: context];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest: request error: &error];
	[AZCoreRecord handleError: error];
	return results;
}

@end