//
//  NSPersistentStoreCoordinatorHelperTests.m
//  Magical Record
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2011 Magical Panda Software LLC. All rights reserved.
//

#import "NSPersistentStoreCoordinatorHelperTests.h"
#import "MagicalRecord+Private.h"

@implementation NSPersistentStoreCoordinatorHelperTests

- (void) setUp
{
	[MagicalRecord _cleanUp];
	NSURL *testStoreURL = [NSPersistentStore URLForStoreName:@"TestStore.sqlite"];
	[[NSFileManager defaultManager] removeItemAtPath:[testStoreURL path] error:nil];
}

- (void) testCreateCoodinatorWithSqlitePersistentStore
{
	NSPersistentStoreCoordinator *testCoordinator = [NSPersistentStoreCoordinator coordinatorWithStoreNamed: @"TestStore.sqlite" ofType: NSSQLiteStoreType];
	
	assertThatUnsignedInteger([[testCoordinator persistentStores] count], is(equalToUnsignedInteger(1)));

	NSPersistentStore *store = [[testCoordinator persistentStores] objectAtIndex:0];
	assertThat([store type], is(equalTo(NSSQLiteStoreType)));
}

- (void) testCreateCoordinatorWithInMemoryStore
{
	NSPersistentStoreCoordinator *testCoordinator = [NSPersistentStoreCoordinator coordinatorWithInMemoryStore];

	assertThatUnsignedInteger([[testCoordinator persistentStores] count], is(equalToUnsignedInteger(1)));
	
	NSPersistentStore *store = [[testCoordinator persistentStores] objectAtIndex:0];
	assertThat([store type], is(equalTo(NSInMemoryStoreType)));
}

- (void) testCanAddAnInMemoryStoreToAnExistingCoordinator
{
	NSPersistentStoreCoordinator *testCoordinator = [NSPersistentStoreCoordinator coordinatorWithStoreNamed: @"TestStore.sqlite" ofType: NSSQLiteStoreType];
	
	assertThatUnsignedInteger([[testCoordinator persistentStores] count], is(equalToUnsignedInteger(1)));
	
	NSPersistentStore *firstStore = [[testCoordinator persistentStores] objectAtIndex:0];
	assertThat([firstStore type], is(equalTo(NSSQLiteStoreType)));
	
	[testCoordinator addInMemoryStore];
	
	assertThatUnsignedInteger([[testCoordinator persistentStores] count], is(equalToUnsignedInteger(2)));
	
	NSPersistentStore *secondStore = [[testCoordinator persistentStores] objectAtIndex:1];
	assertThat([secondStore type], is(equalTo(NSInMemoryStoreType)));
}

@end
