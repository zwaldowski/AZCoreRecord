//
//  NSManagedObjectContext+MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

extern NSString *const MagicalRecordDidMergeUbiquitousChangesNotification;

@interface NSManagedObjectContext (MagicalRecord)

#pragma mark - Instance Methods

- (BOOL) save;
- (BOOL) saveOnMainThread;
- (BOOL) saveOnBackgroundThread;

- (BOOL) saveWithErrorHandler: (MRErrorBlock) errorCallback;
- (BOOL) saveOnMainThreadWithErrorHandler: (MRErrorBlock) errorCallback;
- (BOOL) saveOnBackgroundThreadWithErrorHandler: (MRErrorBlock) errorCallback;

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext;
- (NSManagedObjectContext *) newChildContextWithConcurrencyType: (NSManagedObjectContextConcurrencyType) concurrencyType NS_AVAILABLE(10_7, 5_0);

@property (nonatomic, strong) NSManagedObjectContext *parentContext NS_AVAILABLE(10_6, 4_0);

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext;
+ (NSManagedObjectContext *) contextForCurrentThread;

#pragma mark - Context Factory Methods

+ (NSManagedObjectContext *) context;
+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator;

#pragma mark - Ubiquity Support

- (void)startObservingUbiquitousChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;
- (void)stopObservingUbiquitousChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator;

#pragma mark - Reset Context

+ (void) resetDefaultContext;
+ (void) resetContextForCurrentThread;

@end
