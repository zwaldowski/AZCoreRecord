//
//  NSPersistentStoreCoordinator+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSPersistentStoreCoordinator (MagicalRecord)

+ (NSPersistentStoreCoordinator *)defaultStoreCoordinator;
+ (void)setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

+ (NSPersistentStoreCoordinator *)coordinatorWithInMemoryStore;

+ (NSPersistentStoreCoordinator *)newPersistentStoreCoordinator;

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options;
+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL;
+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL withOptions:(NSDictionary *)options;
+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;
+ (NSPersistentStoreCoordinator *)coordinatorWithPersitentStore:(NSPersistentStore *)persistentStore;

- (NSPersistentStore *)addInMemoryStore;

@end