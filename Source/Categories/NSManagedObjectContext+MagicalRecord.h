//
//  NSManagedObjectContext+MagicalRecord.h
//  MagicalRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObjectContext (MagicalRecord)

+ (NSManagedObjectContext *)defaultContext;
+ (void)setDefaultConcurrencyType:(NSManagedObjectContextConcurrencyType)type;
+ (void)resetDefaultContext;

+ (NSManagedObjectContext *)contextForCurrentThread;
+ (void)resetContextForCurrentThread;

- (void) observeContext:(NSManagedObjectContext *)otherContext;
- (void) stopObservingContext:(NSManagedObjectContext *)otherContext;
- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext;

- (BOOL) save;
- (BOOL) saveWithErrorHandler:(CoreDataError)errorCallback;

- (BOOL) saveOnMainThread;
- (BOOL) saveOnBackgroundThread;

+ (NSManagedObjectContext *) context;
+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThread;
+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

@property (nonatomic) BOOL notifiesMainContextOnSave;

@end