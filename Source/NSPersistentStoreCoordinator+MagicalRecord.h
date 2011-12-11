//
//  NSPersistentStoreCoordinator+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSPersistentStoreCoordinator (MagicalRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator;

#pragma mark - Store Coordinator Factory Methods

+ (NSPersistentStoreCoordinator *) coordinator;
+ (NSPersistentStoreCoordinator *) coordinatorWithPersistentStore: (NSPersistentStore *) persistentStore;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType options: (NSDictionary *) options;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType options: (NSDictionary *) options;

#pragma mark - Automatic Lightweight Migration

+ (NSDictionary *) automaticLightweightMigrationOptions;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled;

#pragma mark - In-Memory Store

+ (NSPersistentStoreCoordinator *) coordinatorWithInMemoryStore;

- (NSPersistentStore *) addInMemoryStore;

#pragma mark Deprecated

+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreNamed: (NSString *) storeName DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreAtURL: (NSURL *) storeURL DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreNamed: (NSString *) storeName DEPRECATED_ATTRIBUTE;

+ (NSPersistentStoreCoordinator *) newPersistentStoreCoordinator DEPRECATED_ATTRIBUTE;

@end
