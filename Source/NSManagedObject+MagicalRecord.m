//
//  NSManagedObject+MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSManagedObject+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSUInteger defaultBatchSize = 20;
static NSString *const kURICodingKey = @"MRManagedObjectURI";

@interface NSManagedObject (MOGenerator_)

+ (NSEntityDescription *) entityInManagedObjectContext: (NSManagedObjectContext *) context;
+ (id) insertInManagedObjectContext: (NSManagedObjectContext *) context;

@end

@implementation NSManagedObject (MagicalRecord)

#pragma mark - NSCoding

- (id) initWithCoder: (NSCoder *) decoder
{
	NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	NSURL *URI = [decoder decodeObjectForKey: kURICodingKey];
	NSManagedObjectID *objectID = [psc managedObjectIDForURIRepresentation: URI];
	
	NSError *error = nil;
	id ret = [[NSManagedObjectContext defaultContext] existingObjectWithID:objectID error:&error];
	[MagicalRecord handleError:error];
	
	return ret;
}
- (void) encodeWithCoder: (NSCoder *) coder
{
	[coder encodeObject: self.URI forKey: kURICodingKey];
}

#pragma mark - Instance Methods

- (id) inContext: (NSManagedObjectContext *) context
{
	NSParameterAssert(context);
	
	NSManagedObjectContext *myContext = self.managedObjectContext;
	if (!myContext)
		myContext = [NSManagedObjectContext defaultContext];
	
	if ([self.objectID isTemporaryID])
	{
		NSError *error = nil;
		[myContext obtainPermanentIDsForObjects: [NSArray arrayWithObject: self] error: &error];
		[MagicalRecord handleError: error];
	}
	
	if ([context isEqual:self.managedObjectContext])
		return self;

	NSError *error = nil;
	NSManagedObject *inContext = [context existingObjectWithID: self.objectID error: &error];
	[MagicalRecord handleError: error];
	
	return inContext;
}
- (id) inThreadContext 
{
	NSManagedObject *weakSelf = self;
	return [weakSelf inContext: [NSManagedObjectContext contextForCurrentThread]];
}

- (void) delete
{
	[self deleteInContext: self.managedObjectContext];
}
- (void) deleteInContext: (NSManagedObjectContext *) context
{
	[context deleteObject: [self inContext: context]];
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
		
		[MagicalRecord handleError: error];
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

+ (id) create
{	
	return [self createInContext: nil];
}
+ (id) createInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext contextForCurrentThread];
	
	if ([self respondsToSelector: @selector(insertInManagedObjectContext:)]) 
		return [self insertInManagedObjectContext: context];

	NSString *entityName = NSStringFromClass([self class]);
	return [NSEntityDescription insertNewObjectForEntityForName: entityName inManagedObjectContext: context];
}

#pragma mark - Entity deletion

+ (BOOL) deleteAllMatchingPredicate: (NSPredicate *) predicate
{
	return [self deleteAllMatchingPredicate: predicate inContext: [NSManagedObjectContext defaultContext]];
}
+ (BOOL) deleteAllMatchingPredicate: (NSPredicate *) predicate inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWithPredicate: predicate inContext: context];
	request.includesPropertyValues = NO;
	
	NSArray *objects = [context executeFetchRequest: request error: NULL];
	[objects makeObjectsPerformSelector:@selector(deleteInContext:) withObject:context];
	
	return YES;
}

+ (BOOL) truncateAll
{
	return [self truncateAllInContext: nil];
}
+ (BOOL) truncateAllInContext: (NSManagedObjectContext *) context
{
	if (!context)
		context = [NSManagedObjectContext defaultContext];
	
	NSArray *objects = [self findAllInContext: context];
	[objects makeObjectsPerformSelector:@selector(deleteInContext:) withObject:context];

	return YES;
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
	[MagicalRecord handleError: error];
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

	if (searchTerm) {
		NSSortDescriptor *sortBy = [NSSortDescriptor sortDescriptorWithKey: sortTerm ascending: ascending];
		request.sortDescriptors = [NSArray arrayWithObject: sortBy];
	}
	
	return request;
}

#pragma mark - Singleton-fetching Fetch Request Convenience Methods

+ (id) findFirst
{
	return [self findFirstSortedBy: nil ascending: NO predicate: nil];
}
+ (id) findFirstInContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: nil inContext: context];
}

+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm];
}
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm inContext: context];
}

+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm attributes: attributes];
}
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: nil ascending: NO predicate: searchTerm attributes: attributes inContext: context];
}

+ (id) findFirstWhere: (NSString *) property equals: (id) searchValue
{
	return [self findFirstWhere: property equals: searchValue sortedBy: nil ascending: NO];
}
+ (id) findFirstWhere: (NSString *) property equals: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	return [self findFirstWhere: property equals: searchValue sortedBy: nil ascending: NO inContext: context];
}
+ (id) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstWhere: property equals: searchValue sortedBy: sortTerm ascending: ascending inContext: nil];
}
+ (id) findFirstWhere: (NSString *) property equals: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat: @"%K = %@", property, searchValue];
	return [self findFirstSortedBy: property ascending: NO predicate: predicate inContext: context];
}

+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: nil attributes: nil];
}
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: nil attributes: nil inContext: context];
}
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm attributes: nil];
}
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self findFirstSortedBy: sortTerm ascending: ascending predicate: searchTerm attributes: nil inContext: context];
}

+ (id) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes
{
	return [self findFirstSortedBy: sortBy ascending: ascending predicate: searchTerm attributes: attributes inContext: nil];
}
+ (id) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending predicate: (NSPredicate *) searchTerm attributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
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
	[MagicalRecord handleError: error];
	return results;
}

@end