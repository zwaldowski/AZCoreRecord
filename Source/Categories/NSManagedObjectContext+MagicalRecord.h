//
//  NSManagedObjectContext+MagicalRecord.h
//  MagicalRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObjectContext (MagicalRecord)

+ (NSManagedObjectContext *)defaultContext;
+ (NSManagedObjectContext *)contextForCurrentThread;

+ (void)resetDefaultContext;
+ (void)resetContextForCurrentThread;
+ (void)setDefaultContextConcurrencyType:(NSManagedObjectContextConcurrencyType)concurrencyType;

- (void) observeContext:(NSManagedObjectContext *)otherContext;
- (void) stopObservingContext:(NSManagedObjectContext *)otherContext;
- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext;

- (BOOL) save;
- (BOOL) saveWithErrorHandler:(void(^)(NSError *))errorCallback;

- (BOOL) saveOnMainThread;
- (BOOL) saveOnBackgroundThread;

+ (NSManagedObjectContext *) context;
+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThread;
+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

@property (nonatomic) BOOL notifiesMainContextOnSave;

@end