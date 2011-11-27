//
//  NSManagedObjectModel+MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObjectModel (MagicalRecord)

#pragma mark - Default Model

+ (NSManagedObjectModel *) defaultModel;

#pragma mark - Model Factory Methods

+ (NSManagedObjectModel *) model;
+ (NSManagedObjectModel *) modelAtURL: (NSURL *) modelURL;
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName;
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle;
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName;

#pragma mark - URL Methods

+ (NSURL *)URLForModelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle;
+ (NSURL *)URLForModelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName;

#pragma mark Deprecated

+ (NSManagedObjectModel *) newManagedObjectModel DEPRECATED_ATTRIBUTE;
+ (NSManagedObjectModel *) mergedObjectModelFromMainBundle DEPRECATED_ATTRIBUTE;
+ (NSManagedObjectModel *) managedObjectModelNamed: (NSString *) modelFileName DEPRECATED_ATTRIBUTE;

@end