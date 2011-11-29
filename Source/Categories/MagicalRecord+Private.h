//
//  MagicalRecord+Private.h
//  Magical Record
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

DISPATCH_EXPORT DISPATCH_PURE DISPATCH_WARN_RESULT DISPATCH_NOTHROW
dispatch_queue_t mr_get_background_queue(void);

extern IMP mr_getSupersequent(id obj, SEL selector); // Defined in MagicalRecord.m
#define getSupersequent() (mr_getSupersequent(self, _cmd))
#define invokeSupersequent(...)  getSupersequent()(self, _cmd, ## __VA_ARGS__)

@interface NSManagedObjectContext (MagicalRecordPrivate)

+ (BOOL) _hasDefaultContext;
+ (void) _setDefaultContext: (NSManagedObjectContext *) newDefault;

@end

@interface NSManagedObjectModel (MagicalRecordPrivate)

+ (BOOL) _hasDefaultModel;
+ (void) _setDefaultModel: (NSManagedObjectModel *) newModel;

@end

@interface NSPersistentStore (MagicalRecordPrivate)

+ (BOOL) _hasDefaultPersistentStore;
+ (void) _setDefaultPersistentStore: (NSPersistentStore *) store;

@end

@interface NSPersistentStoreCoordinator (MagicalRecordPrivate)

+ (BOOL) _hasDefaultStoreCoordinator;
+ (void) _setDefaultStoreCoordinator: (NSPersistentStoreCoordinator *)coordinator;

+ (NSString *)_defaultStoreName;

@end

@interface MagicalRecord (MagicalRecordPrivate)

+ (void) _cleanUp;

+ (BOOL) _stackShouldAutoMigrateStore;
+ (BOOL) _stackShouldUseInMemoryStore;
+ (NSString *) _stackStoreName;
+ (NSURL *) _stackStoreURL;
+ (NSString *) _stackModelName;
+ (NSURL *) _stackModelURL;

@end

extern NSString *const kMagicalRecordDefaultStoreFileName;
