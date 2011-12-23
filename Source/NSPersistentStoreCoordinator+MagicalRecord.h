//
//  NSPersistentStoreCoordinator+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MagicalRecord.h"

extern NSString *const MagicalRecordCompletedCloudSetupNotification;

@interface NSPersistentStoreCoordinator (MagicalRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator;

#pragma mark - Store Coordinator Factory Methods

+ (NSPersistentStoreCoordinator *) coordinator;
+ (NSPersistentStoreCoordinator *) coordinatorWithPersistentStore: (NSPersistentStore *) persistentStore;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType options: (NSDictionary *) options;
+ (NSPersistentStoreCoordinator *) coordinatorWithContainer: (NSString *) containerID contentNameKey: (NSString *) key storeAtURL: (NSURL *) storeURL cloudStorePathComponent: (NSString *) pathComponent;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType options: (NSDictionary *) options;
+ (NSPersistentStoreCoordinator *) coordinatorWithContainer: (NSString *) containerID contentNameKey: (NSString *) key storeNamed: (NSString *) storeName cloudStorePathComponent: (NSString *) pathComponent;

#pragma mark - Migration and Ubiquity Support

+ (NSDictionary *) automaticLightweightMigrationOptions;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled ubiquityEnabled:(BOOL)ubiquity;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled ubiquityEnabled:(BOOL)ubiquity;

- (void)addUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key storeNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)pathComponent;
- (void)addUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key storeAtURL:(NSURL *)localStoreURL cloudStorePathComponent:(NSString *)pathComponent;

#pragma mark - In-Memory Store

+ (NSPersistentStoreCoordinator *) coordinatorWithInMemoryStore;

- (NSPersistentStore *) addInMemoryStore;

#pragma mark Deprecated

+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreNamed: (NSString *) storeName DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreAtURL: (NSURL *) storeURL DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreNamed: (NSString *) storeName DEPRECATED_ATTRIBUTE;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled DEPRECATED_ATTRIBUTE;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled DEPRECATED_ATTRIBUTE;

+ (NSPersistentStoreCoordinator *) newPersistentStoreCoordinator DEPRECATED_ATTRIBUTE;

@end
