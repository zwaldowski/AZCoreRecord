//
//  NSManagedObjectModel+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectModel+AZCoreRecord.h"
#import "AZCoreRecordManager+Private.h"

static NSManagedObjectModel *_defaultManagedObjectModel = nil;

@implementation NSManagedObjectModel (AZCoreRecord)

#pragma mark - Default Model

+ (NSManagedObjectModel *) defaultModel
{
	if (!_defaultManagedObjectModel)
	{
		NSURL *storeURL = [AZCoreRecord azcr_stackModelURL];
		NSString *storeName = [AZCoreRecord azcr_stackModelName];
		
		if (!storeURL && storeName)
			_defaultManagedObjectModel = [self modelNamed:storeName];
		else if (storeURL) 
			_defaultManagedObjectModel = [self modelAtURL:storeURL];
		else
			_defaultManagedObjectModel = [self model];
	}
	
	return _defaultManagedObjectModel;
}

+ (BOOL) azcr_hasDefaultModel
{
	return !!_defaultManagedObjectModel;
}
+ (void) azcr_setDefaultModel: (NSManagedObjectModel *) newModel
{
	_defaultManagedObjectModel = newModel;
}

#pragma mark - Model Factory Methods

+ (NSManagedObjectModel *) model
{
	return [self mergedModelFromBundles: nil];
}
+ (NSManagedObjectModel *) modelAtURL: (NSURL *) modelURL
{
	return [[self alloc] initWithContentsOfURL: modelURL];
}
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName
{
	return [self modelNamed: modelName inBundle: [NSBundle mainBundle]];
}
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle
{
	NSURL *URL = [self URLForModelNamed:modelName inBundle:bundle];
	return [NSManagedObjectModel modelAtURL:URL];
}
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName
{
	NSURL *URL = [self URLForModelNamed:modelName inBundleNamed:bundleName];
	return [NSManagedObjectModel modelAtURL:URL];
}

#pragma mark URL Methods

+ (NSURL *)URLForModelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle
{
	NSString *resource = [modelName stringByDeletingPathExtension];
	NSString *pathExtension = [modelName pathExtension];
	
	NSURL *modelURL = [bundle URLForResource: resource withExtension: pathExtension];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"momd"];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"mom"];
	NSAssert2(modelURL, @"Could not find model named %@ in bundle %@", modelName, bundle);
	
	return modelURL;
}
+ (NSURL *)URLForModelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName
{
	NSString *resource = [modelName stringByDeletingPathExtension];
	NSString *pathExtension = [modelName pathExtension];
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSURL *modelURL = [bundle URLForResource: resource withExtension: pathExtension subdirectory: bundleName];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"momd" subdirectory: bundleName];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"mom" subdirectory: bundleName];
	NSAssert2(modelURL, @"Could not find model named %@ in bundle named %@", modelName, bundleName);
	
	return modelURL;
}

@end
