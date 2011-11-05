//
//  NSManagedObjectModel+MagicalRecord.m
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSManagedObjectModel+MagicalRecord.h"

static __strong NSManagedObjectModel *defaultManagedObjectModel_ = nil;

@implementation NSManagedObjectModel (MagicalRecord)

+ (NSManagedObjectModel *) defaultManagedObjectModel
{
	if (defaultManagedObjectModel_ == nil && [MagicalRecordHelpers shouldAutoCreateManagedObjectModel])
	{
        [self setDefaultManagedObjectModel:[self mergedObjectModelFromMainBundle]];
	}
	return defaultManagedObjectModel_;
}

+ (void) setDefaultManagedObjectModel:(NSManagedObjectModel *)newDefaultModel
{
    defaultManagedObjectModel_ = newDefaultModel;
}

+ (NSManagedObjectModel *)mergedObjectModelFromMainBundle;
{
    return [self mergedModelFromBundles:nil];
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
