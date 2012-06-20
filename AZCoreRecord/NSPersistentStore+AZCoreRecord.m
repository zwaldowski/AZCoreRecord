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

+ (NSURL *) URLForStoreName: (NSString *) storeFileName
{
	if (!storeFileName.length)
		storeFileName = [[AZCoreRecordManager sharedManager] stackStoreName];
	
	if (!storeFileName.length)
		storeFileName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
	
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

@end
