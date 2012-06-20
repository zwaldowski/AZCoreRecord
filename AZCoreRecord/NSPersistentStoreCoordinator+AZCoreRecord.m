//
//  NSPersistentStoreCoordinator+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "AZCoreRecordManager.h"
#import "NSPersistentStore+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

@implementation NSPersistentStoreCoordinator (AZCoreRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	return [[AZCoreRecordManager sharedManager] persistentStoreCoordinator];
}

#pragma mark - Store Coordinator Factory Methods

+ (NSPersistentStoreCoordinator *) coordinator
{
	return [self coordinatorWithStoreAtURL: [NSPersistentStore defaultLocalStoreURL] ofType: NSSQLiteStoreType];
}

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType
{
	return [self coordinatorWithStoreNamed: storeName ofType: storeType options: nil];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType options: (NSDictionary *) options
{
	NSURL *storeURL = [NSPersistentStore URLForStoreName: storeName];
	return [self coordinatorWithStoreAtURL: storeURL ofType: storeType options: options];
}

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType
{
	return [self coordinatorWithStoreAtURL: storeURL ofType: storeType options: nil];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType options: (NSDictionary *) options
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
	
	// Create path to store (if necessary)
	NSFileManager *fileManager = [NSFileManager new];
	NSString *storePath = [[storeURL URLByDeletingLastPathComponent] path];
	
	NSError *fmError = nil;
	[fileManager createDirectoryAtPath: storePath withIntermediateDirectories: YES attributes: nil error: &fmError];
    [AZCoreRecordManager handleError: fmError];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		// Add the persistent store
		dispatch_block_t addBlock = ^{
			NSError *pscError = nil;
			[psc lock];
			[psc addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &pscError];
			[psc unlock];
			[AZCoreRecordManager handleError: pscError];
		};
		
		addBlock();
		
		// HACK: Lame solution to fix automigration error "Migration failed after first pass"
		if (!psc.persistentStores.count)
		{
			dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(when, dispatch_get_main_queue(), addBlock);
		}
	});
	
	return psc;
}

#pragma mark - In-Memory Store

+ (NSPersistentStoreCoordinator *) coordinatorWithInMemoryStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
	[psc addInMemoryStore];
	return psc;
}

- (NSPersistentStore *) addInMemoryStore
{
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType: NSInMemoryStoreType configuration: nil URL: nil options: nil error: &error];
    [AZCoreRecordManager handleError: error];
	return store;
}

@end
