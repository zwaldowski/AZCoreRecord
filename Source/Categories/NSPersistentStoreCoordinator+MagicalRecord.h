//
//  NSPersistentStoreCoordinator+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSPersistentStoreCoordinator (MagicalRecord)

+ (NSPersistentStoreCoordinator *)defaultStoreCoordinator;

+ (NSPersistentStoreCoordinator *)coordinatorWithInMemoryStore;

+ (NSPersistentStoreCoordinator *)newPersistentStoreCoordinator;

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName;
+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName;
+ (NSPersistentStoreCoordinator *)coordinatorWithPersitentStore:(NSPersistentStore *)persistentStore;

- (NSPersistentStore *)addInMemoryStore;

@end