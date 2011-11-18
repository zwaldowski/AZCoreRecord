//
//  NSManagedObjectContext+MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObjectContext (MagicalRecord)

+ (NSManagedObjectContext *)defaultContext;
+ (void)resetDefaultContext;

+ (void)setDefaultConcurrencyType:(NSManagedObjectContextConcurrencyType)type __OSX_AVAILABLE_STARTING(__MAC_10_7, __IPHONE_5_0);

+ (NSManagedObjectContext *)contextForCurrentThread;
+ (void)resetContextForCurrentThread;

- (void) observeContext:(NSManagedObjectContext *)otherContext;
- (void) stopObservingContext:(NSManagedObjectContext *)otherContext;
- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext;

- (BOOL) save;
- (BOOL) saveWithErrorHandler:(MRErrorBlock)errorCallback;

- (BOOL) saveOnMainThread;
- (BOOL) saveOnBackgroundThread;

+ (NSManagedObjectContext *) context;
+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThread;
+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;

@property (nonatomic) BOOL notifiesMainContextOnSave;

@end
