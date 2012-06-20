//
//  AZCoreRecord+Private.h
//  AZCoreRecord
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecord.h"

extern void azcr_swizzle_support(Class cls, SEL oldSel, SEL newSel);
#define azcr_swizzle(oldSelector, newSelector) azcr_swizzle_support([self class], oldSelector, newSelector)

@interface NSManagedObjectContext (AZCoreRecordPrivate)

+ (BOOL) azcr_hasDefaultContext;
+ (void) azcr_setDefaultContext: (NSManagedObjectContext *) newDefault;

- (void) azcr_setParentContext: (NSManagedObjectContext *) context;
- (NSManagedObjectContext *) azcr_parentContext;

+ (void) azcr_saveDefaultContext: (NSNotification *) note;

@end

@interface NSManagedObjectModel (AZCoreRecordPrivate)

+ (BOOL) azcr_hasDefaultModel;
+ (void) azcr_setDefaultModel: (NSManagedObjectModel *) newModel;

@end

@interface NSPersistentStore (AZCoreRecordPrivate)

+ (BOOL) azcr_hasDefaultPersistentStore;
+ (void) azcr_setDefaultPersistentStore: (NSPersistentStore *) store;

@end

@interface NSPersistentStoreCoordinator (AZCoreRecordPrivate)

+ (BOOL) azcr_hasDefaultStoreCoordinator;
+ (void) azcr_setDefaultStoreCoordinator: (NSPersistentStoreCoordinator *)coordinator;

+ (NSDictionary *) azcr_storeOptions;
- (void) azcr_setUbiquityEnabled: (BOOL) enabled;

@end

@interface AZCoreRecord (AZCoreRecordPrivate)

+ (void) azcr_cleanUp;

+ (BOOL) azcr_stackShouldAutoMigrateStore;
+ (BOOL) azcr_stackShouldUseInMemoryStore;
+ (NSString *) azcr_stackStoreName;
+ (NSURL *) azcr_stackStoreURL;
+ (NSString *) azcr_stackModelName;
+ (NSURL *) azcr_stackModelURL;
+ (NSDictionary *) azcr_stackUbiquityOptions;

@end