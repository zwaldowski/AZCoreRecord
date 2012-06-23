//
//  NSManagedObjectContext+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString *const AZCoreRecordDidMergeUbiquitousChangesNotification;

@interface NSManagedObjectContext (AZCoreRecord)

#pragma mark - Instance Methods

- (void) save;
- (void) saveWithErrorHandler: (void (^)(NSError *)) errorCallback;

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext;
+ (NSManagedObjectContext *) contextForCurrentThread;

#pragma mark - Context Factory Methods

+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator;

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext;

#pragma mark - Ubiquity Support

- (void) startObservingUbiquitousChangesInCoordinator: (NSPersistentStoreCoordinator *) coordinator;
- (void) stopObservingUbiquitousChangesInCoordinator: (NSPersistentStoreCoordinator *) coordinator;

#pragma mark - Reset Context

+ (void) resetDefaultContext;
+ (void) resetContextForCurrentThread;

#pragma mark - Data saving

- (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *context)) block;

- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block;
- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block completion: (void (^)(void)) callback;

@end
