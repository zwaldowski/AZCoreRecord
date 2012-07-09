//
//  AZCoreRecordTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordTests.h"
#import "AZCoreRecordManager.h"

@interface AZCoreRecordManager ()
- (void)azcr_cleanUp;
@end

@implementation AZCoreRecordTests

- (void) setUp
{
	[AZCoreRecordManager setDefaultStackModelName:@"TestModel.momd"];
}

- (void) tearDown {
	[[AZCoreRecordManager sharedManager] azcr_cleanUp];
}

- (void) assertDefaultStack
{
	NSLog(@"%@", [NSManagedObjectContext defaultContext]);
	NSLog(@"%@", [NSPersistentStoreCoordinator defaultStoreCoordinator]);
		
	assertThat([NSManagedObjectContext defaultContext], is(notNilValue()));
	assertThat([NSPersistentStoreCoordinator defaultStoreCoordinator], is(notNilValue()));
	assertThat([[NSPersistentStoreCoordinator defaultStoreCoordinator] persistentStores], isNot(empty()));
}

- (void) testCreateDefaultCoreDataStack
{
    NSURL *testStoreURL = [[[AZCoreRecordManager sharedManager] fallbackStoreURL] URLByDeletingLastPathComponent];
	[[NSFileManager defaultManager] removeItemAtPath:[testStoreURL path] error:nil];
	
	[self assertDefaultStack];
	
	NSUInteger storeIndex = [[[NSPersistentStoreCoordinator defaultStoreCoordinator] persistentStores] indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
		return [store.URL.lastPathComponent hasSuffix:@"sqlite"] && [store.type isEqualToString: NSSQLiteStoreType];
	}];

	assertThatUnsignedInteger(storeIndex, isNot(equalToInteger(NSNotFound)));
}

- (void) testCreateInMemoryCoreDataStack
{
	[AZCoreRecordManager setDefaultStackShouldUseInMemoryStore:YES];
	
	[self assertDefaultStack];
	
	NSUInteger storeIndex = [[[NSPersistentStoreCoordinator defaultStoreCoordinator] persistentStores] indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
		return [store.type isEqualToString: NSInMemoryStoreType];
	}];
	
	assertThatUnsignedInteger(storeIndex, isNot(equalToInteger(NSNotFound)));
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
