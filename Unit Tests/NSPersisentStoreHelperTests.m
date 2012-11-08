//
//  NSPersisentStoreHelperTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSPersisentStoreHelperTests.h"
#import "AZCoreRecordManager.h"

@implementation NSPersisentStoreHelperTests

- (NSString *) applicationStorageDirectory
{
	NSString *appSupportDirectory = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
    NSString *applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(NSString *)kCFBundleNameKey];
	appSupportDirectory = [appSupportDirectory stringByAppendingPathComponent: applicationName];
	return appSupportDirectory;
}

- (void)testDefaultStoreIsTheApplicationSupportSlashApplicationFolder
{
	NSString *applicationLibraryDirectory = [self applicationStorageDirectory];
	NSString *defaultStoreName = @"Store.sqlite";
	
	NSURL *expectedStoreUrl = [NSURL fileURLWithPath:[applicationLibraryDirectory stringByAppendingPathComponent:defaultStoreName]];
	
	NSURL *defaultStoreUrl = [[AZCoreRecordManager sharedManager] storeURL];
	assertThat(defaultStoreUrl, is(equalTo(expectedStoreUrl)));
}

- (void) testCanFindAURLInTheLibraryForASpecifiedStoreName
{
	NSString *applicationLibraryDirectory = [self applicationStorageDirectory];
    NSString *customStackName = @"CustomStoreName.storefile";
	NSString *defaultStoreName = @"Store.sqlite";
    NSString *testStorePath = [NSString stringWithFormat: @"%@/%@/%@", applicationLibraryDirectory, customStackName, defaultStoreName];
	
	BOOL folderWasCreated = [[NSFileManager defaultManager] createDirectoryAtPath: [testStorePath stringByDeletingLastPathComponent] withIntermediateDirectories: YES attributes: nil error: NULL];
	BOOL fileWasCreated = [[NSFileManager defaultManager] createFileAtPath:testStorePath contents:[customStackName dataUsingEncoding:NSUTF8StringEncoding] attributes:nil];
	
	assertThatBool(folderWasCreated, is(equalToBool(YES)));
	assertThatBool(fileWasCreated, is(equalToBool(YES)));
	
	NSURL *expectedFoundStoreUrl = [NSURL fileURLWithPath:testStorePath];
	NSURL *foundStoreUrl = [[[AZCoreRecordManager alloc] initWithStackName: customStackName] storeURL];
	
	assertThat(foundStoreUrl, is(equalTo(expectedFoundStoreUrl)));
	
	[[NSFileManager defaultManager] removeItemAtPath:testStorePath error:nil];
}

@end
