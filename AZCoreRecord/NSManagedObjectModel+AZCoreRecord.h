//
//  NSManagedObjectModel+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectModel (AZCoreRecord)

#pragma mark - Model Factory Methods

+ (NSManagedObjectModel *) model;
+ (NSManagedObjectModel *) modelAtURL: (NSURL *) modelURL;
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName;
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle;
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName;

#pragma mark - URL Methods

+ (NSURL *)URLForModelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle;
+ (NSURL *)URLForModelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName;

@end