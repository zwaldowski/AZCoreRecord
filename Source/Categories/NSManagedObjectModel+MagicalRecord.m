//
//  NSManagedObjectModel+MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MagicalRecord+Private.h"
#import "NSManagedObjectModel+MagicalRecord.h"

#define return_model(x) \
	do { \
		NSManagedObjectModel *_model = (x); \
		if (!_defaultManagedObjectModel && [MagicalRecord shouldAutoCreateDefaultModel]) \
			[self _setDefaultModel: _model]; \
		return _model; \
	} while (0)

static NSManagedObjectModel *_defaultManagedObjectModel = nil;

@implementation NSManagedObjectModel (MagicalRecord)

#pragma mark - Default Model

+ (NSManagedObjectModel *) defaultModel
{
	if (!_defaultManagedObjectModel && [MagicalRecord shouldAutoCreateDefaultModel])
	{
		_defaultManagedObjectModel = [self model];
	}
	
	return _defaultManagedObjectModel;
}

+ (BOOL) _hasDefaultModel
{
	return !!_defaultManagedObjectModel;
}
+ (void) _setDefaultModel: (NSManagedObjectModel *) newModel
{
	_defaultManagedObjectModel = newModel;
}

#pragma mark - Model Factory Methods

+ (NSManagedObjectModel *) model
{
	return_model([self mergedModelFromBundles: nil]);
}
+ (NSManagedObjectModel *) modelAtURL: (NSURL *) modelURL
{
	return_model([[self alloc] initWithContentsOfURL: modelURL]);
}
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName
{
	return_model([self modelNamed: modelName inBundle: [NSBundle mainBundle]]);
}
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundle: (NSBundle *) bundle
{
	NSString *resource = [modelName stringByDeletingPathExtension];
	NSString *pathExtension = [modelName pathExtension];
	
	NSURL *modelURL = [bundle URLForResource: resource withExtension: pathExtension];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"momd"];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"mom"];
	NSAssert2(modelURL, @"Could not find model named %@ in bundle %@", modelName, bundle);
	
	return_model([NSManagedObjectModel modelAtURL: modelURL]);
}
+ (NSManagedObjectModel *) modelNamed: (NSString *) modelName inBundleNamed: (NSString *) bundleName
{
	NSString *resource = [modelName stringByDeletingPathExtension];
	NSString *pathExtension = [modelName pathExtension];
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSURL *modelURL = [bundle URLForResource: resource withExtension: pathExtension subdirectory: bundleName];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"momd" subdirectory: bundleName];
	if (!modelURL) modelURL = [bundle URLForResource: resource withExtension: @"mom" subdirectory: bundleName];
	NSAssert2(modelURL, @"Could not find model named %@ in bundle named %@", modelName, bundleName);
	
	return_model([NSManagedObjectModel modelAtURL: modelURL]);
}

#pragma mark Deprecated

+ (NSManagedObjectModel *) mergedObjectModelFromMainBundle
{
	return [self model];
}
+ (NSManagedObjectModel *) newManagedObjectModel
{
	return [self model];
}
+ (NSManagedObjectModel *) managedObjectModelNamed: (NSString *) modelFileName
{
	return [self modelNamed: modelFileName];
}

@end
