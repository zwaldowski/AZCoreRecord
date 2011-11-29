//
//  NSManagedObject+MagicalDataImport.m
//  Magical Record
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import <objc/message.h>

static id colorFromString(NSString *serializedColor)
{
	BOOL isRGB = [serializedColor hasPrefix: @"rgb"];
	BOOL isHSB = [serializedColor hasPrefix: @"hsb"];
	BOOL isHSV = [serializedColor hasPrefix: @"hsv"];
	double divisor = (isRGB || isHSB || isHSV) ? 255.0 : 1.0;
	
	NSScanner *colorScanner = [NSScanner scannerWithString: serializedColor];
	
	NSCharacterSet *delimiters = [[NSCharacterSet characterSetWithCharactersInString: @"0.123456789"] invertedSet];
	[colorScanner scanUpToCharactersFromSet: delimiters intoString: NULL];
	
	CGFLOAT_TYPE *componentValues = calloc(4, sizeof(CGFLOAT_TYPE));
	componentValues[3] = 1.0;
	
	CGFLOAT_TYPE *componentValue = componentValues;
	while (![colorScanner isAtEnd])
	{
		[colorScanner scanCharactersFromSet: delimiters intoString: NULL];
#if CGFLOAT_IS_DOUBLE
		[colorScanner scanDouble: componentValue];
#else
		[colorScanner scanFloat: componentValue];
#endif
		componentValue++;
	}
	
	// Normalize values
	for (int i = 0; i <= 2; ++i) componentValues[i] = MIN(componentValues[i] / divisor, divisor);
	
	// Convert HSB to HSV
	if (isHSV) componentValues[3] = divisor - componentValues[3];
	
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	Class cls = [UIColor class];
	SEL selector = @selector(colorWithRed:green:blue:alpha:);
	if (isHSB || isHSV) selector = @selector(colorWithHue:saturation:brightness:alpha:);
#else
	Class cls = [NSColor class];
	SEL selector = @selector(colorWithDeviceRed:green:blue:alpha:);
	if (isHSB || isHSV) selector = @selector(colorWithDeviceHue:saturation:brightness:alpha:);
#endif
	
	id color = ((id (*)(id, SEL, CGFLOAT_TYPE, CGFLOAT_TYPE, CGFLOAT_TYPE, CGFLOAT_TYPE)) objc_msgSend)(cls, selector, componentValues[0], componentValues[1], componentValues[2], componentValues[3]);
	free(componentValues);
	return color;
}

static inline NSDate *dateAdjustForDST(NSDate *date)
{
	NSTimeInterval dstOffset = [[NSTimeZone localTimeZone] daylightSavingTimeOffsetForDate: date];
	NSDate *actualDate = [date dateByAddingTimeInterval: dstOffset];
	return actualDate;
}
static inline NSDate *dateFromString(NSString *value, NSString *format)
{
	static dispatch_once_t onceToken;
	static NSDateFormatter *helperFormatter;
	dispatch_once(&onceToken, ^{
		helperFormatter = [NSDateFormatter new];
		helperFormatter.timeZone = [NSTimeZone localTimeZone];
		helperFormatter.locale = [NSLocale currentLocale];
	});
	
	helperFormatter.dateFormat = (format ?: kMagicalRecordImportDefaultDateFormat);
	
	return [helperFormatter dateFromString: value];
}

static inline NSString *attributeNameFromString(NSString *value)
{
	NSString *firstCharacter = [[value substringToIndex: 1] capitalizedString];
	value = [value stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstCharacter];
	
	return value;
}
static inline NSString *primaryKeyNameFromString(NSString *value)
{
	NSString *firstCharacter = [[value substringToIndex: 1] lowercaseString];
	value = [value stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString: firstCharacter];
	value = [value stringByAppendingString: @"ID"];
	
	return value;
}

NSString *const kMagicalRecordImportCustomDateFormat = @"dateFormat";
NSString *const kMagicalRecordImportDefaultDateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";

NSString *const kMagicalRecordImportMapKey = @"mappedKey";
NSString *const kMagicalRecordImportClassNameKey = @"className";

NSString *const kMagicalRecordImportPrimaryAttributeKey = @"primaryAttribute";
NSString *const kMagicalRecordImportRelationshipPrimaryKey = @"primaryKey";

@implementation NSManagedObject (MagicalDataImport)

#pragma mark - Private Helper Methods

- (NSManagedObject *) _createInstanceForEntity: (NSEntityDescription *) entityDescription withDictionary: (id) objectData
{
	NSManagedObject *relatedObject = [NSEntityDescription insertNewObjectForEntityForName: [entityDescription name] inManagedObjectContext: [self managedObjectContext]];
	[relatedObject importValuesFromDictionary: objectData];
	
	return relatedObject;
}
- (NSManagedObject *) _findObjectForRelationship: (NSRelationshipDescription *) relationshipInfo withData: (id) singleRelatedObjectData
{
	if ([singleRelatedObjectData isKindOfClass: [NSManagedObject class]])
	{
		NSEntityDescription *objectDataEntity = [(NSManagedObject *) singleRelatedObjectData entity];
		NSEntityDescription *destinationEntity = relationshipInfo.destinationEntity;
		
		if ([objectDataEntity isEqual: destinationEntity] || [objectDataEntity isKindOfEntity: destinationEntity])
			return singleRelatedObjectData;
		
		return nil;
	}
	else if ([singleRelatedObjectData isKindOfClass: [NSURL class]])
	{
		NSPersistentStoreCoordinator *psc = self.managedObjectContext.persistentStoreCoordinator;
		NSManagedObjectID *objectID = [psc managedObjectIDForURIRepresentation: singleRelatedObjectData];
		
		return [self.managedObjectContext existingObjectWithID: objectID error: nil];
	}
	else if ([singleRelatedObjectData isKindOfClass: [NSManagedObjectID class]])
	{
		return [self.managedObjectContext existingObjectWithID: singleRelatedObjectData error: nil];
	}
	
	id relatedValue = nil;
	
	NSEntityDescription *destination = relationshipInfo.destinationEntity;
	
	if ([singleRelatedObjectData isKindOfClass: [NSNumber class]] || [singleRelatedObjectData isKindOfClass: [NSString class]])
	{
		relatedValue = singleRelatedObjectData;
	}
	else if ([singleRelatedObjectData isKindOfClass: [NSDictionary class]])
	{
		NSString *destinationKey = [relationshipInfo.userInfo objectForKey: kMagicalRecordImportClassNameKey];
		NSString *destinationName = [singleRelatedObjectData objectForKey: destinationKey];
		if (destinationName)
		{
			NSEntityDescription *customDestination = [NSEntityDescription entityForName: destinationName inManagedObjectContext: self.managedObjectContext];
			if ([customDestination isKindOfEntity: destination]) destination = customDestination;
		}
		
		NSEntityDescription *destinationEntity = relationshipInfo.destinationEntity;
		NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey: kMagicalRecordImportRelationshipPrimaryKey];
		if (!primaryKeyName) primaryKeyName = primaryKeyNameFromString(relationshipInfo.destinationEntity.name);
		
		NSAttributeDescription *primaryKeyAttribute = [destinationEntity.attributesByName valueForKey: primaryKeyName];
		NSString *lookupKey = [primaryKeyAttribute.userInfo valueForKey: kMagicalRecordImportMapKey];
		if (!lookupKey) lookupKey = primaryKeyAttribute.name;

		relatedValue = [singleRelatedObjectData valueForKeyPath: lookupKey];
	}
	
	if (!relatedValue)
		return nil;

	Class managedObjectClass = NSClassFromString([destination managedObjectClassName]);
	NSString *primaryKeyName = [relationshipInfo.userInfo valueForKey: kMagicalRecordImportRelationshipPrimaryKey];
	if (!primaryKeyName) primaryKeyName = primaryKeyNameFromString(relationshipInfo.destinationEntity.name);
	
	id object = [managedObjectClass findFirstWhere: primaryKeyName isEqualTo: relatedValue inContext: self.managedObjectContext];
	if ([singleRelatedObjectData isKindOfClass: [NSDictionary class]])
		[object updateValuesFromDictionary: singleRelatedObjectData];
	
	return object;
}

- (void) _addObject: (NSManagedObject *) relatedObject forRelationship: (NSRelationshipDescription *) relationshipInfo
{
	NSAssert2(relatedObject, @"Cannot add nil to %@ for attribute %@", NSStringFromClass([self class]), relationshipInfo.name);
	NSAssert2([relatedObject.entity isKindOfEntity: relationshipInfo.destinationEntity], @"Related object entity %@ must be same as destination entity %@", relatedObject.entity.name, relationshipInfo.destinationEntity.name);
	
	// Add related object to set
	NSString *selectorFormat = (relationshipInfo.isToMany) ? @"add%@Object:" : @"set%@:";
	NSString *selectorString = [NSString stringWithFormat: selectorFormat, attributeNameFromString(relationshipInfo.name)];
	
	SEL selector = NSSelectorFromString(selectorString);
	
	@try
	{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[self performSelector: selector withObject: relatedObject];
#pragma clank diagnostic pop
	}
	@catch (NSException *exception)
	{
		MRLog(@"Adding object for relationship failed: %@", relationshipInfo);
		MRLog(@"relatedObject.entity = %@", relatedObject.entity);
		MRLog(@"relationshipInfo.destinationEntity = %@", relationshipInfo.destinationEntity);
		MRLog(@"Perform Selector Exception: %@", exception);
	}
}
- (void) _setAttributes: (NSDictionary *) attributes forDictionary: (NSDictionary *) objectData
{
	[attributes enumerateKeysAndObjectsUsingBlock: ^(NSString *attributeName, NSAttributeDescription *attributeInfo, BOOL *stop) {
		NSString *key = [attributeInfo.userInfo valueForKey: kMagicalRecordImportMapKey] ?: attributeInfo.name;
		if (!key.length)
			return;

		id value = [objectData valueForKeyPath: key];

		for (int i = 1; i < 10 && value == nil; ++i)
		{
			NSString *attributeName = [NSString stringWithFormat: @"%@.%d", kMagicalRecordImportMapKey, i];
			key = [attributeInfo.userInfo valueForKey: attributeName];
			value = [objectData valueForKeyPath: key];
		}

		NSAttributeType attributeType = attributeInfo.attributeType;
		NSString *desiredAttributeType = [attributeInfo.userInfo valueForKey: kMagicalRecordImportClassNameKey];

		if (desiredAttributeType && [desiredAttributeType hasSuffix: @"Color"])
		{
			value = colorFromString(value);
		}
		else if (attributeType == NSDateAttributeType)
		{
			if (![value isKindOfClass: [NSDate class]])
			{
				NSString *dateFormat = [attributeInfo.userInfo valueForKey: kMagicalRecordImportCustomDateFormat];
				value = dateFromString([value description], dateFormat);
			}

			value = dateAdjustForDST(value);
		}

		if (!value)	// If it just wasn't set, leave the default
			return;

		if (value == [NSNull null])	// if it was *explicitly* set to nil, set
			value = nil;

		[self setValue: value forKey: attributeName];
	}];
}
- (void) _setRelationships: (NSDictionary *) relationships forDictionary: (NSDictionary *) relationshipData withBlock: (NSManagedObject *(^)(NSRelationshipDescription *, id)) setRelationship
{
	[relationships enumerateKeysAndObjectsUsingBlock: ^(NSString *relationshipName, NSRelationshipDescription *relationshipInfo, BOOL *stop) {
		NSString *lookupKey = [relationshipInfo.userInfo valueForKey: kMagicalRecordImportMapKey] ?: relationshipName;
		
		id relatedObjectData = [relationshipData valueForKeyPath: lookupKey];
		if (!relatedObjectData || [relatedObjectData isEqual: [NSNull null]]) 
			return;
		
		if (relationshipInfo.isToMany)
		{
			for (id singleRelatedObjectData in relatedObjectData)
			{
				NSManagedObject *obj = setRelationship(relationshipInfo, singleRelatedObjectData);
				[self _addObject: obj forRelationship: relationshipInfo];
			}
		} else {
			NSManagedObject *obj = setRelationship(relationshipInfo, relatedObjectData);
			[self _addObject: obj forRelationship: relationshipInfo];
		}
	}];
}

#pragma mark - Import from Dictionary

+ (id) importFromDictionary: (id) objectData
{
	return [self importFromDictionary: objectData inContext: [NSManagedObjectContext defaultContext]];
}
+ (id) importFromDictionary: (id) objectData inContext: (NSManagedObjectContext *) context
{
	NSManagedObject *managedObject = [self createInContext: context];
	[managedObject importValuesFromDictionary: objectData];
	return managedObject;
}

- (void) importValuesFromDictionary: (id) objectData
{
	@autoreleasepool
	{
		NSDictionary *attributes = self.entity.attributesByName;
		if (attributes.count)
		{
			[self _setAttributes: attributes forDictionary: objectData];
		}
		
		NSDictionary *relationships = self.entity.relationshipsByName;
		if (relationships.count)
		{
			__unsafe_unretained NSManagedObject *weakSelf = self;
			[self _setRelationships: relationships forDictionary: objectData withBlock: ^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData) {
				if ([objectData isKindOfClass: [NSDictionary class]])
				{
					NSEntityDescription *destination = relationshipInfo.destinationEntity;
					
					NSString *destinationKey = [relationshipInfo.userInfo objectForKey: kMagicalRecordImportClassNameKey];
					NSString *destinationName = [objectData objectForKey: destinationKey];
					
					if (destinationName)
					{
						NSManagedObjectContext *context = weakSelf.managedObjectContext;
						NSEntityDescription *customDestination = [NSEntityDescription entityForName: destinationName inManagedObjectContext: context];
						if ([customDestination isKindOfEntity: destination]) destination = customDestination;
					}
					
					return [weakSelf _createInstanceForEntity: destination withDictionary: objectData];
				}
				
				return [weakSelf _findObjectForRelationship: relationshipInfo withData: objectData];
			}];
		}
	}
}

#pragma mark - Update from Dictionary

+ (id) updateFromDictionary: (id) objectData
{
	return [self updateFromDictionary: objectData inContext: [NSManagedObjectContext defaultContext]];
}
+ (id) updateFromDictionary: (id) objectData inContext: (NSManagedObjectContext *) context
{
	NSEntityDescription *entity = self.entityDescription;
	NSString *attributeKey = [entity.userInfo valueForKey: kMagicalRecordImportPrimaryAttributeKey] ?: primaryKeyNameFromString(entity.name);
	
	NSAttributeDescription *primaryAttribute = [entity.attributesByName valueForKey: attributeKey];
	NSAssert3(primaryAttribute, @"Unable to determine primary attribute for %@. Specify either an attribute named %@ or the primary key in userInfo named '%@'", entity.name, attributeKey, kMagicalRecordImportPrimaryAttributeKey);
	
	NSString *lookupKey = [primaryAttribute.userInfo valueForKey: kMagicalRecordImportMapKey] ?: primaryAttribute.name;
	id value = [objectData valueForKeyPath: lookupKey];
	
	NSManagedObject *managedObject = [self findFirstWhere: lookupKey isEqualTo: value inContext: context];
	if (!managedObject) managedObject = [self createInContext: context];
	
	[managedObject updateValuesFromDictionary: objectData];
	
	return managedObject;
}

- (void) updateValuesFromDictionary: (id) objectData
{
	@autoreleasepool
	{
		NSDictionary *attributes = self.entity.attributesByName;
		if (attributes.count)
		{
			[self _setAttributes: attributes forDictionary: objectData];
		}
		
		NSDictionary *relationships = self.entity.relationshipsByName;
		if (relationships.count)
		{
			__unsafe_unretained NSManagedObject *weakSelf = self;
			[self _setRelationships: relationships forDictionary: objectData withBlock: ^NSManagedObject *(NSRelationshipDescription *relationshipInfo, id objectData) {
				NSManagedObject *relatedObject = [weakSelf _findObjectForRelationship: relationshipInfo withData: objectData];
				
				if (relatedObject)
				{
					if ([objectData isKindOfClass: [NSDictionary class]])
						[relatedObject importValuesFromDictionary: objectData];
					
					return relatedObject;
				}
				
				NSEntityDescription *destination = relationshipInfo.destinationEntity;
				
				if ([objectData isKindOfClass: [NSDictionary class]])
				{
					NSString *destinationKey = [relationshipInfo.userInfo objectForKey: kMagicalRecordImportClassNameKey];
					NSString *destinationName = [objectData objectForKey: destinationKey];
					
					if (destinationName)
					{
						NSManagedObjectContext *context = weakSelf.managedObjectContext;
						NSEntityDescription *customDestination = [NSEntityDescription entityForName: destinationName inManagedObjectContext: context];
						if ([customDestination isKindOfEntity: destination]) destination = customDestination;
					}
				}
				
				return [weakSelf _createInstanceForEntity: destination withDictionary: objectData];
			}];
		}
	}
}

#pragma mark - Import from Array

+ (NSArray *) importFromArray: (NSArray *) listOfObjectData
{
	return [self importFromArray: listOfObjectData inContext: [NSManagedObjectContext defaultContext]];
}
+ (NSArray *) importFromArray: (NSArray *) listOfObjectData inContext: (NSManagedObjectContext *) context
{
	__block NSArray *objectIDs = nil;
	
	[MagicalRecord saveDataWithBlock: ^(NSManagedObjectContext *localContext) {
		NSMutableArray *objects = [NSMutableArray array];
		
		[listOfObjectData enumerateObjectsUsingBlock: ^(NSDictionary *objectData, NSUInteger idx, BOOL *stop) {
			[objects addObject: [self importFromDictionary: objectData inContext: localContext]];
		}];
		
		if ([context obtainPermanentIDsForObjects: objects error: NULL])
			objectIDs = [objects valueForKey: @"objectID"];
	}];
	
	return [self findAllWithPredicate: [NSPredicate predicateWithFormat: @"self IN %@", objectIDs] inContext: context];
}

#pragma mark - Update from Array

+ (NSArray *) updateFromArray: (NSArray *) listOfObjectData
{
	return [self updateFromArray: listOfObjectData inContext: [NSManagedObjectContext defaultContext]];
}
+ (NSArray *) updateFromArray: (NSArray *) listOfObjectData inContext: (NSManagedObjectContext *) context
{
	__block NSArray *objectIDs = nil;
	
	[MagicalRecord saveDataWithBlock: ^(NSManagedObjectContext *localContext) {
		NSMutableArray *objects = [NSMutableArray array];
		
		[listOfObjectData enumerateObjectsUsingBlock: ^(id objectData, NSUInteger idx, BOOL *stop) {
			[objects addObject: [self updateFromDictionary: objectData inContext: localContext]];
		}];
		
		if ([context obtainPermanentIDsForObjects: objects error: NULL])
			objectIDs = [objects valueForKey: @"objectID"];
	}];
	
	return [self findAllWithPredicate: [NSPredicate predicateWithFormat: @"self IN %@", objectIDs] inContext: context];
}

@end
