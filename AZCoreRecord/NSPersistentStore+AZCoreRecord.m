//
//  NSPersistentStore+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSPersistentStore+AZCoreRecord.h"
#import "AZCoreRecordManager.h"

@implementation NSPersistentStore (AZCoreRecord)

+ (NSPersistentStore *) defaultPersistentStore
{
	return [[AZCoreRecordManager sharedManager] persistentStore];
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
	NSString *storeName = [[AZCoreRecordManager sharedManager] stackStoreName];
	if (!storeName.length)
		storeName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
	return [self URLForStoreName: storeName];
}

@end
