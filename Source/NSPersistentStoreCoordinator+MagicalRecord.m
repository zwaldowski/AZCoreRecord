//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSPersistentStoreCoordinator *_defaultCoordinator = nil;
NSString *const MagicalRecordCompletedCloudSetupNotification = @"MagicalRecordCompletedCloudSetupNotification";

@implementation NSPersistentStoreCoordinator (MagicalRecord)

#pragma mark - Default Store Coordinator

+ (NSPersistentStoreCoordinator *) defaultStoreCoordinator
{
	if (!_defaultCoordinator)
	{
		NSURL *storeURL = [MagicalRecord _stackStoreURL];
		if (!storeURL || ![[storeURL pathExtension] isEqualToString:@"sqlite"])
		{
			NSString *storeName = [MagicalRecord _stackStoreName] ?: [self _defaultStoreName];
			storeURL = [NSPersistentStore URLForStoreName:storeName];
		}
		
		NSString *storeType = [MagicalRecord _stackShouldUseInMemoryStore] ? NSInMemoryStoreType : NSSQLiteStoreType;
		BOOL shouldAutoMigrate = [MagicalRecord _stackShouldAutoMigrateStore];
		BOOL shouldUseCloud = ([MagicalRecord _stackUbiquityOptions] != nil);
				
		NSPersistentStoreCoordinator *psc = [self coordinatorWithStoreAtURL:storeURL ofType:storeType automaticLightweightMigrationEnabled:shouldAutoMigrate ubiquityEnabled:shouldUseCloud];
		
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

+ (NSString *)_defaultStoreName {
	NSString *defaultName = [[[NSBundle mainBundle] infoDictionary] valueForKey:(id)kCFBundleNameKey];
	if (!defaultName)
	{
		defaultName = kMagicalRecordDefaultStoreFileName;
	}
	
	if (![defaultName hasSuffix:@"sqlite"]) 
	{
		defaultName = [defaultName stringByAppendingPathExtension:@"sqlite"];
	}

	return defaultName;
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
+ (NSPersistentStoreCoordinator *) coordinatorWithContainer: (NSString *) containerID contentNameKey: (NSString *) key storeNamed: (NSString *) storeName cloudStorePathComponent: (NSString *) pathComponent
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[psc addUbiquitousContainer:containerID contentNameKey:key storeNamed:storeName cloudStorePathComponent:pathComponent];
	return psc;
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
	NSError *pscError = nil;
	[psc addPersistentStoreWithType: storeType configuration: nil URL: storeURL options: options error: &pscError];
	[MagicalRecord handleError: pscError];
	
	return psc;
}
+ (NSPersistentStoreCoordinator *) coordinatorWithContainer: (NSString *) containerID contentNameKey: (NSString *) key storeAtURL: (NSURL *) storeURL cloudStorePathComponent: (NSString *) pathComponent
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	[psc addUbiquitousContainer:containerID contentNameKey:key storeAtURL:storeURL cloudStorePathComponent:pathComponent];	
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
	return [self coordinatorWithStoreAtURL:storeURL ofType:storeType automaticLightweightMigrationEnabled:enabled ubiquityEnabled:NO];
}
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled
{
	return [self coordinatorWithStoreNamed:storeName ofType:storeType automaticLightweightMigrationEnabled:enabled ubiquityEnabled:NO];
}

+ (NSPersistentStoreCoordinator *) coordinatorWithStoreAtURL: (NSURL *) storeURL ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled ubiquityEnabled:(BOOL)ubiquity
{	
	NSMutableDictionary *options = enabled || ubiquity ? [NSMutableDictionary dictionary] : nil;
	
	if (enabled)
		[options addEntriesFromDictionary:[self automaticLightweightMigrationOptions]];
	
	if (ubiquity)
		[options addEntriesFromDictionary:[MagicalRecord _stackUbiquityOptions]];
	
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
+ (NSPersistentStoreCoordinator *) coordinatorWithStoreNamed: (NSString *) storeName ofType: (NSString *) storeType automaticLightweightMigrationEnabled: (BOOL) enabled ubiquityEnabled:(BOOL)ubiquity
{
	NSURL *storeURL = [NSPersistentStore URLForStoreName: storeName];
	return [self coordinatorWithStoreAtURL: storeURL ofType: storeType automaticLightweightMigrationEnabled: enabled ubiquityEnabled:ubiquity];
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

#pragma mark - Ubiquity Support

- (void)addUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key storeNamed:(NSString *)localStoreName cloudStorePathComponent:(NSString *)pathComponent
{
	NSURL *URL = [NSPersistentStore URLForStoreName:localStoreName];
	[self addUbiquitousContainer:containerID contentNameKey:key storeAtURL:URL cloudStorePathComponent:pathComponent];
}

- (void)addUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key storeAtURL:(NSURL *)localStoreURL cloudStorePathComponent:(NSString *)pathComponent
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSURL *cloudURL = [NSPersistentStore URLForUbiquitousContainer:containerID];
		if (pathComponent) 
		{
			cloudURL = [cloudURL URLByAppendingPathComponent:pathComponent];
		}
		
		NSDictionary *options = [[self class] automaticLightweightMigrationOptions];
		if (cloudURL)   //iCloud is available
		{
			NSMutableDictionary *cloudOptions = [NSMutableDictionary dictionaryWithObjectsAndKeys:
										   key, NSPersistentStoreUbiquitousContentNameKey,
										   cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
			[cloudOptions addEntriesFromDictionary:options];
			options = cloudOptions;
		}
		else 
		{
			MRLog(@"iCloud is not enabled");
		}
				
		[self lock];
		NSError *error = nil;
		[self addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:localStoreURL options:options error:&error];
		[MagicalRecord handleError:error];
		[self unlock];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			MRLog(@"iCloud Store Enabled: %@", [MagicalRecordHelpers currentStack]);
			[[NSNotificationCenter defaultCenter] postNotificationName:MagicalRecordCompletedCloudSetupNotification object:nil]; 
		});
	});   
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
