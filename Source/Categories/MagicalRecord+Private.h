//
//  MagicalRecord+Private.h
//  MagicalRecord
//
//  Created by Saul Mora on 11/15/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

@interface NSManagedObjectContext(MagicalRecordPrivate)
+ (void)_setDefaultContext:(NSManagedObjectContext *)newDefault;
@end

@interface NSManagedObjectModel(MagicalRecordPrivate)
+ (void)_setDefaultManagedObjectModel:(NSManagedObjectModel *)newModel;
@end

@interface NSPersistentStore(MagicalRecordPrivate)
+ (void)_setDefaultPersistentStore:(NSPersistentStore *)store;
@end

@interface NSPersistentStoreCoordinator(MagicalRecordPrivate)
+ (void)_setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator;
@end

@interface MagicalRecord(MagicalRecordPrivate)
+ (NSString *)currentStack;
+ (void)_cleanUp;
@end

extern NSString *const kMagicalRecordDefaultStoreFileName;