//
//  NSPersistentStoreCoordinator+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSPersistentStoreCoordinator (AZCoreRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator;

#pragma mark - Store Coordinator Factory Methods

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType options: (NSDictionary *) options;

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType;
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType options: (NSDictionary *) options;

#pragma mark - In-Memory Store

- (NSPersistentStore *) addInMemoryStore;

@end
