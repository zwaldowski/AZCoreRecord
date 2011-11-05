//
//  NSPersistentStore+MagicalRecord.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#import "MagicalRecordHelpers.h"

extern NSString *const kMagicalRecordDefaultStoreFileName;

/** MagicalRecord for NSPersistentStore.  Allows for
 a default persistent store and automatic store creation.
 */
@interface NSPersistentStore (MagicalRecord)

/** The default persistent store.
 
 @return A persistent store.
 */
+ (NSPersistentStore *)defaultPersistentStore;

/** Sets the default persistent store.
 
 @param store A persistent store.
 */
+ (void)setDefaultPersistentStore:(NSPersistentStore *)store;

/** Creates and returns a URL for a given store name.
 
 @param storeFileName A file name, like @"Nyan.sqlite"
 @return A URL for the store in the user's path.
 */
+ (NSURL *)URLForStoreName:(NSString *)storeFileName;

/** Creates and returns a URL for the default store
 name in the user's directory.
 
 @return A URL for CoreDataStore.sqlite in the user's directory.
 */
+ (NSURL *)defaultLocalStoreURL;

@end