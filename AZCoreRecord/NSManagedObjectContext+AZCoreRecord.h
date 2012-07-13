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

- (BOOL) save;
- (BOOL) saveWithErrorHandler: (void (^)(NSError *)) errorCallback;

- (id) existingObjectWithURI: (id) URI;
- (id) existingObjectWithID: (NSManagedObjectID *) objectID;

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext;
+ (NSManagedObjectContext *) contextForCurrentThread;

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext;

#pragma mark - Ubiquity Support

- (void) startObservingUbiquitousChanges;
- (void) stopObservingUbiquitousChanges;

#pragma mark - Reset Context

+ (void) resetDefaultContext;
+ (void) resetContextForCurrentThread;

#pragma mark - Data saving

- (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *context)) block;

- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block;
- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block completion: (void (^)(void)) callback;

@end
