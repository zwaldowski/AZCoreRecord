//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSPersistentStoreCoordinator *_defaultCoordinator = nil;

@implementation NSPersistentStoreCoordinator (MagicalRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	if (!_defaultCoordinator)
	{
		NSURL *storeURL = [MagicalRecord _stackStoreURL];
		if (!storeURL) {
			NSString *storeName = [MagicalRecord _stackStoreName] ?: kMagicalRecordDefaultStoreFileName;
			storeURL = [NSPersistentStore URLForStoreName:storeName];
		}
		
		NSString *storeType = [MagicalRecord _stackShouldUseInMemoryStore] ? NSInMemoryStoreType : NSSQLiteStoreType;
		BOOL shouldAutoMigrate = [MagicalRecord _stackShouldAutoMigrateStore];
		
		NSPersistentStoreCoordinator *psc = [self coordinatorWithStoreAtURL:storeURL ofType:storeType automaticLightweightMigrationEnabled:shouldAutoMigrate];
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
	if (_defaultCoordinator.persistentStores.count && ![NSPersistentStore _hasDefaultPersistentStore])
	{
		NSPersistentStore *defaultStore = [_defaultCoordinator.persistentStores objectAtIndex: 0];
		[NSPersistentStore _setDefaultPersistentStore: defaultStore];
	}
}

#pragma mark - Store Coordinator Factory Methods

+ (NSPersistentStoreCoordinator *) coordinator
{
	return [self coordinatorWithStoreNamed: kMagicalRecordDefaultStoreFileName ofType: NSSQLiteStoreType];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithPersistentStore: (NSPersistentStore *) persistentStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
	
	NSError *error = nil;
	[psc addPersistentStoreWithType: persistentStore.type configuration: persistentStore.configurationName URL: persistentStore.URL options: persistentStore.options error: &error];
	[MagicalRecord handleError: error];
	
	return psc;
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
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *storeDirectory = [storeURL URLByDeletingLastPathComponent];
	
	NSError *fmError = nil;
	[fileManager createDirectoryAtURL: storeDirectory withIntermediateDirectories: YES attributes: nil error: &fmError];
    [MagicalRecord handleError: fmError];
	
	// Add the persistent store
	NSError *pscError = nil;
	[psc addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &pscError];
	[MagicalRecord handleError: pscError];
	
	return psc;
}

#pragma mark - Automatic Lightweight Migration

+ (NSDictionary *) automaticLightweightMigrationOptions
{
	static NSDictionary *options = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		id yes = (__bridge id) kCFBooleanTrue;
		options = [NSDictionary dictionaryWithObjectsAndKeys:
				   yes, NSMigratePersistentStoresAutomaticallyOption,
				   yes, NSInferMappingModelAutomaticallyOption, nil];
	});
	
	return options;
}

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled
{
	// If we don't want ALM...
	if (!enabled) return [self coordinatorWithStoreAtURL: storeURL ofType: storeType];
	
	NSDictionary *options = [self automaticLightweightMigrationOptions];
	NSPersistentStoreCoordinator *psc = [self coordinatorWithStoreAtURL: storeURL ofType: storeType options: options];
	
	// HACK: Lame solution to fix automigration error "Migration failed after first pass"
	if (!psc.persistentStores.count)
	{
		dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
		dispatch_after(when, dispatch_get_main_queue(), ^ {
			NSError *error = nil;
			[psc addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &error];
			[MagicalRecord handleError: error];
		});
	}
	
	return psc;
}
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled
{
	NSURL *storeURL = [NSPersistentStore URLForStoreName: storeName];
	return [self coordinatorWithStoreAtURL: storeURL ofType: storeType automaticLightweightMigrationEnabled: enabled];
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

#pragma mark Deprecated

+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeName
{
	return [self coordinatorWithStoreNamed: storeName ofType: NSSQLiteStoreType automaticLightweightMigrationEnabled: YES];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL
{
	return [self coordinatorWithStoreAtURL: storeURL ofType: NSSQLiteStoreType automaticLightweightMigrationEnabled: YES];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreAtURL: (NSURL *) storeURL
{
	return [self coordinatorWithStoreAtURL: storeURL ofType: NSSQLiteStoreType options: nil];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithSqliteStoreNamed: (NSString *) storeName
{
	return [self coordinatorWithStoreNamed: storeName ofType: NSSQLiteStoreType options: nil];
}

+ (NSPersistentStoreCoordinator *) newPersistentStoreCoordinator
{
	return [self coordinator];
}

@end
