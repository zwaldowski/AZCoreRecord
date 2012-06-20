//
//  AZCoreRecordTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordTests.h"
#import "AZCoreRecordManager+Private.h"
#import "AZCoreRecord.h"

@implementation AZCoreRecordTests

- (void) setUp
{
	[AZCoreRecordManager setStackModelName:@"TestModel.momd"];
}

- (void) tearDown {
	[AZCoreRecordManager azcr_cleanUp];
}

- (void) assertDefaultStack
{
	NSLog(@"%@", [NSManagedObjectContext defaultContext]);
	NSLog(@"%@", [NSManagedObjectModel defaultModel]);
	NSLog(@"%@", [NSPersistentStoreCoordinator defaultStoreCoordinator]);
	NSLog(@"%@", [NSPersistentStore defaultPersistentStore]);
	
	assertThat([NSManagedObjectContext defaultContext], is(notNilValue()));
	assertThat([NSManagedObjectModel defaultModel], is(notNilValue()));
	assertThat([NSPersistentStoreCoordinator defaultStoreCoordinator], is(notNilValue()));
	assertThat([NSPersistentStore defaultPersistentStore], is(notNilValue()));	
}

- (void) testCreateDefaultCoreDataStack
{
	NSURL *testStoreURL = [NSPersistentStore defaultLocalStoreURL];
	[[NSFileManager defaultManager] removeItemAtPath:[testStoreURL path] error:nil];
	
	[self assertDefaultStack];

	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([[defaultStore URL] lastPathComponent] , endsWith(@".sqlite"));
	assertThat([defaultStore type], is(equalTo(NSSQLiteStoreType)));
}

- (void) testCreateInMemoryCoreDataStack
{
	[AZCoreRecordManager setStackShouldUseInMemoryStore:YES];
	
	[self assertDefaultStack];
	
	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([defaultStore type], is(equalTo(NSInMemoryStoreType)));
}

- (void) testCreateSqliteStackWithCustomName
{
	NSString *testStoreName = @"MyTestDataStore.sqlite";
	[AZCoreRecordManager setStackStoreName:testStoreName];
	
	[self assertDefaultStack];
	
	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([defaultStore type], is(equalTo(NSSQLiteStoreType)));
	assertThat([[defaultStore URL] absoluteString], endsWith(testStoreName));
	
	[[NSFileManager defaultManager] removeItemAtURL:[defaultStore URL] error:NULL];
}

- (void) testCanSetAUserSpecifiedErrorHandler
{
	[AZCoreRecordManager setErrorDelegate: self];
	
	assertThat([AZCoreRecordManager errorDelegate], is(equalTo(self)));
}

- (void)handleError:(NSError *)error
{
	assertThat(error, is(notNilValue()));
	assertThat([error domain], is(equalTo(@"AZCoreRecordUnitTests")));
	assertThatInteger([error code], is(equalToInteger(1000)));
	errorHandlerWasCalled_ = YES;
}

- (void) testCanSetAUserSpecifiedErrorHandlerBlock
{
	[AZCoreRecordManager setErrorHandler: ^(NSError *error){
		// this block intentionally left empty
	}];
	
	assertThat([AZCoreRecordManager errorHandler], is(notNilValue()));
}

- (void) testUserSpecifiedErrorHandlerIsTriggeredOnError
{
	errorHandlerWasCalled_ = NO;
	[AZCoreRecordManager setErrorDelegate: self];
	[AZCoreRecordManager setErrorHandler:NULL];
	
	NSError *testError = [NSError errorWithDomain:@"AZCoreRecordUnitTests" code:1000 userInfo:nil];
	[AZCoreRecordManager handleError:testError];
	
	assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
}

- (void) testUserSpecifiedErrorHandlerBlockIsTriggeredOnError
{
	errorHandlerWasCalled_ = NO;
	[AZCoreRecordManager setErrorHandler: ^(NSError *error) {
		[self handleError:error];
	}];
	[AZCoreRecordManager setErrorDelegate: nil];
	
	NSError *testError = [NSError errorWithDomain:@"AZCoreRecordUnitTests" code:1000 userInfo:nil];
	[AZCoreRecordManager handleError:testError];
	
	assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
}

- (void) testLogsErrorsToLogger
{
	NSError *testError = [NSError errorWithDomain:@"Cocoa" code:1000 userInfo:nil];
	id mockErrorHandler = [OCMockObject mockForProtocol:@protocol(AZCoreRecordErrorHandler)];
	[[mockErrorHandler expect] handleError:testError];
	
	[AZCoreRecordManager setErrorDelegate: mockErrorHandler];
	[AZCoreRecordManager setErrorHandler:NULL];
	[AZCoreRecordManager handleError:testError];
	
	[mockErrorHandler verify];
}

@end
