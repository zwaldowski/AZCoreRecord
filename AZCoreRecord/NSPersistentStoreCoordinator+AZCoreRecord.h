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

#pragma mark - Store adding

- (NSPersistentStore *) addInMemoryStoreWithConfiguration: (NSString *)configuration options: (NSDictionary *)options;
- (NSPersistentStore *) addInMemoryStore;

- (NSPersistentStore *) addStoreAtURL: (NSURL *)URL configuration: (NSString *)configuration options: (NSDictionary *)options;

#pragma mark - Seeding stores

- (void) seedWithPersistentStoreAtURL: (NSURL *) oldStoreURL usingBlock:(void(^)(NSManagedObjectContext *oldMOC, NSManagedObjectContext *newMOC))block;

@end
