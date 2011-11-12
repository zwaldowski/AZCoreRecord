//
//  NSManagedObjectModel+MagicalRecord.h
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObjectModel (MagicalRecord)

+ (NSManagedObjectModel *)defaultManagedObjectModel;
+ (void)setDefaultManagedObjectModel:(NSManagedObjectModel *)newDefaultModel;

+ (NSManagedObjectModel *)managedObjectModel;
+ (NSManagedObjectModel *)newManagedObjectModelNamed:(NSString *)modelFileName;
+ (NSManagedObjectModel *)newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName;

+ (NSManagedObjectModel *)newManagedObjectModel DEPRECATED_ATTRIBUTE;
+ (NSManagedObjectModel *)mergedObjectModelFromMainBundle DEPRECATED_ATTRIBUTE;
+ (NSManagedObjectModel *)managedObjectModelNamed:(NSString *)modelFileName DEPRECATED_ATTRIBUTE;

@end