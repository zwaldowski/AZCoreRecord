//
//  MagicalRecord+Private.h
//  Magical Record
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

DISPATCH_EXPORT DISPATCH_PURE DISPATCH_WARN_RESULT DISPATCH_NOTHROW
dispatch_queue_t mr_get_background_queue(void);

extern IMP _mr_getSupersequent(id obj, SEL selector); // Defined in MagicalRecord.m
#define mr_getSupersequent() (_mr_getSupersequent(self, _cmd))
#define mr_invokeSupersequent(...)  mr_getSupersequent()(self, _cmd, ## __VA_ARGS__)

extern void _mr_swizzle(Class cls, SEL oldSel, SEL newSel);
#define mr_swizzle(oldSelector, newSelector) _mr_swizzle([self class], oldSelector, newSelector)

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