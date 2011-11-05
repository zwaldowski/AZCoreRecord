//
//  NSManagedObject+JSONHelpers.h
//  Gathering
//
//  Created by Saul Mora on 6/28/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString *const kMagicalRecordImportMapKey;
extern NSString *const kMagicalRecordImportClassNameKey;

extern NSString * const kMagicalRecordImportPrimaryAttributeKey;
extern NSString * const kMagicalRecordImportRelationshipPrimaryKey;
extern NSString * const kMagicalRecordImportRelationshipTypeKey;

@interface NSManagedObject (NSManagedObject_DataImport)

- (void) MR_importValuesForKeysWithDictionary:(NSDictionary *)objectData;
- (void) MR_updateValuesForKeysWithDictionary:(NSDictionary *)objectData;

+ (id) MR_importFromDictionary:(NSDictionary *)data;
+ (id) MR_importFromDictionary:(NSDictionary *)data inContext:(NSManagedObjectContext *)context;

+ (NSArray *) MR_importFromArray:(NSArray *)listOfObjectData;
+ (NSArray *) MR_importFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)context;

+ (id)MR_updateFromDictionary:(NSDictionary *)objectData;
+ (id)MR_updateFromDictionary:(NSDictionary *)objectData inContext:(NSManagedObjectContext *)context;

+ (void)MR_updateFromArray:(NSArray *)listOfObjectData;
+ (void)MR_updateFromArray:(NSArray *)listOfObjectData inContext:(NSManagedObjectContext *)localContext;


@end


#ifdef MR_SHORTHAND
    #define importFromDictionary                    MR_importFromDictionary
    #define setValuesForKeysWithJSDONDictionary     MR_setValuesForKeysWithJSONDictionary
#endif