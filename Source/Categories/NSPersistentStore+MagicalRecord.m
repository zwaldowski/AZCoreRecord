//
//  NSPersistentStore+MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStore+MagicalRecord.h"

NSString *const kMagicalRecordDefaultStoreFileName = @"CoreDataStore.sqlite";

static NSPersistentStore *defaultPersistentStore_ = nil;

@implementation NSPersistentStore (MagicalRecord)

+ (NSPersistentStore *)defaultPersistentStore
{
	return defaultPersistentStore_;
}

+ (BOOL) _hasDefaultPersistentStore
{
	return !!defaultPersistentStore_;
}
+ (void)_setDefaultPersistentStore:(NSPersistentStore *) store
{
	defaultPersistentStore_ = store;
}

+ (NSString *)_directory:(NSSearchPathDirectory) type
{	
	return [NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES) lastObject];
}

+ (NSString *)_applicationDocumentsDirectory 
{
	return [self _directory:NSDocumentDirectory];
}

+ (NSString *)_applicationStorageDirectory
{
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
    return [[self _directory:NSApplicationSupportDirectory] stringByAppendingPathComponent:applicationName];
}

+ (NSURL *)URLForStoreName:(NSString *)storeFileName
{
	NSArray *paths = [NSArray arrayWithObjects:[self _applicationDocumentsDirectory], [self _applicationStorageDirectory], nil];
	NSFileManager *fm = [NSFileManager new];

	for (NSString *path in paths) 
	{
		NSString *filepath = [path stringByAppendingPathComponent:storeFileName];
		if ([fm fileExistsAtPath:filepath])
		{
			return [NSURL fileURLWithPath:filepath];
		}
	}

    //set default url
    return [NSURL fileURLWithPath:[[self _applicationStorageDirectory] stringByAppendingPathComponent:storeFileName]];
}

+ (NSURL *)defaultLocalStoreURL {
	return [self URLForStoreName:kMagicalRecordDefaultStoreFileName];
}

@end
