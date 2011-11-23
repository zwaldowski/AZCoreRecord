//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSPersistentStoreCoordinator *_defaultCoordinator = nil;

@interface NSPersistentStoreCoordinator ()

- (void) setUpStoreWithType: (NSString *) storeType URL: (NSURL *) storeURL options: (NSDictionary *) options;

@end

@implementation NSPersistentStoreCoordinator (MagicalRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	if (!_defaultCoordinator)
	{
		[self _setDefaultStoreCoordinator: [self coordinator]];
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
	if (_defaultCoordinator.persistentStores.count && ![NSPersistentStore defaultPersistentStore])
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
	[psc setUpStoreWithType: persistentStore.type URL: persistentStore.URL options: persistentStore.options];
	
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
	[psc setUpStoreWithType: storeType URL: storeURL options: options];
	
	return psc;

}

- (void) setUpStoreWithType: (NSString *) storeType URL: (NSURL *) storeURL options: (NSDictionary *) options
{
	// Create path to store
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *storeDirectory = [storeURL URLByDeletingLastPathComponent];
	
	NSError *error = nil;
	[fileManager createDirectoryAtURL: storeDirectory withIntermediateDirectories: YES attributes: nil error: &error];
    [MagicalRecord handleError: error];
	error = nil;
	
	[self addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &error];
	[MagicalRecord handleError: error];
	error = nil;
	
	//HACK: Lame solution to fix automigration error "Migration failed after first pass"
	if (!self.persistentStores.count)
	{
		dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC);
		dispatch_after(when, dispatch_get_main_queue(), ^(void){
			NSError *error = nil;
			[self addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &error];
			[MagicalRecord handleError: error];
		});
	}
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
	if (enabled)
	{
		NSDictionary *options = [self automaticLightweightMigrationOptions];
		return [self coordinatorWithStoreAtURL: storeURL ofType: storeType options: options];
	}
	
	return [self coordinatorWithStoreAtURL: storeURL ofType: storeType];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled
{
	if (enabled)
	{
		NSDictionary *options = [self automaticLightweightMigrationOptions];
		return [self coordinatorWithStoreNamed: storeName ofType: storeType options: options];
	}
	
	return [self coordinatorWithStoreNamed: storeName ofType: storeType];
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
