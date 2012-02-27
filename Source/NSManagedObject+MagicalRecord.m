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

- (id) objectWithMinValueFor: (NSString *) property 
{
	return [self objectWithMinValueFor: property inContext: self. managedObjectContext];
}
- (id) objectWithMinValueFor: (NSString *) property inContext: (NSManagedObjectContext *) context
{
	NSPredicate *searchFor = [NSPredicate predicateWithFormat:@"SELF = %@ AND %K = min(%@)", self, property, property];
	return [[self class] findFirstWithPredicate: searchFor inContext: context];
}

- (id) objectWithMaxValueFor: (NSString *) property 
{
	return [self objectWithMaxValueFor: property inContext: self. managedObjectContext];
}
- (id) objectWithMaxValueFor: (NSString *) property inContext: (NSManagedObjectContext *) context
{
	NSPredicate *searchFor = [NSPredicate predicateWithFormat:@"SELF = %@ AND %K = max(%@)", self, property, property];
	return [[self class] findFirstWithPredicate: searchFor inContext: context];
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

#pragma mark - Fetch Request Helpers

+ (NSFetchRequest *) createFetchRequest
{
	return [self createFetchRequestInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) createFetchRequestInContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [NSFetchRequest new];
	request.entity = [self entityDescriptionInContext: context];
	return request;	
}

+ (NSArray *) executeFetchRequest: (NSFetchRequest *) request 
{
	return [self executeFetchRequest: request inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) executeFetchRequest: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context
{
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest: request error: &error];
	[MagicalRecord handleError: error];
	
	return results;
}

+ (id) executeFetchRequestAndReturnFirstObject: (NSFetchRequest *) request
{
	return [self executeFetchRequestAndReturnFirstObject: request inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) executeFetchRequestAndReturnFirstObject: (NSFetchRequest *) request inContext: (NSManagedObjectContext *) context
{
	request.fetchLimit = 1;
	
	NSArray *results = [self executeFetchRequest: request inContext: context];
	return [results lastObject];
}

+ (NSArray *) ascendingSortDescriptors: (NSArray *) attributesToSortBy
{
	return [self sortAscending: YES attributes: attributesToSortBy];
}
+ (NSArray *) descendingSortDescriptors: (NSArray *) attributesToSortBy
{
	return [self sortAscending: NO attributes: attributesToSortBy];
}
+ (NSArray *) sortAscending: (BOOL) ascending attributes: (NSArray *) attributesToSortBy
{
	NSMutableArray * attributes = [NSMutableArray array];
	[attributesToSortBy enumerateObjectsUsingBlock: ^(NSString *attributeName, NSUInteger idx, BOOL *stop) {
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey: attributeName ascending: ascending];
		[attributes addObject: sortDescriptor];
	}];
	
	return [attributes copy];
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
	return [self entityDescriptionInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSEntityDescription *) entityDescriptionInContext: (NSManagedObjectContext *) context
{
	if ([self respondsToSelector: @selector(entityInManagedObjectContext:)]) 
	{
		NSEntityDescription *entity = [self performSelector: @selector(entityInManagedObjectContext:) withObject: context];
		return entity;
	}
	else
	{
		NSString *entityName = NSStringFromClass([self class]);
		return [NSEntityDescription entityForName: entityName inManagedObjectContext: context];
	}
}

#pragma mark - Entity Creation

+ (id) create
{	
	return [self createInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) createInContext: (NSManagedObjectContext *) context
{
	if ([self respondsToSelector: @selector(insertInManagedObjectContext:)]) 
		return [self performSelector: @selector(insertInManagedObjectContext:) withObject: context];

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
	
	NSArray *objects = [self executeFetchRequest: request inContext: context];
	[objects enumerateObjectsUsingBlock: ^(NSManagedObject *obj, NSUInteger idx, BOOL *stop) {
		[obj deleteInContext: context];
	}];
	
	return YES;
}

+ (BOOL) truncateAll
{
	return [self truncateAllInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (BOOL) truncateAllInContext: (NSManagedObjectContext *) context
{
	NSArray *entities = [self findAllInContext: context];
	[entities enumerateObjectsUsingBlock: ^(NSManagedObject *obj, NSUInteger idx, BOOL *stop) {
		[obj deleteInContext: context];
	}];

	return YES;
}

#pragma mark - Entity Count

+ (BOOL) hasAtLeastOneEntity
{
	return [self hasAtLeastOneEntityInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (BOOL) hasAtLeastOneEntityInContext: (NSManagedObjectContext *) context
{
	return ([self countOfEntitiesWithContext: context] > 0);
}

+ (NSUInteger) countOfEntities
{
	return [self countOfEntitiesWithContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (NSUInteger) countOfEntitiesWithContext: (NSManagedObjectContext *) context
{
	NSError *error = nil;
	NSUInteger count = [context countForFetchRequest: [self createFetchRequestInContext: context] error: &error];
	[MagicalRecord handleError:error];
	return count;
}
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter
{
	return [self countOfEntitiesWithPredicate: searchFilter inContext: [NSManagedObjectContext defaultContext]];
}
+ (NSUInteger) countOfEntitiesWithPredicate: (NSPredicate *) searchFilter inContext: (NSManagedObjectContext *) context;
{
	NSError *error = nil;
	NSFetchRequest *request = [self createFetchRequestInContext: context];
	request.predicate = searchFilter;
	
	NSUInteger count = [context countForFetchRequest: request error: &error];
	[MagicalRecord handleError: error];
	return count;
}

#pragma mark - Singleton-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestFirst
{
	return [self requestFirstInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestFirstInContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllInContext: context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self requestFirstWithPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWithPredicate: searchTerm inContext: context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue
{
	return [self requestFirstWhere: property isEqualTo: searchValue inContext: [NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWhere: property isEqualTo: searchValue inContext: context];
	request.fetchLimit = 1;
	return request;
}
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestFirstWhere: property isEqualTo: searchValue sortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllWhere: property isEqualTo: searchValue sortedBy: sortTerm ascending: ascending inContext: context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllSortedBy: sortTerm ascending: ascending inContext: context];
	request.fetchLimit = 1;
	return request;
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm
{
	return [self requestFirstSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: context];
	request.fetchLimit = 1;
	return request;
}

#pragma mark - Array-returning Fetch Request Factory Methods

+ (NSFetchRequest *) requestAll
{
	return [self createFetchRequestInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestAllInContext: (NSManagedObjectContext *) context
{
	return [self createFetchRequestInContext: context];
}

+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm
{
	return [self requestAllWithPredicate:searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self createFetchRequestInContext: context];
	request.predicate = searchTerm;

	return request;
}

+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value
{
	return [self requestAllWhere: property isEqualTo: value inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value inContext: (NSManagedObjectContext *) context
{
	return [self requestAllWithPredicate: [NSPredicate predicateWithFormat: @"%K = %@", property, value] inContext: context];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestAllWhere: property isEqualTo: value sortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: [NSPredicate predicateWithFormat: @"%K = %@", property, value] inContext: context];
}

+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: nil];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: nil inContext: context];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm
{
	return [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSFetchRequest *) requestAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self createFetchRequestInContext: context];
	request.predicate = searchTerm;
	request.fetchBatchSize = self.defaultBatchSize;

	NSSortDescriptor *sortBy = [NSSortDescriptor sortDescriptorWithKey: sortTerm ascending: ascending];
	request.sortDescriptors = [NSArray arrayWithObject: sortBy];
	
	return request;
}

#pragma mark - Singleton-fetching Fetch Request Convenience Methods

+ (id) findFirst
{
	return [self findFirstInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstInContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequestAndReturnFirstObject: [self requestAll] inContext: context];
}

+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm
{
	return [self findFirstWithPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequestAndReturnFirstObject: [self requestAllWithPredicate: searchTerm inContext: context]];
}
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm andRetrieveAttributes: (NSArray *) attributes
{
	return [self findFirstWithPredicate: searchTerm andRetrieveAttributes: attributes inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstWithPredicate: (NSPredicate *) searchTerm andRetrieveAttributes: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestFirstWithPredicate: searchTerm inContext: context];
	request.propertiesToFetch = attributes;
	
	return [self executeFetchRequestAndReturnFirstObject: request inContext: context];
}

+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue
{
	return [self findFirstWhere: property isEqualTo: searchValue inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequestAndReturnFirstObject: [self requestAllWhere: property isEqualTo: searchValue inContext: context] inContext: context];
}
+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstWhere: property isEqualTo: searchValue sortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstWhere: (NSString *) property isEqualTo: (id) searchValue sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequestAndReturnFirstObject: [self requestAllWhere: property isEqualTo: searchValue sortedBy: sortTerm ascending: ascending inContext: context] inContext: context];
}

+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findFirstSortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequestAndReturnFirstObject: [self requestAllSortedBy: sortTerm ascending: ascending inContext: context] inContext: context];
}
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm
{
	return [self findFirstSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequestAndReturnFirstObject: [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: context] inContext: context];
}
+ (id) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm andRetrieveAttributes: (id) firstAttribute, ...
{
	NSMutableArray *attribs = [NSMutableArray array];
	
	va_list args;
	id obj;
	if (firstAttribute) 
	{
		[attribs addObject: firstAttribute];
		va_start(args, firstAttribute);
		while ((obj = va_arg(args, id)))
			[attribs addObject: obj];
		va_end(args);
	}
	
	return [self findFirstSortedBy: sortBy ascending: ascending withPredicate: searchTerm attributesToRetrieve: attribs];
}
+ (id) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context andRetrieveAttributes: (id) firstAttribute, ...
{
	NSMutableArray *attribs = [NSMutableArray array];
	
	va_list args;
	id obj;
	if (firstAttribute)
	{
		[attribs addObject: firstAttribute];
		va_start(args, firstAttribute);
		while ((obj = va_arg(args, id)))
			[attribs addObject: obj];
		va_end(args);
	}
	
	return [self findFirstSortedBy: sortBy ascending: ascending withPredicate: searchTerm attributesToRetrieve: attribs inContext: context];
}
+ (id) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm attributesToRetrieve: (NSArray *) attributes
{
	return [self findFirstSortedBy: sortBy ascending: ascending withPredicate: searchTerm attributesToRetrieve: attributes inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (id) findFirstSortedBy: (NSString *) sortBy ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm attributesToRetrieve: (NSArray *) attributes inContext: (NSManagedObjectContext *) context
{
	NSFetchRequest *request = [self requestFirstSortedBy: sortBy ascending: ascending withPredicate: searchTerm inContext: context];
	request.propertiesToFetch = attributes;
	
	return [self executeFetchRequestAndReturnFirstObject: request inContext: context];
}

#pragma mark - Array-fetching Fetch Request Convenience Methods

+ (NSArray *) findAll
{
	return [self findAllInContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) findAllInContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequest: [self requestAllInContext: context] inContext: context];
}

+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm
{
	return [self findAllWithPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) findAllWithPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequest: [self requestAllWithPredicate: searchTerm inContext: context] inContext: context];
}

+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value
{
	return [self findAllWhere: property isEqualTo: value inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequest: [self requestAllWhere: property isEqualTo: value inContext: context] inContext: context];
}
+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findAllWhere: property isEqualTo: value sortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) findAllWhere: (NSString *) property isEqualTo: (id) value sortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequest: [self requestAllWhere: property isEqualTo: value sortedBy: sortTerm ascending: ascending inContext: context] inContext: context];
}

+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending
{
	return [self findAllSortedBy: sortTerm ascending: ascending inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending inContext: (NSManagedObjectContext *) context
{
	return [self executeFetchRequest: [self requestAllSortedBy: sortTerm ascending: ascending inContext: context] inContext: context];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm
{
	return [self findAllSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: [NSManagedObjectContext contextForCurrentThread]];
}
+ (NSArray *) findAllSortedBy: (NSString *) sortTerm ascending: (BOOL) ascending withPredicate: (NSPredicate *) searchTerm inContext: (NSManagedObjectContext *) context
{
	return MRFetchExecute(context, [self requestAllSortedBy: sortTerm ascending: ascending withPredicate: searchTerm inContext: context]);
}

@end