//
//  NSManagedObjectContext+MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

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

@property (nonatomic, strong) NSManagedObjectContext *parentContext;

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext;
+ (NSManagedObjectContext *) contextForCurrentThread;

+ (void) setDefaultConcurrencyType: (NSManagedObjectContextConcurrencyType) concurrencyType NS_AVAILABLE(10_7, 5_0);

#pragma mark - Context Factory Methods

+ (NSManagedObjectContext *) context;
+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator;

#pragma mark - Reset Context

+ (void) resetDefaultContext;
+ (void) resetContextForCurrentThread;

@end
