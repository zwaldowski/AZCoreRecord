//
//  NSManagedObjectModel+MagicalRecord.m
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSManagedObjectModel+MagicalRecord.h"

@implementation NSManagedObjectModel (MagicalRecord)

+ (NSManagedObjectModel *)defaultManagedObjectModel
{
    static dispatch_once_t onceToken;
    static NSManagedObjectModel *defaultManagedObjectModel_ = nil;
    dispatch_once(&onceToken, ^{
        defaultManagedObjectModel_ = [self mergedModelFromBundles:nil];
    });
	return defaultManagedObjectModel_;
}

+ (NSManagedObjectModel *)managedObjectModel {
	return [self mergedModelFromBundles:nil];
}

+ (NSManagedObjectModel *)mergedObjectModelFromMainBundle;
{
	return [self managedObjectModel];
}

+ (NSManagedObjectModel *)newManagedObjectModel {
	return [self managedObjectModel];
}

+ (NSManagedObjectModel *)newModelNamed:(NSString *) modelName inBundleNamed:(NSString *) bundleName
{
	NSString *path = [[NSBundle mainBundle] pathForResource:[modelName stringByDeletingPathExtension] 
													 ofType:[modelName pathExtension] 
												inDirectory:bundleName];
	NSURL *modelUrl = [NSURL fileURLWithPath:path];
	
	NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelUrl];
	
	return mom;
}

+ (NSManagedObjectModel *)newManagedObjectModelNamed:(NSString *)modelFileName
{
	NSString *path = [[NSBundle mainBundle] pathForResource:[modelFileName stringByDeletingPathExtension] ofType:[modelFileName pathExtension]];
	NSURL *momURL = [NSURL fileURLWithPath:path];
	
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:momURL];
	return model;
}

+ (NSManagedObjectModel *)managedObjectModelNamed:(NSString *)modelFileName
{
	return [self newManagedObjectModelNamed:modelFileName];
}

@end
