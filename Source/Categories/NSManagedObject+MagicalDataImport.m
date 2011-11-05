//
//  NSManagedObject+JSONHelpers.m
//  Gathering
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "CoreData+MagicalRecord.h"

static NSString * const kMagicalRecordImportCustomDateFormat = @"dateFormat";
static NSString * const kMagicalRecordImportDefaultDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

static NSString * const kMagicalRecordImportMapKey = @"mappedKey";
static NSString * const kMagicalRecordImportClassNameKey = @"className";

static NSString * const kMagicalRecordImportPrimaryAttributeKey = @"primaryAttribute";
static NSString * const kMagicalRecordImportRelationshipPrimaryKey = @"primaryKey";

@implementation NSManagedObject (MagicalRecord_DataImport)

- (NSManagedObject *)_createInstanceForEntity:(NSEntityDescription *)entityDescription withDictionary:(id)objectData
{
    NSManagedObject *relatedObject = [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] 
                                                                   inManagedObjectContext:[self managedObjectContext]];
    
    [relatedObject importValuesFromDictionary:objectData];
    
    return relatedObject;
}

- (NSManagedObject *)_findObjectForRelationship:(NSRelationshipDescription *)relationshipInfo withData:(id)singleRelatedObjectData
{
    NSString *destinationName = [singleRelatedObjectData objectForKey:kMagicalRecordImportClassNameKey];
    NSEntityDescription *destination = [relationshipInfo destinationEntity];
    if (destinationName) {
        NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:[self managedObjectContext]];
        if ([customDestination isKindOfEntity:destination])
            destination = customDestination;
    }
    
    id relatedValue = nil;
    NSManagedObject *objectForRelationship = nil;
    
    if ([singleRelatedObjectData isKindOfClass:[NSNumber class]] || [singleRelatedObjectData isKindOfClass:[NSString class]])
        relatedValue = singleRelatedObjectData;
    else if ([singleRelatedObjectData isKindOfClass:[NSDictionary class]]) {
        NSEntityDescription *destinationEntity = [relationshipInfo destinationEntity];
        NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey:kMagicalRecordImportRelationshipPrimaryKey] ?: primaryKeyNameFromString(relationshipInfo.destinationEntity.name);    
        NSAttributeDescription *primaryKeyAttribute = [destinationEntity.attributesByName valueForKey:primaryKeyName];
        NSString *lookupKey = [[primaryKeyAttribute userInfo] valueForKey:kMagicalRecordImportMapKey] ?: [primaryKeyAttribute name];
        relatedValue = [singleRelatedObjectData valueForKeyPath:lookupKey];
    }

    if (relatedValue) 
    {
        NSManagedObjectContext *context = [self managedObjectContext];
        Class managedObjectClass = NSClassFromString([destination managedObjectClassName]);
        NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey:kMagicalRecordImportRelationshipPrimaryKey] ?: primaryKeyNameFromString(relationshipInfo.destinationEntity.name);
        objectForRelationship = [managedObjectClass findFirstByAttribute:primaryKeyName
                                                               withValue:relatedValue
                                                               inContext:context];
    }

    return objectForRelationship;
}

- (void)_setAttributes:(NSDictionary *)attributes forDictionary:(NSDictionary *)objectData {
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeInfo, BOOL *stop) {
        NSString *key = [attributeInfo.userInfo valueForKey:kMagicalRecordImportMapKey] ?: attributeInfo.name;
        NSString *keyPath = [objectData valueForKeyPath:key];
        
        if (!keyPath.length)
            return;
        
        id value = [objectData valueForKeyPath:keyPath];
        
        NSAttributeType attributeType = [attributeInfo attributeType];
        NSString *desiredAttributeType = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportClassNameKey];
        
        if (desiredAttributeType && [desiredAttributeType hasSuffix:@"Color"]) {
            value = colorFromString(value);
        } else if (!desiredAttributeType && attributeType == NSDateAttributeType) {
            if (![value isKindOfClass:[NSDate class]]) 
            {
                NSString *dateFormat = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportCustomDateFormat];
                value = dateFromString([value description], dateFormat ?: kMagicalRecordImportDefaultDateFormat);
            }
            value = adjustDateForDST(value);
        }
        
        value = value != [NSNull null] ? value : nil;
        [self setValue:value forKey:attributeName];
    }];
}

- (void)_setRelationships:(NSDictionary *)relationships forDictionary:(NSDictionary *)relationshipData withBlock:(NSManagedObject *(^)(NSRelationshipDescription *,id))setRelationship
{
    [relationships enumerateKeysAndObjectsUsingBlock:^(NSString *relationshipName, NSRelationshipDescription *relationshipInfo, BOOL *stop) {
        NSString *lookupKey = [relationshipInfo.userInfo valueForKey:kMagicalRecordImportMapKey] ?: relationshipName;
        
        id relatedObjectData = [relationshipData valueForKey:lookupKey];
        if (!relatedObjectData || [relatedObjectData isEqual:[NSNull null]]) 
            return;
        
        void (^addObject)(NSManagedObject *) = ^(NSManagedObject *relatedObject){
            NSAssert2(relatedObject, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), relationshipInfo.name);
            NSAssert2([relatedObject entity] == [relationshipInfo destinationEntity], @"related object entity %@ not same as destination entity %@", [relatedObject entity], [relationshipInfo destinationEntity]);
            
            //add related object to set
            NSString *addRelationMessageFormat = [relationshipInfo isToMany] ? @"add%@Object:" : @"set%@:";
            NSString *addRelatedObjectToSetMessage = [NSString stringWithFormat:addRelationMessageFormat, attributeNameFromString([relationshipInfo name])];
            
            SEL selector = NSSelectorFromString(addRelatedObjectToSetMessage);
            
            @try 
            {
                [self performSelector:selector withObject:relatedObject];        
            }
            @catch (NSException *exception) 
            {
                ARLog(@"Adding object for relationship failed: %@\n", relationshipInfo);
                ARLog(@"relatedObject.entity %@", [relatedObject entity]);
                ARLog(@"relationshipInfo.destinationEntity %@", [relationshipInfo destinationEntity]);
                ARLog(@"perform selector error: %@", exception);
            }
        };
        
        if (relationshipInfo.isToMany) {
            for (id singleRelatedObjectData in relatedObjectData)  {
                NSManagedObject *obj = setRelationship(relationshipInfo, singleRelatedObjectData);
                addObject(obj);
            }
        } else {
            NSManagedObject *obj = setRelationship(relationshipInfo, relatedObjectData);
            addObject(obj);
        }
    }];
}

- (void) importValuesFromDictionary:(NSDictionary *)objectData
{
    @autoreleasepool {
        [self _setAttributes:self.entity.attributesByName forDictionary:objectData];
        [self _setRelationships:self.entity.relationshipsByName forDictionary:objectData  withBlock:^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData) {
            if ([objectData isKindOfClass:[NSURL class]]) {
                NSManagedObjectID *objectID = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectData];
                return [self.managedObjectContext existingObjectWithID:objectID error:nil];
            } else if ([objectData isKindOfClass:[NSManagedObjectID class]]) {
                return [self.managedObjectContext existingObjectWithID:objectData error:nil];
            } else if ([objectData isKindOfClass:[NSManagedObject class]]) {
                if (![[objectData entity] isKindOfEntity:relationshipInfo.destinationEntity])
                    return nil;
                
                return objectData;
            } else if ([objectData isKindOfClass:[NSDictionary class]])  {
                NSString *destinationName = [objectData objectForKey:kMagicalRecordImportClassNameKey];
                NSEntityDescription *destination = [relationshipInfo destinationEntity];
                if (destinationName) {
                    NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:[self managedObjectContext]];
                    if ([customDestination isKindOfEntity:destination])
                        destination = customDestination;
                }
                return [self _createInstanceForEntity:destination withDictionary:objectData];
            } else {
                NSManagedObject *relatedObject = [self _findObjectForRelationship:relationshipInfo withData:objectData];
                [relatedObject importValuesFromDictionary:objectData];
                return relatedObject;
            }
        }];
    }
}

- (void)updateValuesFromDictionary:(NSDictionary *)objectData
{
    @autoreleasepool {
        [self _setAttributes:self.entity.attributesByName forDictionary:objectData];
        [self _setRelationships:self.entity.relationshipsByName forDictionary:objectData withBlock:^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData){
            NSManagedObject *relatedObject = [self _findObjectForRelationship:relationshipInfo withData:objectData];

            if (!relatedObject) {
                NSString *destinationName = [objectData objectForKey:kMagicalRecordImportClassNameKey];
                NSEntityDescription *destination = [relationshipInfo destinationEntity];
                if (destinationName) {
                    NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:[self managedObjectContext]];
                    if ([customDestination isKindOfEntity:destination])
                        destination = customDestination;
                }
                return [self _createInstanceForEntity:destination withDictionary:objectData];
            }
             
            [relatedObject importValuesFromDictionary:objectData];
            
            return relatedObject;
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
    NSAssert3(primaryAttribute != nil, @"Unable to determine primary attribute for %@. Specify either an attribute named %@ or the primary key in userInfo named '%@'", entity.name, primaryKeyNameFromString(entity.name), kMagicalRecordImportPrimaryAttributeKey);
    
    NSString *lookupKey = [primaryAttribute.userInfo valueForKey:kMagicalRecordImportMapKey] ?: primaryAttribute.name;
    NSString *lookupKeyPath = [self valueForKeyPath:lookupKey];
    id value = [objectData valueForKeyPath:lookupKeyPath];
    
    NSManagedObject *manageObject = [self findFirstByAttribute:lookupKey withValue:value inContext:context];
    if (!manageObject)  {
        manageObject = [self createInContext:context];
    }
    [manageObject updateValuesFromDictionary:objectData];
    
    return manageObject;
}

+ (NSArray *)importFromArray:(NSArray *)listOfObjectData
{
    return [self importFromArray:listOfObjectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *)importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *objectIDs = [NSMutableArray array];
    [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) {    
         [listOfObjectData enumerateObjectsWithOptions:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
          {
              NSDictionary *objectData = (NSDictionary *)obj;
              
              NSManagedObject *dataObject = [self importFromDictionary:objectData inContext:localContext];
              
              if ([context obtainPermanentIDsForObjects:[NSArray arrayWithObject:dataObject] error:nil])
              {
                  [objectIDs addObject:[dataObject objectID]];
              }
          }];
     }];
    
    return [self findAllWithPredicate:[NSPredicate predicateWithFormat:@"self IN %@", objectIDs] inContext:context];
}

+ (void)updateFromArray:(NSArray *)listOfObjectData {
    [MRCoreDataAction saveDataInBackgroundWithBlock:^(NSManagedObjectContext *localContext) {
        [self updateFromArray:listOfObjectData inContext:localContext];
    }];
}

+ (void)updateFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)localContext {
    [listOfObjectData enumerateObjectsUsingBlock:^(NSDictionary *objectData, NSUInteger idx, BOOL *stop) {
        [self updateFromDictionary:objectData inContext:localContext];
    }];
}

@end
