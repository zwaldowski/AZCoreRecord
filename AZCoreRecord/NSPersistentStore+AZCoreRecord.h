//
//  NSPersistentStore+AZCoreRecord.h
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

/** AZCoreRecord for NSPersistentStore.  Allows for
 a default persistent store and automatic store creation. */
@interface NSPersistentStore (AZCoreRecord)

/** Creates and returns a URL for a given store name.
 
 If a store name is not provided, the store name is either
 the store name of the default Core Record stack or the
 application's bundle name.
 
 @param storeFileName A file name, like @"Nyan.sqlite"
 @return A URL for the store in the sandboxed user directory.
 */
+ (NSURL *) URLForStoreName: (NSString *) storeFileName;

@end