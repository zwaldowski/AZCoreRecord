//
//  MagicalRecordHelperTests.m
//  MagicalRecord
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalRecordHelperTests.h"
#import "MagicalRecord+Private.h"

@implementation MagicalRecordHelperTests

- (void) setUp
{
	[NSManagedObjectModel _setDefaultManagedObjectModel:[NSManagedObjectModel newManagedObjectModelNamed:@"TestModel.momd"]];
}

- (void) tearDown
{
	[MagicalRecord _cleanUp];
}

- (void) assertDefaultStack
{
	assertThat([NSManagedObjectContext defaultContext], is(notNilValue()));
	assertThat([NSManagedObjectModel defaultManagedObjectModel], is(notNilValue()));
	assertThat([NSPersistentStoreCoordinator defaultStoreCoordinator], is(notNilValue()));
	assertThat([NSPersistentStore defaultPersistentStore], is(notNilValue()));	
}

- (void) testCreateDefaultCoreDataStack
{
	NSURL *testStoreURL = [NSPersistentStore URLForStoreName:kMagicalRecordDefaultStoreFileName];
	[[NSFileManager defaultManager] removeItemAtPath:[testStoreURL path] error:nil];
	
	[self assertDefaultStack];
	
	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([[defaultStore URL] absoluteString], endsWith(kMagicalRecordDefaultStoreFileName));
	assertThat([defaultStore type], is(equalTo(NSSQLiteStoreType)));
}

- (void) testCreateInMemoryCoreDataStack
{
	[MagicalRecord setupCoreDataStackWithInMemoryStore];
	
	[self assertDefaultStack];
	
	NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
	assertThat([defaultStore type], is(equalTo(NSInMemoryStoreType)));
}

- (void) testCreateSqliteStackWithCustomName
{
	@autoreleasepool
	{
		NSString *testStoreName = @"MyTestDataStore.sqlite";
		
		NSURL *testStoreURL = [NSPersistentStore URLForStoreName:testStoreName];
		[[NSFileManager defaultManager] removeItemAtPath:[testStoreURL path] error:nil];
		
		[MagicalRecord setupCoreDataStackWithStoreNamed:testStoreName];
		
		[self assertDefaultStack];
		
		NSPersistentStore *defaultStore = [NSPersistentStore defaultPersistentStore];
		assertThat([defaultStore type], is(equalTo(NSSQLiteStoreType)));
		assertThat([[defaultStore URL] absoluteString], endsWith(testStoreName));
	}
}

- (void) testCanSetAUserSpecifiedErrorHandler
{
	[MagicalRecord setErrorHandlerTarget:self];
	
	assertThat([MagicalRecord errorHandlerTarget], is(equalTo(self)));
}

- (void)handleError:(NSError *)error
{
	assertThat(error, is(notNilValue()));
	assertThat([error domain], is(equalTo(@"MRTests")));
	assertThatInteger([error code], is(equalToInteger(1000)));
	errorHandlerWasCalled_ = YES;
}

- (void) testCanSetAUserSpecifiedErrorHandlerBlock
{
	MRErrorBlock handler = ^(NSError *error){ };
	[MagicalRecord setErrorHandler: handler];
	
	assertThat([MagicalRecord errorHandler], is(notNilValue()));
}

- (void) testUserSpecifiedErrorHandlerIsTriggeredOnError
{
	errorHandlerWasCalled_ = NO;
	[MagicalRecord setErrorHandlerTarget:self];
	[MagicalRecord setErrorHandler:NULL];
	
	NSError *testError = [NSError errorWithDomain:@"MRTests" code:1000 userInfo:nil];
	[MagicalRecord handleError:testError];
	
	assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
}

- (void) testUserSpecifiedErrorHandlerBlockIsTriggeredOnError
{
	errorHandlerWasCalled_ = NO;
	[MagicalRecord setErrorHandler: ^(NSError *error) {
		[self handleError:error];
	}];
	[MagicalRecord setErrorHandlerTarget:nil];
	
	NSError *testError = [NSError errorWithDomain:@"MRTests" code:1000 userInfo:nil];
	[MagicalRecord handleError:testError];
	
	assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
}

- (void) testLogsErrorsToLogger
{
	NSError *testError = [NSError errorWithDomain:@"Cocoa" code:1000 userInfo:nil];
	id mockErrorHandler = [OCMockObject mockForProtocol:@protocol(MRErrorHandler)];
	[[mockErrorHandler expect] handleError:testError];
	
	[MagicalRecord setErrorHandlerTarget:mockErrorHandler];
	[MagicalRecord setErrorHandler:NULL];
	[MagicalRecord handleError:testError];
	
	[mockErrorHandler verify];
}

@end
