//
//  NSPersistentStoreCoordinator+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "AZCoreRecordManager+Private.h"
#import "NSPersistentStore+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

static NSPersistentStoreCoordinator *_defaultCoordinator = nil;

static NSDictionary *azcr_automaticLightweightMigrationOptions(void) {
	static NSDictionary *options = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		id yes = (__bridge id)kCFBooleanTrue;
		options = [NSDictionary dictionaryWithObjectsAndKeys:
				   yes, NSMigratePersistentStoresAutomaticallyOption,
				   yes, NSInferMappingModelAutomaticallyOption, nil];
	});
	return options;
}

@implementation NSPersistentStoreCoordinator (AZCoreRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	if (!_defaultCoordinator)
	{
		NSURL *storeURL = [AZCoreRecord azcr_stackStoreURL] ?: [NSPersistentStore defaultLocalStoreURL];
		NSString *storeType = [AZCoreRecord azcr_stackShouldUseInMemoryStore] ? NSInMemoryStoreType : NSSQLiteStoreType;
		NSDictionary *options = [self azcr_storeOptions];
		
		NSPersistentStoreCoordinator *psc = [self coordinatorWithStoreAtURL: storeURL ofType: storeType options: options];
		
		[self azcr_setDefaultStoreCoordinator:psc];
	}
	
	return _defaultCoordinator;
}

+ (BOOL) azcr_hasDefaultStoreCoordinator
{
	return !!_defaultCoordinator;
}
+ (void) azcr_setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	_defaultCoordinator = coordinator;
	
	// NB: If `_defaultCoordinator` is nil, then `persistentStores` is also nil, so `count` returns 0
	if (![NSPersistentStore azcr_hasDefaultPersistentStore] && _defaultCoordinator.persistentStores.count)
	{
		NSPersistentStore *defaultStore = [_defaultCoordinator.persistentStores objectAtIndex: 0];
		[NSPersistentStore azcr_setDefaultPersistentStore: defaultStore];
	}
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
    [AZCoreRecord handleError: fmError];
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		// Add the persistent store
		dispatch_block_t addBlock = ^{
			NSError *pscError = nil;
			[psc lock];
			[psc addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &pscError];
			[psc unlock];
			[AZCoreRecord handleError: pscError];
		};
		
		addBlock();
		
		// HACK: Lame solution to fix automigration error "Migration failed after first pass"
		if (!psc.persistentStores.count)
		{
			dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
			dispatch_after(when, dispatch_get_main_queue(), addBlock);
		}
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if (![NSPersistentStore azcr_hasDefaultPersistentStore]) {
				[NSPersistentStoreCoordinator azcr_setDefaultStoreCoordinator: psc];
			}
		});
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
    [AZCoreRecord handleError: error];
	return store;
}

#pragma mark - Ubiquity

+ (NSDictionary *)aczr_storeOptions {
	BOOL shouldAutoMigrate = [AZCoreRecord azcr_stackShouldAutoMigrateStore];
	BOOL shouldUseCloud = ([AZCoreRecord azcr_stackUbiquityOptions] != nil);
	
	NSMutableDictionary *options = shouldAutoMigrate || shouldUseCloud ? [NSMutableDictionary dictionary] : nil;
	
	if (shouldAutoMigrate)
		[options addEntriesFromDictionary:azcr_automaticLightweightMigrationOptions()];
	
	if (shouldUseCloud)
		[options addEntriesFromDictionary:[AZCoreRecord azcr_stackUbiquityOptions]];
	
	return options;
}

- (void)_setUbiquityEnabled:(BOOL)enabled {
	NSPersistentStore *mainStore = [NSPersistentStore defaultPersistentStore];
	
	if ((([mainStore.options objectForKey:NSPersistentStoreUbiquitousContentURLKey]) != nil) == enabled)
		return;
	
	NSDictionary *newOptions = [NSPersistentStoreCoordinator aczr_storeOptions];
	
	NSError *err = nil;
	[self migratePersistentStore:mainStore toURL:mainStore.URL options:newOptions withType:mainStore.type error:&err];
	[AZCoreRecord handleError:err];
}

@end
