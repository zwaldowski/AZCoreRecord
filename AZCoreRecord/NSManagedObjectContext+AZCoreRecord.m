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
	__block BOOL success = YES;
	void (^block)(void) = ^{
		NSError *error = nil;
		success = [self save: &error];
		if (!success) {
			if (errorCallback)
				errorCallback(error);
			else
				[AZCoreRecordManager handleError: error];
		}
	};
	
	if (self.concurrencyType == NSConfinementConcurrencyType) {
		block();
	} else {
		[self performBlockAndWait: block];
	}
	
	return success;
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
	
	static dispatch_semaphore_t semaphore;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		semaphore = dispatch_semaphore_create(0);
	});
	
	dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);

	NSMutableDictionary *dict = [[NSThread currentThread] threadDictionary];
	static NSString const *AZCoreRecordManagedObjectContextKey = @"AZCoreRecordManagedObjectContext";
	context = [dict objectForKey: AZCoreRecordManagedObjectContextKey];
	if (!context)
	{
		context = [[self defaultContext] newChildContext];
		[dict setObject: context forKey: AZCoreRecordManagedObjectContextKey];
	}
	
	dispatch_semaphore_signal(semaphore);
	
	return context;
}

#pragma mark - Context Factory Methods

+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator
{
	NSParameterAssert(coordinator != nil);
	
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
	context.persistentStoreCoordinator = coordinator;
	
	return context;
}

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext
{
	NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
	context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	context.parentContext = self;	
	return context;
}

#pragma mark - Ubiquity Support

- (void) azcr_mergeUbiquitousChanges: (NSNotification *) notification
{
	[self performBlock: ^{
		[self mergeChangesFromContextDidSaveNotification: notification];
	}];
}

- (void) startObservingUbiquitousChanges
{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(azcr_mergeUbiquitousChanges:) name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: self.persistentStoreCoordinator];
}

- (void) stopObservingUbiquitousChanges
{
	[[NSNotificationCenter defaultCenter] removeObserver: self name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: self.persistentStoreCoordinator];
}

#pragma mark - Reset Context

+ (void) resetDefaultContext
{
	NSManagedObjectContext *context = [self defaultContext];
	[context performBlockAndWait: ^{
		[context reset];
	}];
}
+ (void) resetContextForCurrentThread 
{
	[[NSManagedObjectContext contextForCurrentThread] reset];
}

#pragma mark - Data saving

- (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *context)) block
{
	NSParameterAssert(block != nil);
	
	NSManagedObjectContext *localContext = [self newChildContext];
	
	NSMergePolicy *backupMergePolicy = self.mergePolicy;
	self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
	localContext.mergePolicy = NSOverwriteMergePolicy;
	
	block(localContext);
	
	[localContext save];
	
	self.mergePolicy = backupMergePolicy;
}

- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block
{
	[self saveDataInBackgroundWithBlock: block completion: NULL];
}

- (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback
{
	NSParameterAssert(block != nil);
	
	NSManagedObjectContext *localContext = [self newChildContext];
	
	NSMergePolicy *backupMergePolicy = self.mergePolicy;
	self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
	localContext.mergePolicy = NSOverwriteMergePolicy;
	
	[localContext performBlock: ^{
		block(localContext);
		
		[localContext save];
		
		self.mergePolicy = backupMergePolicy;
		
		if (callback)
			dispatch_async(dispatch_get_main_queue(), callback);
	}];
}

@end
