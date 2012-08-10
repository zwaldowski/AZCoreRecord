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
#import "FixtureHelpers.h"
#import "SingleEntityWithNoRelationships.h"

@implementation AZCoreRecordTests {
    AZCoreRecordManager *_localManager;
}

- (void)setUp {
    _localManager = [[AZCoreRecordManager alloc] initWithStackName: @"TestStore.storefile"];
    _localManager.stackModelName = @"TestModel.momd";
}

- (void)tearDown {
    NSURL *URLToRemove = [_localManager.fallbackStoreURL URLByDeletingLastPathComponent];
    _localManager = nil;
	[[NSFileManager defaultManager] removeItemAtPath:[URLToRemove path] error:nil];
}

- (void) testCreateDefaultCoreDataStack
{   
    assertThat(_localManager.persistentStoreCoordinator, is(notNilValue()));
	assertThat(_localManager.managedObjectContext, is(notNilValue()));
    
    NSUInteger storeIndex = [_localManager.persistentStoreCoordinator.persistentStores indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
        return [store.URL.lastPathComponent hasSuffix:@"sqlite"] && [store.type isEqualToString: NSSQLiteStoreType];
    }];
    
    assertThatUnsignedInteger(storeIndex, isNot(equalToInteger(NSNotFound)));
}

- (void) testCreateInMemoryCoreDataStack
{
    _localManager.stackShouldUseInMemoryStore = YES;
    assertThat(_localManager.persistentStoreCoordinator, is(notNilValue()));
	assertThat(_localManager.managedObjectContext, is(notNilValue()));
    
    NSUInteger storeIndex = [_localManager.persistentStoreCoordinator.persistentStores indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
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
	
    dispatch_async(dispatch_get_main_queue(), ^{
        assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
    });
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        assertThatBool(errorHandlerWasCalled_, is(equalToBool(YES)));
    });
}

- (void) testDeduplication
{
	NSArray *data = [FixtureHelpers dataFromJSONFixtureNamed: @"Deduplication"];
	[SingleEntityWithNoRelationships importFromArray: data inContext: _localManager.managedObjectContext];
	[_localManager.managedObjectContext save];
	
	// Part 1
	[_localManager registerDeduplicationHandler: ^NSArray *(NSArray *conflictingManagedObjects, NSArray *identityAttributes) {
		return [conflictingManagedObjects lastObject];
	} forEntityName: @"SingleEntityWithNoRelationships"	includeSubentities: NO];
	
	[_localManager performSelector: @selector(azcr_didRecieveDeduplicationNotification:) withObject: nil];
	
	// Part 2
	__block BOOL handlerWasCalled = NO;
	[_localManager registerDeduplicationHandler: ^NSArray *(NSArray *conflictingManagedObjects, NSArray *identityAttributes) {
		handlerWasCalled = YES;
		return nil;
	} forEntityName: @"SingleEntityWithNoRelationships"	includeSubentities: NO];
	
	[_localManager performSelector: @selector(azcr_didRecieveDeduplicationNotification:) withObject: nil];
	
	assertThatBool(handlerWasCalled, is(equalToBool(NO)));
}

@end
