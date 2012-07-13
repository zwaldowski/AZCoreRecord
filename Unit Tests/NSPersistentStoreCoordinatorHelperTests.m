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
    NSPersistentStoreCoordinator *testCoordinator = _localManager.persistentStoreCoordinator;
    
    assertThat(testCoordinator.persistentStores, isNot(empty()));
        
    NSUInteger storeIndex = [_localManager.persistentStoreCoordinator.persistentStores indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
        return [store.type isEqualToString: NSSQLiteStoreType];
    }];
    
    assertThatUnsignedInteger(storeIndex, isNot(equalToInteger(NSNotFound)));
}

- (void) testCanAddAnInMemoryStoreToAnExistingCoordinator
{
    NSPersistentStoreCoordinator *testCoordinator = _localManager.persistentStoreCoordinator;
    
    assertThat(testCoordinator.persistentStores, isNot(empty()));
    [testCoordinator addInMemoryStore];
    
    assertThatUnsignedInteger(testCoordinator.persistentStores.count, is(greaterThanOrEqualTo([NSNumber numberWithUnsignedInteger: 2])));
    
    NSUInteger storeIndex = [_localManager.persistentStoreCoordinator.persistentStores indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
        return [store.type isEqualToString: NSInMemoryStoreType];
    }];
    
    assertThatUnsignedInteger(storeIndex, isNot(equalToInteger(NSNotFound)));
}

@end
