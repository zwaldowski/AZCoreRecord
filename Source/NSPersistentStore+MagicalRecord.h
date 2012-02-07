//
//  NSPersistentStore+MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MagicalRecord.h"

/** MagicalRecord for NSPersistentStore.  Allows for
 a default persistent store and automatic store creation.
 */
@interface NSPersistentStore (MagicalRecord)

/** The default persistent store.
 
 @return A persistent store.
 */
+ (NSPersistentStore *) defaultPersistentStore;

/** Creates and returns a URL for a given store name.
 
 @param storeFileName A file name, like @"Nyan.sqlite"
 @return A URL for the store in the user's path.
 */
+ (NSURL *) URLForStoreName: (NSString *) storeFileName;

+ (NSURL *) URLForUbiquitousContainer: (NSString *) bucketName;

/** Creates and returns a URL for the default store
 name in the user's directory.
 
 @return A URL for <<App Name>>.sqlite in the user's directory.
 */
+ (NSURL *) defaultLocalStoreURL;

@end