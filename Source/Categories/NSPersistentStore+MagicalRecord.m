//
//  NSPersistentStore+MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStore+MagicalRecord.h"

NSString *const kMagicalRecordDefaultStoreFileName = @"CoreDataStore.sqlite";

static NSPersistentStore *_defaultPersistentStore = nil;

@interface NSPersistentStore ()

+ (NSString *) _directory: (NSSearchPathDirectory) type;

@end

@implementation NSPersistentStore (MagicalRecord)

+ (NSPersistentStore *) defaultPersistentStore
{
	return _defaultPersistentStore;
}

+ (BOOL) _hasDefaultPersistentStore
{
	return !!_defaultPersistentStore;
}
+ (void) _setDefaultPersistentStore: (NSPersistentStore *) store
{
	_defaultPersistentStore = store;
}

+ (NSString *) _applicationDocumentsDirectory 
{
	return [self _directory: NSDocumentDirectory];
}
+ (NSString *) _applicationStorageDirectory
{
    NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
    return [[self _directory: NSApplicationSupportDirectory] stringByAppendingPathComponent: applicationName];
}
+ (NSString *) _directory: (NSSearchPathDirectory) type
{	
	return [NSSearchPathForDirectoriesInDomains(type, NSUserDomainMask, YES) lastObject];
}

+ (NSURL *) URLForStoreName: (NSString *) storeFileName
{
	NSFileManager *fm = [NSFileManager new];
	NSString *documentsDir = [self _applicationDocumentsDirectory];
	NSString *appSupportDir = [self _applicationStorageDirectory];
	
	NSArray *paths = [NSArray arrayWithObjects: documentsDir, appSupportDir, nil];
	
	// Set default URL (just in case)
	__block NSURL *storeURL = [NSURL fileURLWithPath: [appSupportDir stringByAppendingPathComponent: storeFileName]];
	
	[paths enumerateObjectsUsingBlock: ^(NSString *directory, NSUInteger idx, BOOL *stop) {
		NSString *filePath = [directory stringByAppendingPathComponent: storeFileName];
		if ([fm fileExistsAtPath: filePath])
		{
			// Replace `storeURL`, then return
			storeURL = [NSURL fileURLWithPath: filePath];
			*stop = YES;
		}
	}];
	
	// Guaranteed to be non-nil
	return storeURL;
}

+ (NSURL *) defaultLocalStoreURL
{
	return [self URLForStoreName: kMagicalRecordDefaultStoreFileName];
}

@end
