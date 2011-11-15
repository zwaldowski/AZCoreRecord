//
//  NSManagedObject+MagicalRecord.m
//  MagicalRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSManagedObject+MagicalRecord.h"

static NSUInteger defaultBatchSize = 20;
static NSString *const kURICodingKey = @"MRManagedObjectURI";

@interface NSManagedObject (MOGenerator_)
+ (NSEntityDescription *)entityInManagedObjectContext:(NSManagedObjectContext *)context;
+ (id)insertInManagedObjectContext:(NSManagedObjectContext *)context;
@end

@implementation NSManagedObject (MagicalRecord)

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
    NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
    NSURL *uri = [aDecoder decodeObjectForKey:kURICodingKey];
    NSManagedObjectID *moi = [psc managedObjectIDForURIRepresentation:uri];
    return [context objectWithID:moi];
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:self.uri forKey:kURICodingKey];
}

#pragma mark - Instance methods

- (id) inContext:(NSManagedObjectContext*)context 
{
	NSError *error = nil;
	NSManagedObject *inContext = [context existingObjectWithID:[self objectID] error:&error];
	[MagicalRecordHelpers handleErrors:error];
	
	return inContext;
}

- (id) inThreadContext 
{
	NSManagedObject *weakSelf = self;
	return [weakSelf inContext:[NSManagedObjectContext contextForCurrentThread]];
}

- (BOOL)deleteEntity {
	[self deleteInContext:[self managedObjectContext]];
	return YES;
}

- (void)delete {
	[self deleteInContext:[self managedObjectContext]];
}

- (void)deleteInContext:(NSManagedObjectContext *)context {
	[context deleteObject:[self inContext:context]];
}

- (id) objectWithMinValueFor:(NSString *)property inContext:(NSManagedObjectContext *)context
{
	NSPredicate *searchFor = [NSPredicate predicateWithFormat:@"SELF = %@ AND %K = min(%@)", self, property, property];
    return [[self class] findFirstWithPredicate:searchFor inContext:context];
}

- (id) objectWithMinValueFor:(NSString *)property 
{
	return [self objectWithMinValueFor:property inContext:[self  managedObjectContext]];
}

- (NSURL *)uri {
    NSManagedObjectID *objectID = self.objectID;
    
    if (objectID.isTemporaryID) {
        if ([self.managedObjectContext obtainPermanentIDsForObjects:[NSArray arrayWithObject:self] error:NULL])
            objectID = self.objectID;
        else
            return nil;
    }
    
    if (!objectID)
        return nil;
    
    return objectID.URIRepresentation;
}

#pragma mark - Default batch size

+ (void)setDefaultBatchSize:(NSUInteger)newBatchSize
{
    defaultBatchSize = newBatchSize;
}

+ (NSUInteger) defaultBatchSize
{
	return defaultBatchSize;
}

#pragma mark - Fetch request helpers

+ (NSFetchRequest *)createFetchRequest
{
	return [self createFetchRequestInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *)createFetchRequestInContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [NSFetchRequest new];
	request.entity = [self entityDescriptionInContext:context];
	return request;	
}

+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request 
{
	return [self executeFetchRequest:request inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) executeFetchRequest:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	NSError *error = nil;
	
	NSArray *results = [context executeFetchRequest:request error:&error];
	[MagicalRecordHelpers handleErrors:error];
	return results;	
}

+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request
{
	return [self executeFetchRequestAndReturnFirstObject:request inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) executeFetchRequestAndReturnFirstObject:(NSFetchRequest *)request inContext:(NSManagedObjectContext *)context
{
	[request setFetchLimit:1];
	
	NSArray *results = [self executeFetchRequest:request inContext:context];
	if ([results count] == 0)
	{
		return nil;
	}
	return [results objectAtIndex:0];
}

+ (NSArray *) sortAscending:(BOOL)ascending attributes:(NSArray *)attributesToSortBy
{
	NSMutableArray *attributes = [NSMutableArray array];
	
	for (NSString *attributeName in attributesToSortBy) 
	{
		NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:attributeName ascending:ascending];
		[attributes addObject:sortDescriptor];
	}
	
	return attributes;
}

+ (NSArray *) ascendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self sortAscending:YES attributes:attributesToSortBy];
}

+ (NSArray *) descendingSortDescriptors:(NSArray *)attributesToSortBy
{
	return [self sortAscending:NO attributes:attributesToSortBy];
}

#pragma mark - Entity description

+ (NSEntityDescription *)entityDescription
{
	return [self entityDescriptionInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSEntityDescription *)entityDescriptionInContext:(NSManagedObjectContext *)context
{
	if ([self respondsToSelector:@selector(entityInManagedObjectContext:)]) 
	{
		NSEntityDescription *entity = [self performSelector:@selector(entityInManagedObjectContext:) withObject:context];
		return entity;
	}
	else
	{
		NSString *entityName = NSStringFromClass([self class]);
		return [NSEntityDescription entityForName:entityName inManagedObjectContext:context];
	}
}

+ (NSArray *)propertiesNamed:(NSArray *)properties
{
	NSEntityDescription *description = [self entityDescription];
	NSMutableArray *propertiesWanted = [NSMutableArray array];
	
	if (properties)
	{
		NSDictionary *propDict = [description propertiesByName];
		
		for (NSString *propertyName in properties)
		{
			NSPropertyDescription *property = [propDict objectForKey:propertyName];
			if (property)
			{
				[propertiesWanted addObject:property];
			}
			else
			{
				ARLog(@"Property '%@' not found in %@ properties for %@", propertyName, [propDict count], NSStringFromClass(self));
			}
		}
	}
	return propertiesWanted;
}

#pragma mark - Entity creation

+ (id)createEntity
{	
	return [self createInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)create
{	
	return [self createInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id) createInContext:(NSManagedObjectContext *)context
{
	if ([self respondsToSelector:@selector(insertInManagedObjectContext:)]) 
	{
		id entity = [self performSelector:@selector(insertInManagedObjectContext:) withObject:context];
		return entity;
	}
	else
	{
		NSString *entityName = NSStringFromClass([self class]);
		return [NSEntityDescription insertNewObjectForEntityForName:entityName inManagedObjectContext:context];
	}
}

#pragma mark - Entity deletion

+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate
{
	return [self deleteAllMatchingPredicate:predicate inContext:[NSManagedObjectContext defaultContext]];
}

+ (BOOL) deleteAllMatchingPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self requestAllWithPredicate:predicate inContext:context];
	[request setIncludesSubentities:NO];
	[request setIncludesPropertyValues:NO];
	
	NSArray *objectsToTruncate = [self executeFetchRequest:request inContext:context];
	
	for (id objectToTruncate in objectsToTruncate) 
	{
		[objectToTruncate deleteInContext:context];
	}
	
	return YES;
}

+ (BOOL) truncateAll
{
	[self truncateAllInContext:[NSManagedObjectContext contextForCurrentThread]];
	return YES;
}

+ (BOOL) truncateAllInContext:(NSManagedObjectContext *)context
{
	NSArray *allEntities = [self findAllInContext:context];
	for (NSManagedObject *obj in allEntities)
	{
		[obj deleteInContext:context];
	}
	return YES;
}

#pragma mark - Counting entities

+ (NSNumber *)numberOfEntities
{
	return [self numberOfEntitiesWithContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSNumber *) numberOfEntitiesWithContext:(NSManagedObjectContext *)context
{
	return [NSNumber numberWithUnsignedInteger:[self countOfEntitiesWithContext:context]];
}

+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm;
{
	return [self numberOfEntitiesWithPredicate:searchTerm 
									 inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSNumber *) numberOfEntitiesWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	
	return [NSNumber numberWithUnsignedInteger:[self countOfEntitiesWithPredicate:searchTerm inContext:context]];
}

+ (NSUInteger) countOfEntities;
{
	return [self countOfEntitiesWithContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSUInteger) countOfEntitiesWithContext:(NSManagedObjectContext *)context;
{
	NSError *error = nil;
	NSUInteger count = [context countForFetchRequest:[self createFetchRequestInContext:context] error:&error];
	[MagicalRecordHelpers handleErrors:error];
	
	return count;
}

+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter;
{
	return [self countOfEntitiesWithPredicate:searchFilter inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSUInteger) countOfEntitiesWithPredicate:(NSPredicate *)searchFilter inContext:(NSManagedObjectContext *)context;
{
	NSError *error = nil;
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchFilter];
	
	NSUInteger count = [context countForFetchRequest:request error:&error];
	[MagicalRecordHelpers handleErrors:error];
	
	return count;
}

+ (BOOL) hasAtLeastOneEntity
{
	return [self hasAtLeastOneEntityInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (BOOL) hasAtLeastOneEntityInContext:(NSManagedObjectContext *)context
{
	return [[self numberOfEntitiesWithContext:context] intValue] > 0;
}

#pragma mark - Fetch requests for groups

+ (NSFetchRequest *) requestAll
{
	return [self createFetchRequestInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllInContext:(NSManagedObjectContext *)context
{
	return [self createFetchRequestInContext:context];
}

+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm
{
	return [self requestAllWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	return request;
}

+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value
{
	return [self requestAllWhere:property isEqualTo:value inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context
{
	return [self requestAllWithPredicate:[NSPredicate predicateWithFormat:@"%K = %@", property, value] inContext:context];
}

+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self requestAllWhere:property isEqualTo:value sortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	return [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:[NSPredicate predicateWithFormat:@"%K = %@", property, value] inContext:context];
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending
{
	return [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:nil];
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	return [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:nil inContext:context];
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm
{
	return [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context
{
	NSFetchRequest *request = [self createFetchRequestInContext:context];
	[request setPredicate:searchTerm];
	[request setIncludesSubentities:NO];
	[request setFetchBatchSize:[self defaultBatchSize]];
	NSSortDescriptor *sortBy = [NSSortDescriptor sortDescriptorWithKey:sortTerm ascending:ascending];
	[request setSortDescriptors:[NSArray arrayWithObject:sortBy]];
	return request;
}

#pragma mark - Fetch requests for single items

+ (NSFetchRequest *) requestFirst {
	return [self requestFirstInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestAllInContext:context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm {
	return [self requestFirstWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestAllWithPredicate:searchTerm inContext:context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue {
	return [self requestFirstWhere:property isEqualTo:searchValue inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestAllWhere:property isEqualTo:searchValue inContext:context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self requestFirstWhere:property isEqualTo:searchValue sortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestAllWhere:property isEqualTo:searchValue sortedBy:sortTerm ascending:ascending inContext:context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self requestFirstSortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm ascending:ascending inContext:context];
	request.fetchLimit = 1;
	return request;
}

+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm {
	return [self requestFirstSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchRequest *) requestFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:context];
	request.fetchLimit = 1;
	return request;
}

#pragma mark - Fetch requests for single items (deprecated)

+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue {
	return [self requestFirstWhere:attribute isEqualTo:searchValue];
}

+ (NSFetchRequest *) requestFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context {
	return [self requestFirstWhere:attribute isEqualTo:searchValue inContext:context];
}

#pragma mark - Fetching groups

+ (NSArray *)findAll {
	return [self findAllInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *)findAllInContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequest:[self requestAllInContext:context] inContext:context];	
}

+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm {
	return [self findAllWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *)findAllWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequest:[self requestAllWithPredicate:searchTerm inContext:context] inContext:context];
}

+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value {
	return [self findAllWhere:property isEqualTo:value inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequest:[self requestAllWhere:property isEqualTo:value inContext:context] inContext:context];
}

+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self findAllWhere:property isEqualTo:value sortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *) findAllWhere:(NSString *)property isEqualTo:(id)value sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequest:[self requestAllWhere:property isEqualTo:value sortedBy:sortTerm ascending:ascending inContext:context] inContext:context];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self findAllSortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequest:[self requestAllSortedBy:sortTerm ascending:ascending inContext:context] inContext:context];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm {
	return [self findAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSArray *)findAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequest:[self requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:context] inContext:context];
}

#pragma mark - Fetching object groups (deprecated)

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue {
	return [self findAllWhere:attribute isEqualTo:searchValue];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context {
	return [self findAllWhere:attribute isEqualTo:searchValue inContext:context];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self findAllWhere:attribute isEqualTo:searchValue sortedBy:sortTerm ascending:ascending];
}

+ (NSArray *)findByAttribute:(NSString *)attribute withValue:(id)searchValue andOrderBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	return [self findAllWhere:attribute isEqualTo:searchValue sortedBy:sortTerm ascending:ascending inContext:context];
}

#pragma mark - Fetching single objects

+ (id)findFirst {
	return [self findFirstInContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstInContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequestAndReturnFirstObject:[self requestAll] inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm {
	return [self findFirstWithPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequestAndReturnFirstObject:[self requestAllWithPredicate:searchTerm inContext:context]];
}

+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue {
	return [self findFirstWhere:property isEqualTo:searchValue inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequestAndReturnFirstObject:[self requestAllWhere:property isEqualTo:searchValue inContext:context] inContext:context];
}

+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self findFirstWhere:property isEqualTo:searchValue sortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstWhere:(NSString *)property isEqualTo:(id)searchValue sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequestAndReturnFirstObject:[self requestAllWhere:property isEqualTo:searchValue sortedBy:sortTerm ascending:ascending inContext:context] inContext:context];
}

+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending {
	return [self findFirstSortedBy:sortTerm ascending:ascending inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequestAndReturnFirstObject:[self requestAllSortedBy:sortTerm ascending:ascending inContext:context] inContext:context];
}

+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm {
	return [self findFirstSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context {
	return [self executeFetchRequestAndReturnFirstObject:[self requestAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm inContext:context] inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes {
	return [self findFirstWithPredicate:searchTerm andRetrieveAttributes:attributes inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(NSArray *)attributes inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestFirstWithPredicate:searchTerm inContext:context];
	request.propertiesToFetch = attributes;
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm andRetrieveAttributes:(id)firstAttribute, ... {
	NSMutableArray *attribs = [NSMutableArray array];
	va_list args;
	id obj;
	if (firstAttribute)
	{
		[attribs addObject:firstAttribute];
		va_start(args, firstAttribute);
		while ((obj = va_arg(args, id)))
			[attribs addObject:obj];
		va_end(args);
	}
	return [self findFirstSortedBy:sortBy ascending:ascending withPredicate:searchTerm attributesToRetrieve:attribs];
}

+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)firstAttribute, ... {
	NSMutableArray *attribs = [NSMutableArray array];
	va_list args;
	id obj;
	if (firstAttribute)
	{
		[attribs addObject:firstAttribute];
		va_start(args, firstAttribute);
		while ((obj = va_arg(args, id)))
			[attribs addObject:obj];
		va_end(args);
	}
	return [self findFirstSortedBy:sortBy ascending:ascending withPredicate:searchTerm attributesToRetrieve:attribs inContext:context];
}

+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm attributesToRetrieve:(NSArray *)attributes {
	return [self findFirstSortedBy:sortBy ascending:ascending withPredicate:searchTerm attributesToRetrieve:attributes inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (id)findFirstSortedBy:(NSString *)sortBy ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm attributesToRetrieve:(NSArray *)attributes inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *request = [self requestFirstSortedBy:sortBy ascending:ascending withPredicate:searchTerm inContext:context];
	request.propertiesToFetch = attributes;
	return [self executeFetchRequestAndReturnFirstObject:request inContext:context];
}

#pragma mark - Fetching single objects (deprecated)

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending andRetrieveAttributes:(id)firstAttribute, ... {
	NSMutableArray *attribs = [NSMutableArray array];
	va_list args;
	id obj;
	if (firstAttribute)
	{
		[attribs addObject:firstAttribute];
		va_start(args, firstAttribute);
		while ((obj = va_arg(args, id)))
			[attribs addObject:obj];
		va_end(args);
	}
	return [self findFirstSortedBy:sortBy ascending:ascending withPredicate:searchTerm attributesToRetrieve:attribs];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortBy ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context andRetrieveAttributes:(id)firstAttribute, ... {
	NSMutableArray *attribs = [NSMutableArray array];
	va_list args;
	id obj;
	if (firstAttribute)
	{
		[attribs addObject:firstAttribute];
		va_start(args, firstAttribute);
		while ((obj = va_arg(args, id)))
			[attribs addObject:obj];
		va_end(args);
	}
	return [self findFirstSortedBy:sortBy ascending:ascending withPredicate:searchTerm attributesToRetrieve:attribs inContext:context];
}

+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue {
	return [self findFirstWhere:attribute isEqualTo:searchValue];
}

+ (id)findFirstByAttribute:(NSString *)attribute withValue:(id)searchValue inContext:(NSManagedObjectContext *)context {
	return [self findFirstWhere:attribute isEqualTo:searchValue inContext:context];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending {
	return [self findFirstSortedBy:property ascending:ascending withPredicate:searchterm];
}

+ (id)findFirstWithPredicate:(NSPredicate *)searchterm sortedBy:(NSString *)property ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	return [self findFirstSortedBy:property ascending:ascending withPredicate:searchterm inContext:context];
}

#pragma mark - Fetched results controllers

#if TARGET_OS_IPHONE

+ (void) performFetch:(NSFetchedResultsController *)controller
{
	NSError *error = nil;
	if (![controller performFetch:&error])
	{
		[MagicalRecordHelpers handleErrors:error];
	}
}

+ (NSFetchedResultsController *) fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending 
{
	return [self fetchRequestAllGroupedBy:group
							withPredicate:searchTerm
								 sortedBy:sortTerm
								ascending:ascending
								inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath inContext:(NSManagedObjectContext *)context
{
	NSFetchedResultsController *controller = [self fetchRequestAllGroupedBy:groupingKeyPath 
															  withPredicate:searchTerm
																   sortedBy:sortTerm 
																  ascending:ascending
																  inContext:context];
	
	[self performFetch:controller];
	return controller;
}

+ (NSFetchedResultsController *) fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group
{
	return [self fetchRequest:request 
					groupedBy:group
					inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchedResultsController *) fetchRequest:(NSFetchRequest *)request groupedBy:(NSString *)group inContext:(NSManagedObjectContext *)context
{
	NSString *cacheName = TARGET_OS_IPHONE ? [NSString stringWithFormat:@"MagicalRecord-Cache-%@", NSStringFromClass([self class])] : nil;
	NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request managedObjectContext:context sectionNameKeyPath:group cacheName:cacheName];
	[self performFetch:controller];
	return controller;
}

+ (NSFetchedResultsController *) fetchAllSortedBy:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(NSPredicate *)searchTerm groupBy:(NSString *)groupingKeyPath
{
	return [self fetchAllSortedBy:sortTerm ascending:ascending withPredicate:searchTerm groupBy:groupingKeyPath  inContext:[NSManagedObjectContext contextForCurrentThread]];
}

+ (NSFetchedResultsController *) fetchRequestAllGroupedBy:(NSString *)group withPredicate:(NSPredicate *)searchTerm sortedBy:(NSString *)sortTerm ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context
{
	NSString *cacheName = TARGET_OS_IPHONE ? [NSString stringWithFormat:@"MagicalRecord-Cache-%@", NSStringFromClass(self)] : nil;

	NSFetchRequest *request = [self requestAllSortedBy:sortTerm 
											 ascending:ascending 
										 withPredicate:searchTerm
											 inContext:context];
	
	return [[NSFetchedResultsController alloc] initWithFetchRequest:request  managedObjectContext:context sectionNameKeyPath:group cacheName:cacheName];
}

#endif

@end