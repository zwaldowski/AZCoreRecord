//
//  NSPersistentStoreCoordinator+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSPersistentStoreCoordinator (MagicalRecord)

+ (NSPersistentStoreCoordinator *)defaultStoreCoordinator;

+ (NSPersistentStoreCoordinator *)coordinator;
+ (NSPersistentStoreCoordinator *)coordinatorWithInMemoryStore;
+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
+ (NSPersistentStoreCoordinator *)coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore;

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL;
+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL withOptions:(NSDictionary *)options;
+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;

- (NSPersistentStore *)addInMemoryStore;

+ (NSPersistentStoreCoordinator *)newPersistentStoreCoordinator DEPRECATED_ATTRIBUTE;


@end