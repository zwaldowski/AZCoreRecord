//
//  MagicalRecord+Private.h
//  Magical Record
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MagicalRecord.h"

DISPATCH_EXPORT DISPATCH_PURE DISPATCH_WARN_RESULT DISPATCH_NOTHROW dispatch_queue_t mr_get_background_queue(void);

extern void mr_swizzle_support(Class cls, SEL oldSel, SEL newSel);
#define mr_swizzle(oldSelector, newSelector) mr_swizzle_support([self class], oldSelector, newSelector)

@class MagicalRecord;

@interface NSManagedObjectContext (MagicalRecordPrivate)

+ (BOOL) mr_hasDefaultContext;
+ (void) mr_setDefaultContext: (NSManagedObjectContext *) newDefault;

- (void) mr_setParentContext: (NSManagedObjectContext *) context;
- (NSManagedObjectContext *) mr_parentContext;

@end

@interface NSManagedObjectModel (MagicalRecordPrivate)

+ (BOOL) mr_hasDefaultModel;
+ (void) mr_setDefaultModel: (NSManagedObjectModel *) newModel;

@end

@interface NSPersistentStore (MagicalRecordPrivate)

+ (BOOL) mr_hasDefaultPersistentStore;
+ (void) mr_setDefaultPersistentStore: (NSPersistentStore *) store;

@end

@interface NSPersistentStoreCoordinator (MagicalRecordPrivate)

+ (BOOL) mr_hasDefaultStoreCoordinator;
+ (void) mr_setDefaultStoreCoordinator: (NSPersistentStoreCoordinator *)coordinator;

+ (NSDictionary *) mr_storeOptions;
- (void) mr_setUbiquityEnabled:(BOOL)enabled;

@end

@interface MagicalRecord (MagicalRecordPrivate)

+ (void) mr_cleanUp;

+ (BOOL) mr_stackShouldAutoMigrateStore;
+ (BOOL) mr_stackShouldUseInMemoryStore;
+ (NSString *) mr_stackStoreName;
+ (NSURL *) mr_stackStoreURL;
+ (NSString *) mr_stackModelName;
+ (NSURL *) mr_stackModelURL;
+ (NSDictionary *) mr_stackUbiquityOptions;

@end