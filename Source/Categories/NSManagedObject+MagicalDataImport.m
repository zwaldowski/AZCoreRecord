//
//  NSManagedObject+MagicalDataImport.m
//  MagicalRecord
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import <objc/message.h>

NSString * const kMagicalRecordImportCustomDateFormat = @"dateFormat";
NSString * const kMagicalRecordImportDefaultDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

NSString * const kMagicalRecordImportMapKey = @"mappedKey";
NSString * const kMagicalRecordImportClassNameKey = @"className";

NSString * const kMagicalRecordImportPrimaryAttributeKey = @"primaryAttribute";
NSString * const kMagicalRecordImportRelationshipPrimaryKey = @"primaryKey";

static NSString * attributeNameFromString(NSString *value)
{
	NSString *firstCharacter = [[value substringToIndex:1] capitalizedString];
	return [firstCharacter stringByAppendingString:[value substringFromIndex:1]];
}

static NSString *primaryKeyNameFromString(NSString *value)
{
	NSString *firstCharacter = [[value substringToIndex:1] lowercaseString];
	return [firstCharacter stringByAppendingFormat:@"%@ID", [value substringFromIndex:1]];
}

@implementation NSManagedObject (MagicalDataImport)

- (NSManagedObject *)_createInstanceForEntity:(NSEntityDescription *)entityDescription withDictionary:(id)objectData
{
	NSManagedObject *relatedObject = [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] 
																   inManagedObjectContext:[self managedObjectContext]];
	
	[relatedObject importValuesFromDictionary:objectData];
	
	return relatedObject;
}

- (NSManagedObject *)_findObjectForRelationship:(NSRelationshipDescription *)relationshipInfo withData:(id)singleRelatedObjectData
{
	if ([singleRelatedObjectData isKindOfClass:[NSManagedObject class]]) {
		if (!([[singleRelatedObjectData entity] isKindOfEntity:relationshipInfo.destinationEntity] || [[singleRelatedObjectData entity] isEqual:relationshipInfo.destinationEntity]))
			return nil;
		return singleRelatedObjectData;
	} else if ([singleRelatedObjectData isKindOfClass:[NSURL class]]) {
		NSManagedObjectID *objectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:singleRelatedObjectData];
		return [self.managedObjectContext existingObjectWithID:objectID error:nil];
	} else if ([singleRelatedObjectData isKindOfClass:[NSManagedObjectID class]]) {
		return [self.managedObjectContext existingObjectWithID:singleRelatedObjectData error:nil];
	}
	
	id relatedValue = nil;
	
	NSEntityDescription *destination = [relationshipInfo destinationEntity];
	
	if ([singleRelatedObjectData isKindOfClass:[NSNumber class]] || [singleRelatedObjectData isKindOfClass:[NSString class]])
		relatedValue = singleRelatedObjectData;
	else if ([singleRelatedObjectData isKindOfClass:[NSDictionary class]]) {
        
        NSString *destinationKey = [relationshipInfo.userInfo objectForKey:kMagicalRecordImportClassNameKey];
        NSString *destinationName = [singleRelatedObjectData objectForKey:destinationKey];
        if (destinationName) {
            NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:[self managedObjectContext]];
            if ([customDestination isKindOfEntity:destination])
                destination = customDestination;
        }
        
		NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
		NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey:kMagicalRecordImportRelationshipPrimaryKey] ?: primaryKeyNameFromString(relationshipInfo.destinationEntity.name);	
		NSAttributeDescription *primaryKeyAttribute = [destinationEntity.attributesByName valueForKey:primaryKeyName];
		NSString *lookupKey = [[primaryKeyAttribute userInfo] valueForKey:kMagicalRecordImportMapKey] ?: [primaryKeyAttribute name];
		relatedValue = [singleRelatedObjectData valueForKeyPath:lookupKey];
	}
	
	if (!relatedValue)
		return nil;

	Class managedObjectClass = NSClassFromString([destination managedObjectClassName]);
	NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey:kMagicalRecordImportRelationshipPrimaryKey] ?: primaryKeyNameFromString(relationshipInfo.destinationEntity.name);
	id object = [managedObjectClass findFirstWhere:primaryKeyName isEqualTo:relatedValue inContext:self.managedObjectContext];
	if ([singleRelatedObjectData isKindOfClass:[NSDictionary class]])
		[object updateValuesFromDictionary:singleRelatedObjectData];
	return object;
}

- (void)_setAttributes:(NSDictionary *)attributes forDictionary:(NSDictionary *)objectData {
	[attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeInfo, BOOL *stop) {
		NSString *key = [attributeInfo.userInfo valueForKey:kMagicalRecordImportMapKey] ?: attributeInfo.name;
		if (!key.length)
			return;
		
		id value = [objectData objectForKey:key];
        
        for (int i = 1; i < 10 && value == nil; i++)
        {
            NSString *attributeName = [NSString stringWithFormat:@"%@.%d", key, i];
            key = [[attributeInfo userInfo] valueForKey:attributeName];
            value = [objectData valueForKeyPath:key];
        }
		
		NSAttributeType attributeType = [attributeInfo attributeType];
		NSString *desiredAttributeType = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportClassNameKey];
        
        if ([key isEqualToString:@"nullTestAttribute"]) {
            NSLog(@"%@ %@", value, NSStringFromClass([value class]));
        }
        
        switch (attributeType) {
            case NSDateAttributeType:
                if ([value isKindOfClass:[NSString class]]) {
                    NSString *dateFormat = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportCustomDateFormat];
                    value = MRDateFromString(value, dateFormat ?: kMagicalRecordImportDefaultDateFormat);
                }
                value = MRDateAdjustForDST(value);
                break;
                
            default:
                if (desiredAttributeType && [desiredAttributeType hasSuffix:@"Color"])
                    value = MRColorFromString(value);
                
                if (!value) // if it just wasn't set, leave the default
                    return;
                
                if (value == [NSNull null]) // if it was *explicitly* set to nil, set
                    value = nil;
                break;
        }
		
		[self setValue:value forKey:attributeName];
	}];
}

- (void)_addObject:(NSManagedObject *)relatedObject forRelationship:(NSRelationshipDescription *)relationshipInfo {
	NSAssert2(relatedObject, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), relationshipInfo.name);
	NSAssert2([[relatedObject entity] isKindOfEntity:relationshipInfo.destinationEntity], @"related object entity %@ not same as destination entity %@", [[relatedObject entity] name], [[relationshipInfo destinationEntity] name]);
	
	//add related object to set
	SEL selector = NSSelectorFromString([NSString stringWithFormat:@"add%@Object:", attributeNameFromString([relationshipInfo name])]);
	
	@try 
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self performSelector:selector withObject:relatedObject];
#pragma clank diagnostic pop
	}
	@catch (NSException *exception) 
	{
		ARLog(@"Adding object for relationship failed: %@\n", relationshipInfo);
		ARLog(@"relatedObject.entity %@", [relatedObject entity]);
		ARLog(@"relationshipInfo.destinationEntity %@", [relationshipInfo destinationEntity]);
		ARLog(@"perform selector error: %@", exception);
	}
}

- (void)_setRelationships:(NSDictionary *)relationships forDictionary:(NSDictionary *)relationshipData withBlock:(NSManagedObject *(^)(NSRelationshipDescription *,id))setRelationship
{
	[relationships enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipInfo, BOOL *stop) {
		NSString *lookupKey = [relationshipInfo.userInfo valueForKey:kMagicalRecordImportMapKey] ?: relationshipName;
		
		id relatedObjectData = [relationshipData valueForKey:lookupKey];
		if (!relatedObjectData || [relatedObjectData isEqual:[NSNull null]]) 
			return;
		
		if (relationshipInfo.isToMany) {
			for (id singleRelatedObjectData in relatedObjectData)  {
				NSManagedObject *obj = setRelationship(relationshipInfo, singleRelatedObjectData);
				[self _addObject:obj forRelationship:relationshipInfo];
			}
		} else {
			NSManagedObject *obj = setRelationship(relationshipInfo, relatedObjectData);
			[self _addObject:obj forRelationship:relationshipInfo];
		}
	}];
}

- (void) importValuesFromDictionary:(NSDictionary *)objectData
{
	@autoreleasepool {
		[self _setAttributes:self.entity.attributesByName forDictionary:objectData];
		NSManagedObjectContext *context = self.managedObjectContext;
		__block id safeSelf = self;
		[self _setRelationships:self.entity.relationshipsByName forDictionary:objectData withBlock:^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData) {			
			NSManagedObject *relatedObject = nil;
			
			if ([objectData isKindOfClass:[NSDictionary class]])  {
				NSEntityDescription *destination = [relationshipInfo destinationEntity];
				NSString *destinationKey = [relationshipInfo.userInfo objectForKey:kMagicalRecordImportClassNameKey];
				NSString *destinationName = [objectData objectForKey:destinationKey];
				if (destinationName) {
					NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:context];
					if ([customDestination isKindOfEntity:destination])
						destination = customDestination;
				}
				relatedObject = [safeSelf _createInstanceForEntity:destination withDictionary:objectData];
			} else {
				relatedObject = [safeSelf _findObjectForRelationship:relationshipInfo withData:objectData];
			}
			return relatedObject;
		}];
	}
}

- (void)updateValuesFromDictionary:(NSDictionary *)objectData
{
	@autoreleasepool {
		[self _setAttributes:self.entity.attributesByName forDictionary:objectData];
		__block NSManagedObject *safeSelf = self;
		[self _setRelationships:self.entity.relationshipsByName forDictionary:objectData withBlock:^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData){
			NSManagedObject *relatedObject = [safeSelf _findObjectForRelationship:relationshipInfo withData:objectData];
			
			if (relatedObject) {
				if ([objectData isKindOfClass:[NSDictionary class]])
					[relatedObject importValuesFromDictionary:objectData];
				return relatedObject;
			}

			NSEntityDescription *destination = [relationshipInfo destinationEntity];
            
            if ([objectData isKindOfClass:[NSDictionary class]]) {
                NSString *destinationKey = [relationshipInfo.userInfo objectForKey:kMagicalRecordImportClassNameKey];
                NSString *destinationName = [objectData objectForKey:destinationKey];
                if (destinationName) {
                    NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:safeSelf.managedObjectContext];
                    if ([customDestination isKindOfEntity:destination])
                        destination = customDestination;
                }
            }
			return [safeSelf _createInstanceForEntity:destination withDictionary:objectData];
		 }];
	}
}

+ (id)importFromDictionary:(NSDictionary *)objectData {
	return [self importFromDictionary:objectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (id)importFromDictionary:(NSDictionary *)objectData inContext:(NSManagedObjectContext *)context {
	NSManagedObject *managedObject = [self createInContext:context];
	[managedObject importValuesFromDictionary:objectData];
	return managedObject;
}

+ (id)updateFromDictionary:(NSDictionary *)objectData {
	return [self updateFromDictionary:objectData inContext:[NSManagedObjectContext defaultContext]];	
}

+ (id)updateFromDictionary:(NSDictionary *)objectData inContext:(NSManagedObjectContext *)context
{
	NSEntityDescription *entity = [self entityDescription];
	NSString *attributeKey = [entity.userInfo valueForKey:kMagicalRecordImportPrimaryAttributeKey] ?: primaryKeyNameFromString(entity.name);
	NSAttributeDescription *primaryAttribute = [entity.attributesByName valueForKey:attributeKey];
	NSAssert3(primaryAttribute, @"Unable to determine primary attribute for %@. Specify either an attribute named %@ or the primary key in userInfo named '%@'", entity.name, attributeKey, kMagicalRecordImportPrimaryAttributeKey);
	
	NSString *lookupKey = [primaryAttribute.userInfo valueForKey:kMagicalRecordImportMapKey] ?: primaryAttribute.name;
	id value = [objectData valueForKey:lookupKey];
	
	NSManagedObject *managedObject = [self findFirstWhere:lookupKey isEqualTo:value inContext:context];
	if (!managedObject) {
		managedObject = [self createInContext:context];
	}
	[managedObject updateValuesFromDictionary:objectData];
	
	return managedObject;
}

+ (NSArray *)importFromArray:(NSArray *)listOfObjectData
{
	return [self importFromArray:listOfObjectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context
{
	__block NSArray *objectIDs = nil;
	
	[MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) {
		NSMutableArray *objects = [NSMutableArray array];
		
		for (NSDictionary *objectData in listOfObjectData) {
			[objects addObject:[self importFromDictionary:objectData inContext:localContext]];
		}
		
		if ([context obtainPermanentIDsForObjects:objects error:nil])
			objectIDs = [objects valueForKey:@"objectID"];
	}];
	
	return [self findAllWithPredicate:[NSPredicate predicateWithFormat:@"self IN %@", objectIDs] inContext:context];
}

+ (NSArray *)updateFromArray:(NSArray *)listOfObjectData {
	return [self updateFromArray:listOfObjectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)updateFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context {
	__block NSArray *objectIDs = nil;
	
	[MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) {
		NSMutableArray *objects = [NSMutableArray array];
		
		for (NSDictionary *objectData in listOfObjectData) {
			[objects addObject:[self updateFromDictionary:objectData inContext:localContext]];
		}
		
		if ([context obtainPermanentIDsForObjects:objects error:nil])
			objectIDs = [objects valueForKey:@"objectID"];
	}];
	
	return [self findAllWithPredicate:[NSPredicate predicateWithFormat:@"self IN %@", objectIDs] inContext:context];
}

@end
