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
	static NSURL *documentsURL = nil;
	static NSURL *appSupportURL = nil;
	dispatch_once(&onceToken, ^{
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
		documentsURL = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
		appSupportURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent: applicationName isDirectory: YES];
	});
	
	NSURL *documentsFile = [documentsURL URLByAppendingPathComponent: storeFileName];
	NSURL *appSupportFile = [appSupportURL URLByAppendingPathComponent: storeFileName];
	
	// Guaranteed to be non-nil
	return [fm fileExistsAtPath: [documentsFile absoluteString]] ? documentsFile : appSupportFile;
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
	NSString *storeName = [MagicalRecord mr_stackStoreName];
	if (!storeName.length)
		storeName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
	return [self URLForStoreName: storeName];
}

@end
