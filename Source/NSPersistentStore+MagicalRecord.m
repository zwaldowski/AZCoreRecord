//
//  NSPersistentStore+MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStore+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSPersistentStore *_defaultPersistentStore = nil;

@implementation NSPersistentStore (MagicalRecord)

+ (NSPersistentStore *) defaultPersistentStore
{
	return _defaultPersistentStore;
}

+ (BOOL) mr_hasDefaultPersistentStore
{
	return !!_defaultPersistentStore;
}
+ (void) mr_setDefaultPersistentStore: (NSPersistentStore *) store
{
	_defaultPersistentStore = store;
}

+ (NSURL *) URLForStoreName: (NSString *) storeFileName
{
	if (!storeFileName)
		return nil;
	
	if (!storeFileName.pathExtension.length) 
		storeFileName = [storeFileName stringByAppendingPathExtension:@"sqlite"];
	
	NSFileManager *fm = [NSFileManager new];
	
	static dispatch_once_t onceToken;
	static NSString *documentsDir = nil;
	static NSString *appSupportDir = nil;
	dispatch_once(&onceToken, ^{
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
		documentsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
		appSupportDir = [[NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent: applicationName];
	});
	
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

+ (NSURL *) URLForUbiquitousContainer: (NSString *) bucketName
{
	if (![NSFileManager instancesRespondToSelector:@selector(URLForUbiquityContainerIdentifier:)])
		return nil;
		
	NSFileManager *fm = [NSFileManager new];
	NSURL *cloudURL = [fm URLForUbiquityContainerIdentifier:bucketName];
	return cloudURL;	
}

+ (NSURL *) defaultLocalStoreURL
{
	NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
	return [self URLForStoreName: applicationName];
}

@end
