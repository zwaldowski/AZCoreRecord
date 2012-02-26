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

+ (BOOL) _hasDefaultContext;
+ (void) _setDefaultContext: (NSManagedObjectContext *) newDefault;

- (void) _mr_setParentContext: (NSManagedObjectContext *) context;
- (NSManagedObjectContext *) _mr_parentContext;

@end

@interface NSManagedObjectModel (MagicalRecordPrivate)

+ (BOOL) _hasDefaultModel;
+ (void) _setDefaultModel: (NSManagedObjectModel *) newModel;

@end

@interface NSPersistentStore (MagicalRecordPrivate)

+ (BOOL) _hasDefaultPersistentStore;
+ (void) _setDefaultPersistentStore: (NSPersistentStore *) store;
+ (NSString *) _directory: (NSSearchPathDirectory) type;

@end

@interface NSPersistentStoreCoordinator (MagicalRecordPrivate)

+ (BOOL) _hasDefaultStoreCoordinator;
+ (void) _setDefaultStoreCoordinator: (NSPersistentStoreCoordinator *)coordinator;

+ (NSDictionary *)_storeOptions;
- (void) _setUbiquityEnabled:(BOOL)enabled;

@end

@interface MagicalRecord (MagicalRecordPrivate)

+ (void) _cleanUp;

+ (BOOL) _stackShouldAutoMigrateStore;
+ (BOOL) _stackShouldUseInMemoryStore;
+ (NSString *) _stackStoreName;
+ (NSURL *) _stackStoreURL;
+ (NSString *) _stackModelName;
+ (NSURL *) _stackModelURL;
+ (NSDictionary *) _stackUbiquityOptions;

@end