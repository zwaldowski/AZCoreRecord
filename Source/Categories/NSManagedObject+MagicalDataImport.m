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

NSString * const kMagicalRecordImportMapKey = @"mappedKey";
NSString * const kMagicalRecordImportClassNameKey = @"className";

NSString * const kMagicalRecordImportPrimaryAttributeKey = @"primaryAttribute";
NSString * const kMagicalRecordImportRelationshipPrimaryKey = @"primaryKey";
NSString * const kMagicalRecordImportRelationshipTypeKey = @"type";

@implementation NSManagedObject (MagicalRecord_DataImport)

- (id) MR_valueForAttribute:(NSAttributeDescription *)attributeInfo fromObjectData:(NSDictionary *)objectData forKeyPath:(NSString *)keyPath
{
    id value = [objectData valueForKeyPath:keyPath];
    
    NSAttributeType attributeType = [attributeInfo attributeType];
    NSString *desiredAttributeType = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportClassNameKey];
    if (desiredAttributeType) 
    {
        if ([desiredAttributeType hasSuffix:@"Color"])
        {
            value = colorFromString(value);
        }
    }
    else 
    {
        if (attributeType == NSDateAttributeType)
        {
            if (![value isKindOfClass:[NSDate class]]) 
            {
                NSString *dateFormat = [[attributeInfo userInfo] valueForKey:kMagicalRecordImportCustomDateFormat];
                value = dateFromString([value description], dateFormat ?: kMagicalRecordImportDefaultDateFormat);
            }
            value = adjustDateForDST(value);
        }
    }
    
    return value == [NSNull null] ? nil : value;
}

- (void) MR_setAttributes:(NSDictionary *)attributes forKeysWithDictionary:(NSDictionary *)objectData
{
    [attributes enumerateKeysAndObjectsUsingBlock:^(NSString *attributeName, NSAttributeDescription *attributeInfo, BOOL *stop) {
        NSString *lookupKey = [attributeInfo.userInfo valueForKey:kMagicalRecordImportMapKey] ?: attributeInfo.name;
        NSString *lookupKeyPath = [objectData valueForKeyPath:lookupKey];
        
        if (!lookupKeyPath)
            return;
        
        id value = [self MR_valueForAttribute:attributeInfo fromObjectData:objectData forKeyPath:lookupKeyPath];
        [self setValue:value forKey:attributeName];
    }];
}

- (NSManagedObject *) MR_createInstanceForEntity:(NSEntityDescription *)entityDescription withDictionary:(id)objectData
{
    NSManagedObject *relatedObject = [NSEntityDescription insertNewObjectForEntityForName:[entityDescription name] 
                                                                   inManagedObjectContext:[self managedObjectContext]];
    
    [relatedObject MR_importValuesForKeysWithDictionary:objectData];
    
    return relatedObject;
}

- (NSManagedObject *) MR_findObjectForRelationship:(NSRelationshipDescription *)relationshipInfo withData:(id)singleRelatedObjectData
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

- (void) MR_addObject:(NSManagedObject *)relatedObject forRelationship:(NSRelationshipDescription *)relationshipInfo
{
    NSAssert2(relatedObject != nil, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), [relationshipInfo name]);    
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
}

- (void) MR_setRelationships:(NSDictionary *)relationships forKeysWithDictionary:(NSDictionary *)relationshipData withBlock:(void(^)(NSRelationshipDescription *,id))setRelationshipBlock
{
    for (NSString *relationshipName in relationships) 
    {
        NSRelationshipDescription *relationshipInfo = [relationships valueForKey:relationshipName];
        NSString *lookupKey = [[relationshipInfo userInfo] valueForKey:kMagicalRecordImportMapKey] ?: relationshipName;
        
        id relatedObjectData = [relationshipData valueForKey:lookupKey];
        
        if (relatedObjectData == nil || [relatedObjectData isEqual:[NSNull null]]) 
        {
            continue;
        }

        if ([relationshipInfo isToMany])
        {
            for (id singleRelatedObjectData in relatedObjectData) 
            {
                setRelationshipBlock(relationshipInfo, singleRelatedObjectData);
            }
        }
        else
        {
            setRelationshipBlock(relationshipInfo, relatedObjectData);
        }
    }
}

- (void) MR_importValuesForKeysWithDictionary:(NSDictionary *)objectData
{
    @autoreleasepool {
        NSDictionary *attributes = [[self entity] attributesByName];
        [self MR_setAttributes:attributes forKeysWithDictionary:objectData];
        
        NSDictionary *relationships = [[self entity] relationshipsByName];
        [self MR_setRelationships:relationships
            forKeysWithDictionary:objectData 
                        withBlock:^(NSRelationshipDescription *relationshipInfo, id objectData)
         {
             NSManagedObject *relatedObject = nil;
             if ([objectData isKindOfClass:[NSURL class]]) {
                 objectData = [self.managedObjectContext.persistentStoreCoordinator managedObjectIDForURIRepresentation:objectData];
                 if (!objectData)
                     return;
             }
             
             if ([objectData isKindOfClass:[NSManagedObjectID class]]) {
                 objectData = [self.managedObjectContext existingObjectWithID:objectData error:nil];
                 if (!objectData)
                     return;
             }
             
             if ([objectData isKindOfClass:[NSManagedObject class]]) {
                 NSEntityDescription *objDescription = [objectData entity];
                 NSEntityDescription *relDescription = [relationshipInfo destinationEntity];
                 if ([objDescription isKindOfEntity:relDescription]) {
                     [self MR_addObject:objectData forRelationship:relationshipInfo];
                 }
                 return;
             }
                      
             if ([objectData isKindOfClass:[NSDictionary class]]) 
             {
                 NSString *destinationName = [objectData objectForKey:kMagicalRecordImportClassNameKey];
                 NSEntityDescription *destination = [relationshipInfo destinationEntity];
                 if (destinationName) {
                     NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:[self managedObjectContext]];
                     if ([customDestination isKindOfEntity:destination])
                         destination = customDestination;
                 }
                 relatedObject = [self MR_createInstanceForEntity:destination withDictionary:objectData];
                 [relatedObject MR_importValuesForKeysWithDictionary:objectData];
             }
             else
             {
                 relatedObject = [self MR_findObjectForRelationship:relationshipInfo withData:objectData];
                 [relatedObject MR_importValuesForKeysWithDictionary:objectData];
             }
             
             [self MR_addObject:relatedObject forRelationship:relationshipInfo];            
         }];
    }
}

- (void) MR_updateValuesForKeysWithDictionary:(NSDictionary *)objectData
{
    @autoreleasepool {
        NSDictionary *attributes = [[self entity] attributesByName];
        [self MR_setAttributes:attributes forKeysWithDictionary:objectData];
        
        NSDictionary *relationships = [[self entity] relationshipsByName];
        [self MR_setRelationships:relationships
            forKeysWithDictionary:objectData 
                        withBlock:^(NSRelationshipDescription *relationshipInfo, id objectData)
         {
             NSManagedObject *relatedObject = [self MR_findObjectForRelationship:relationshipInfo
                                                                        withData:objectData];
             if (relatedObject == nil)
             {
                 NSString *destinationName = [objectData objectForKey:kMagicalRecordImportClassNameKey];
                 NSEntityDescription *destination = [relationshipInfo destinationEntity];
                 if (destinationName) {
                     NSEntityDescription *customDestination = [NSEntityDescription entityForName:destinationName inManagedObjectContext:[self managedObjectContext]];
                     if ([customDestination isKindOfEntity:destination])
                         destination = customDestination;
                 }
                 relatedObject = [self MR_createInstanceForEntity:destination withDictionary:objectData];
             }
             else
             {
                 [relatedObject MR_importValuesForKeysWithDictionary:objectData];
             }
             
             [self MR_addObject:relatedObject forRelationship:relationshipInfo];            
         }];
    }
}

+ (id) MR_importFromDictionary:(NSDictionary *)objectData inContext:(NSManagedObjectContext *)context;
{
    NSManagedObject *managedObject = [self createInContext:context];
    [managedObject MR_importValuesForKeysWithDictionary:objectData];
    return managedObject;
}

+ (id) MR_importFromDictionary:(NSDictionary *)objectData
{
    return [self MR_importFromDictionary:objectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (id) MR_updateFromDictionary:(NSDictionary *)objectData inContext:(NSManagedObjectContext *)context
{
    NSEntityDescription *entity = [self entityDescription];
    NSString *attributeKey = [entity.userInfo valueForKey:kMagicalRecordImportPrimaryAttributeKey] ?: primaryKeyNameFromString(entity.name);
    NSAttributeDescription *primaryAttribute = [entity.attributesByName valueForKey:attributeKey];
    NSAssert3(primaryAttribute != nil, @"Unable to determine primary attribute for %@. Specify either an attribute named %@ or the primary key in userInfo named '%@'", entity.name, primaryKeyNameFromString(entity.name), kMagicalRecordImportPrimaryAttributeKey);
    
    id value = nil;    
    NSString *lookupKey = [primaryAttribute.userInfo valueForKey:kMagicalRecordImportMapKey] ?: primaryAttribute.name;
    NSString *lookupKeyPath = [self valueForKeyPath:lookupKey];
    if (lookupKeyPath)
        value = [objectData valueForKeyPath:lookupKeyPath];
    
    NSManagedObject *manageObject = [self findFirstByAttribute:[primaryAttribute name] withValue:value inContext:context];
    if (!manageObject) 
    {
        manageObject = [self createInContext:context];
        [manageObject MR_importValuesForKeysWithDictionary:objectData];
    }
    else
    {
        [manageObject MR_updateValuesForKeysWithDictionary:objectData];
    }
    return manageObject;
}

+ (id) MR_updateFromDictionary:(NSDictionary *)objectData
{
    return [self MR_updateFromDictionary:objectData inContext:[NSManagedObjectContext defaultContext]];    
}

+ (NSArray *) MR_importFromArray:(NSArray *)listOfObjectData
{
    return [self MR_importFromArray:listOfObjectData inContext:[NSManagedObjectContext defaultContext]];
}

+ (NSArray *) MR_importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context
{
    NSMutableArray *objectIDs = [NSMutableArray array];
    [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) 
     {    
         [listOfObjectData enumerateObjectsWithOptions:0 usingBlock:^(id obj, NSUInteger idx, BOOL *stop) 
          {
              NSDictionary *objectData = (NSDictionary *)obj;
              
              NSManagedObject *dataObject = [self MR_importFromDictionary:objectData inContext:localContext];
              
              if ([context obtainPermanentIDsForObjects:[NSArray arrayWithObject:dataObject] error:nil])
              {
                  [objectIDs addObject:[dataObject objectID]];
              }
          }];
     }];
    
    return [self findAllWithPredicate:[NSPredicate predicateWithFormat:@"self IN %@", objectIDs] inContext:context];
}

+ (void)MR_updateFromArray:(NSArray *)listOfObjectData {
    [MRCoreDataAction saveDataWithBlock:^(NSManagedObjectContext *localContext) {
        [self MR_updateFromArray:listOfObjectData inContext:localContext];
    }];
}

+ (void)MR_updateFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)localContext {
    [listOfObjectData enumerateObjectsUsingBlock:^(NSDictionary *objectData, NSUInteger idx, BOOL *stop) {
        [self MR_updateFromDictionary:objectData inContext:localContext];
    }];
}

@end
