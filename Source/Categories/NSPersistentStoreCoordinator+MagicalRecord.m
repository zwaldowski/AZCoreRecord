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

+ (void)setDefaultStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	defaultCoordinator_ = coordinator;
	if ([NSPersistentStore defaultPersistentStore] == nil)
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
	BOOL pathWasCreated = [fileManager createDirectoryAtPath:[pathToStore path] withIntermediateDirectories:YES attributes:nil error:&error];

	if (!pathWasCreated) 
	{
		[MagicalRecordHelpers handleErrors:error];
	}
}

- (void)setupSqliteStoreNamed:(id)storeFileName withOptions:(NSDictionary *)options
{
	NSURL *url = [storeFileName isKindOfClass:[NSURL class]] ? storeFileName : [NSPersistentStore URLForStoreName:storeFileName];
	[self _createPathToStoreFileIfNeccessary:url];
	
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:options error:&error];
    
	if (!store) 
		[MagicalRecordHelpers handleErrors:error];
    
	[NSPersistentStore _setDefaultPersistentStore:store];		
}

+ (NSPersistentStoreCoordinator *)coordinatorWithPersistentStore:(NSPersistentStore *)persistentStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[psc setupSqliteStoreNamed:[persistentStore URL] withOptions:nil];
	
	return psc;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName withOptions:(NSDictionary *)options
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[psc setupSqliteStoreNamed:storeFileName withOptions:options];
	
	return psc;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithSqliteStoreNamed:(NSString *)storeFileName
{
	return [self coordinatorWithSqliteStoreNamed:storeFileName withOptions:nil];
}

- (void)setupAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 [NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption,
							 [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption,
							 nil];
	
	[self setupSqliteStoreNamed:storeFileName withOptions:options];
}

+ (NSPersistentStoreCoordinator *)coordinatorWithAutoMigratingSqliteStoreNamed:(NSString *) storeFileName
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
	NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
	
	[coordinator setupAutoMigratingSqliteStoreNamed:storeFileName];
	
	//HACK: lame solution to fix automigration error "Migration failed after first pass"
	if ([[coordinator persistentStores] count] == 0) 
	{
		[coordinator performSelector:@selector(setupAutoMigratingSqliteStoreNamed:) withObject:storeFileName afterDelay:0.5];
	}
	return coordinator;
}

+ (NSPersistentStoreCoordinator *)coordinatorWithInMemoryStore
{
	NSManagedObjectModel *model = [NSManagedObjectModel defaultManagedObjectModel];
	NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

	[psc addInMemoryStore];
	
	return psc;
}

- (NSPersistentStore *)addInMemoryStore
{
	NSError *error = nil;
	NSPersistentStore *store = [self addPersistentStoreWithType:NSInMemoryStoreType
														 configuration:nil 
																   URL:nil
															   options:nil
																 error:&error];
	if (!store)
	{
		[MagicalRecordHelpers handleErrors:error];
	}
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
