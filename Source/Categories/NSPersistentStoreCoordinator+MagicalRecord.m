//
//  NSPersistentStoreCoordinator+MagicalRecord.m
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "MagicalRecord+Private.h"

static NSPersistentStoreCoordinator *defaultCoordinator_ = nil;

@implementation NSPersistentStoreCoordinator (MagicalRecord)

+ (NSPersistentStoreCoordinator *)defaultStoreCoordinator
{
	if (!defaultCoordinator_) {
		defaultCoordinator_ = [self coordinator];
	}
	return defaultCoordinator_;
}

+ (BOOL) _hasDefaultStoreCoordinator
{
	return !!defaultCoordinator_;
}
+ (void)_setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	defaultCoordinator_ = coordinator;
	if (defaultCoordinator_ && ![NSPersistentStore defaultPersistentStore])
	{
		NSArray *persistentStores = [defaultCoordinator_ persistentStores];
		if ([persistentStores count])
		{
			[NSPersistentStore _setDefaultPersistentStore:[persistentStores objectAtIndex:0]];
		}
	}
}

- (void)_createPathToStoreFileIfNeccessary:(NSURL *)urlForStore
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSURL *pathToStore = [urlForStore URLByDeletingLastPathComponent];
	
	NSError *error = nil;
	[fileManager createDirectoryAtPath:[pathToStore path] withIntermediateDirectories:YES attributes:nil error:&error];
    [MagicalRecord handleError:error];
}

- (void)setupSqliteStoreAtURL:(NSURL *)storeURL withOptions:(NSDictionary *)options
{
	[self _createPathToStoreFileIfNeccessary:storeURL];
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
	[MagicalRecord handleError:error];
	[NSPersistentStore _setDefaultPersistentStore:store];		
}

- (void)setupSqliteStoreNamed:(NSString *)storeFilename withOptions:(NSDictionary *)options
{
	NSURL *storeURL = [NSPersistentStore URLForStoreName:storeFilename];
	[self setupSqliteStoreAtURL:storeURL withOptions:options];
}

+ (NSPersistentStoreCoordinator *)coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[psc setupSqliteStoreAtURL:[persistentStore URL] withOptions:nil];
	
	return psc;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[psc setupSqliteStoreNamed:storeFileName withOptions:options];
	
	return psc;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName
{
	return [self coordinatorWithSqliteStoreNamed:storeFileName withOptions:nil];
}

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL withOptions:(NSDictionary *)options
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[psc setupSqliteStoreAtURL:storeURL withOptions:options];
	
	return psc;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreAtURL:(NSURL *)storeURL
{
	return [self coordinatorWithSqliteStoreAtURL:storeURL withOptions:nil];
}

- (void)setupAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 nil];
	
	[self setupSqliteStoreNamed:storeFileName withOptions:options];
}

- (void)setupAutoMigratingSqliteStoreAtURL:(NSURL *) storeURL
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 nil];
	
	[self setupSqliteStoreAtURL:storeURL withOptions:options];
}

+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[coordinator setupAutoMigratingSqliteStoreNamed:storeFileName];
	
	//HACK: lame solution to fix automigration error "Migration failed after first pass"
	if ([[coordinator persistentStores] count] == 0) 
	{
		[coordinator performSelector:@selector(setupAutoMigratingSqliteStoreNamed:) withObject:storeFileName afterDelay:0.5];
	}
	return coordinator;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[coordinator setupAutoMigratingSqliteStoreAtURL:storeURL];
	
	//HACK: lame solution to fix automigration error "Migration failed after first pass"
	if ([[coordinator persistentStores] count] == 0) 
	{
		[coordinator performSelector:@selector(setupAutoMigratingSqliteStoreAtURL:) withObject:storeURL afterDelay:0.5];
	}
	return coordinator;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithInMemoryStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[psc addInMemoryStore];
	
	return psc;
}

- (NSPersistentStore *)addInMemoryStore
{
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType:NSInMemoryStoreType configuration:nil URL:nil options:nil error:&error];
    [MagicalRecord handleError:error];
	return store;
}

+ (NSPersistentStoreCoordinator *)coordinator
{
	return [self coordinatorWithSqliteStoreNamed:kMagicalRecordDefaultStoreFileName];
}

+ (NSPersistentStoreCoordinator *)newPersistentStoreCoordinator
{
	return [self coordinator];
}

@end
