//
//  NSManagedObjectContext+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectContext+AZCoreRecord.h"
#import "AZCoreRecordManager.h"
#import <objc/runtime.h>
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"

@implementation NSManagedObjectContext (AZCoreRecord)

#pragma mark - Instance Methods

- (BOOL) save
{
	return [self saveWithErrorHandler: NULL];
}
- (BOOL) saveWithErrorHandler: (void (^)(NSError *)) errorCallback
{
	NSError *error = nil;
	BOOL saved = [self save: &error];
	
	if (!saved)
	{
		if (errorCallback)
		{
			errorCallback(error);
		}
		else
		{
			[AZCoreRecordManager handleError: error];
		}
	}
	
	return saved;
}

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext
{
    return [[AZCoreRecordManager sharedManager] managedObjectContext];
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
	if ([NSThread isMainThread])
		return [self defaultContext];
	
	NSManagedObjectContext *context = nil;
	@synchronized(self) {
		NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
		static NSString const *AZCoreRecordManagedObjectContextKey = @"AZCoreRecordManagedObjectContext";
		context = [dict objectForKey: AZCoreRecordManagedObjectContextKey];
		if (!context)
		{
			context = [[self defaultContext] newChildContext];
			[dict setObject: context forKey: AZCoreRecordManagedObjectContextKey];
		}
	}
	return context;
}

#pragma mark - Context Factory Methods

+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator
{
	NSParameterAssert(coordinator);
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
	context.persistentStoreCoordinator = coordinator;
	return context;
}

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext
{
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
	context.persistentStoreCoordinator = self.persistentStoreCoordinator;
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	context.parentContext = self;	
	return context;
}

#pragma mark - Ubiquity Support

- (void)azcr_mergeUbiquitousChanges:(NSNotification *)notification {
	[self performBlock:^{
		[self mergeChangesFromContextDidSaveNotification:notification];
	}];
}

- (void)startObservingUbiquitousChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(azcr_mergeUbiquitousChanges:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
}

- (void)stopObservingUbiquitousChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
}

#pragma mark - Reset Context

+ (void) resetDefaultContext
{
	NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
	[context performBlockAndWait:^{
		[context reset];
	}];
}
+ (void) resetContextForCurrentThread 
{
	NSManagedObjectContext *context = [NSManagedObjectContext contextForCurrentThread];
	[context performBlockAndWait:^{
		[context reset];
	}];
}

#pragma mark - Data saving

- (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *)) block {
	NSParameterAssert(block);
	NSManagedObjectContext *localContext = [self newChildContext];
	NSMergePolicy *backupMergePolicy = self.mergePolicy;
	self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
	localContext.mergePolicy = NSOverwriteMergePolicy;
	[localContext performBlockAndWait:^{
		block(localContext);
	}];
	[localContext save];
	self.mergePolicy = backupMergePolicy;
}

- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block {
	[self saveDataInBackgroundWithBlock: block completion: NULL];
}

- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback {
	NSParameterAssert(block);
	NSManagedObjectContext *localContext = [self newChildContext];
	NSMergePolicy *backupMergePolicy = self.mergePolicy;
	self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
	localContext.mergePolicy = NSOverwriteMergePolicy;
	[localContext performBlock:^{
		block(localContext);
		
		[localContext save];
		
		self.mergePolicy = backupMergePolicy;
		
		if (callback)
			dispatch_async(dispatch_get_main_queue(), callback);
	}];
}


@end
