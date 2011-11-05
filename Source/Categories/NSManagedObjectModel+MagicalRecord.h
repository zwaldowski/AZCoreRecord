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

+ (NSManagedObjectModel *)newManagedObjectModelNamed:(NSString *)modelFileName NS_RETURNS_RETAINED;
+ (NSManagedObjectModel *)managedObjectModelNamed:(NSString *)modelFileName;
+ (NSManagedObjectModel *)newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName NS_RETURNS_RETAINED;
+ (NSManagedObjectModel *)mergedObjectModelFromMainBundle;

@end