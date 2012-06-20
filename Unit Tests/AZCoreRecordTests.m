//
//  AZCoreRecordTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordTests.h"
#import "AZCoreRecord+Private.h"

@implementation AZCoreRecordTests

- (void) setUp
{
	[AZCoreRecord setStackModelName:@"TestModel.momd"];
}

- (void) tearDown {
	[AZCoreRecord azcr_cleanUp];
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
	[AZCoreRecord setStackShouldUseInMemoryStore:YES];
	
	[self assertDefaultStack];
	
	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([defaultStore type], is(equalTo(NSInMemoryStoreType)));
}

- (void) testCreateSqliteStackWithCustomName
{
	NSString *testStoreName = @"MyTestDataStore.sqlite";
	[AZCoreRecord setStackStoreName:testStoreName];
	
	[self assertDefaultStack];
	
	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([defaultStore type], is(equalTo(NSSQLiteStoreType)));
	assertThat([[defaultStore URL] absoluteString], endsWith(testStoreName));
	
	[[NSFileManager defaultManager] removeItemAtURL:[defaultStore URL] error:NULL];
}

- (void) testCanSetAUserSpecifiedErrorHandler
{
	[AZCoreRecord setErrorHandlerTarget:self];
	
	assertThat([AZCoreRecord errorHandlerTarget], is(equalTo(self)));
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
	[AZCoreRecord setErrorHandler: ^(NSError *error){
		// this block intentionally left empty
	}];
	
	assertThat([AZCoreRecord errorHandler], is(notNilValue()));
}

- (void) testUserSpecifiedErrorHandlerIsTriggeredOnError
{
	errorHandlerWasCalled_ = NO;
	[AZCoreRecord setErrorHandlerTarget:self];
	[AZCoreRecord setErrorHandler:NULL];
	
	NSError *testError = [NSError errorWithDomain:@"AZCoreRecordUnitTests" code:1000 userInfo:nil];
	[AZCoreRecord handleError:testError];
	
	assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
}

- (void) testUserSpecifiedErrorHandlerBlockIsTriggeredOnError
{
	errorHandlerWasCalled_ = NO;
	[AZCoreRecord setErrorHandler: ^(NSError *error) {
		[self handleError:error];
	}];
	[AZCoreRecord setErrorHandlerTarget:nil];
	
	NSError *testError = [NSError errorWithDomain:@"AZCoreRecordUnitTests" code:1000 userInfo:nil];
	[AZCoreRecord handleError:testError];
	
	assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
}

- (void) testLogsErrorsToLogger
{
	NSError *testError = [NSError errorWithDomain:@"Cocoa" code:1000 userInfo:nil];
	id mockErrorHandler = [OCMockObject mockForProtocol:@protocol(AZCoreRecordErrorHandler)];
	[[mockErrorHandler expect] handleError:testError];
	
	[AZCoreRecord setErrorHandlerTarget:mockErrorHandler];
	[AZCoreRecord setErrorHandler:NULL];
	[AZCoreRecord handleError:testError];
	
	[mockErrorHandler verify];
}

@end
