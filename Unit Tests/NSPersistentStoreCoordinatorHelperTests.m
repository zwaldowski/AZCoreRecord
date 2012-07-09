//
//  NSPersistentStoreCoordinatorHelperTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSPersistentStoreCoordinatorHelperTests.h"
#import "AZCoreRecordManager.h"

@implementation NSPersistentStoreCoordinatorHelperTests {
    AZCoreRecordManager *_localManager;
}

- (void)setUp {
    _localManager = [[AZCoreRecordManager alloc] initWithStackName: @"TestStore.storefile"];
}

- (void)tearDown {
    NSURL *URLToRemove = [_localManager.fallbackStoreURL URLByDeletingLastPathComponent];
    _localManager = nil;
	[[NSFileManager defaultManager] removeItemAtPath:[URLToRemove path] error:nil];
}

- (void) testDefaultCoodinatorWithSqlitePersistentStore
{
	NSPersistentStoreCoordinator *testCoordinator = [_localManager persistentStoreCoordinator];
	
	assertThatUnsignedInteger(testCoordinator.persistentStores.count, is(equalToUnsignedInteger(1)));

	NSPersistentStore *store = [[testCoordinator persistentStores] objectAtIndex:0];
	assertThat([store type], is(equalTo(NSSQLiteStoreType)));
}

- (void) testCanAddAnInMemoryStoreToAnExistingCoordinator
{
	NSPersistentStoreCoordinator *testCoordinator = [_localManager persistentStoreCoordinator];
	
	assertThatUnsignedInteger([[testCoordinator persistentStores] count], is(equalToUnsignedInteger(1)));
	
	NSPersistentStore *firstStore = [[testCoordinator persistentStores] objectAtIndex:0];
	assertThat([firstStore type], is(equalTo(NSSQLiteStoreType)));
	
	[testCoordinator addInMemoryStore];
	
	assertThatUnsignedInteger([[testCoordinator persistentStores] count], is(equalToUnsignedInteger(2)));
	
	NSPersistentStore *secondStore = [[testCoordinator persistentStores] objectAtIndex:1];
	assertThat([secondStore type], is(equalTo(NSInMemoryStoreType)));
}

@end
