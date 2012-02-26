//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSPersistentStoreCoordinator *_defaultCoordinator = nil;

static NSDictionary *mr_automaticLightweightMigrationOptions(void) {
	static NSDictionary *options = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		id yes = (__bridge id)kCFBooleanTrue;
		options = [NSDictionary dictionaryWithObjectsAndKeys:
				   YES, NSMigratePersistentStoresAutomaticallyOption,
				   yes, NSInferMappingModelAutomaticallyOption, nil];
	});
	return options;
}

@implementation NSPersistentStoreCoordinator (MagicalRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	if (!_defaultCoordinator)
	{
		NSURL *storeURL = [MagicalRecord _stackStoreURL];
		
		if (!storeURL)
			storeURL = [NSPersistentStore URLForStoreName:[MagicalRecord _stackStoreName]];
		
		if (!storeURL)
			storeURL = [NSPersistentStore defaultLocalStoreURL];
		
		NSString *storeType = [MagicalRecord _stackShouldUseInMemoryStore] ? NSInMemoryStoreType : NSSQLiteStoreType;
		NSDictionary *options = [self _storeOptions];
		
		NSPersistentStoreCoordinator *psc = [self coordinatorWithStoreAtURL: storeURL ofType: storeType options: options];
		
		[self _setDefaultStoreCoordinator:psc];
	}
	
	return _defaultCoordinator;
}

+ (BOOL) _hasDefaultStoreCoordinator
{
	return !!_defaultCoordinator;
}
+ (void) _setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	_defaultCoordinator = coordinator;
	
	// NB: If `_defaultCoordinator` is nil, then `persistentStores` is also nil, so `count` returns 0
	if (![NSPersistentStore _hasDefaultPersistentStore] && _defaultCoordinator.persistentStores.count)
	{
		NSPersistentStore *defaultStore = [_defaultCoordinator.persistentStores objectAtIndex: 0];
		[NSPersistentStore _setDefaultPersistentStore: defaultStore];
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
    [MagicalRecord handleError: fmError];
	
	// Add the persistent store
	dispatch_block_t addBlock = ^{
		NSError *pscError = nil;
		[psc addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &pscError];
		[MagicalRecord handleError: pscError];
	};
	
	addBlock();
	
	// HACK: Lame solution to fix automigration error "Migration failed after first pass"
	if (!psc.persistentStores.count)
	{
		dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
		dispatch_after(when, dispatch_get_main_queue(), addBlock);
	}
	
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
    [MagicalRecord handleError: error];
	return store;
}

#pragma mark - Ubiquity

+ (NSDictionary *)_storeOptions {
	BOOL shouldAutoMigrate = [MagicalRecord _stackShouldAutoMigrateStore];
	BOOL shouldUseCloud = ([MagicalRecord _stackUbiquityOptions] != nil);
	
	NSMutableDictionary *options = shouldAutoMigrate || shouldUseCloud ? [NSMutableDictionary dictionary] : nil;
	
	if (shouldAutoMigrate)
		[options addEntriesFromDictionary:mr_automaticLightweightMigrationOptions()];
	
	if (shouldUseCloud)
		[options addEntriesFromDictionary:[MagicalRecord _stackUbiquityOptions]];
	
	return options;
}

- (void)_setUbiquityEnabled:(BOOL)enabled {
	NSPersistentStore *mainStore = [NSPersistentStore defaultPersistentStore];
	
	if ((([mainStore.options objectForKey:NSPersistentStoreUbiquitousContentURLKey]) != nil) == enabled)
		return;
	
	NSDictionary *newOptions = [NSPersistentStoreCoordinator _storeOptions];
	
	NSError *err = nil;
	[self migratePersistentStore:mainStore toURL:mainStore.URL options:newOptions withType:mainStore.type error:&err];
	[MagicalRecord handleError:err];
}

@end
