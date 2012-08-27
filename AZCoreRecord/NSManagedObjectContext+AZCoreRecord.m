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

- (id) existingObjectWithURI: (id) URI
{
	NSParameterAssert(URI);
	
	if ([URI isKindOfClass:[NSString class]])
		URI = [NSURL URLWithString:URI];
	
	if ([URI isKindOfClass:[NSURL class]])
		URI = [self.persistentStoreCoordinator managedObjectIDForURIRepresentation: URI];
	
	if (!URI || ![URI isKindOfClass:[NSManagedObjectID class]])
		return nil;
	
	return [self existingObjectWithID: URI];
}

- (id) existingObjectWithID: (NSManagedObjectID *) objectID
{
	NSError *error = nil;
	id ret = [self existingObjectWithID: objectID error: &error];
	[AZCoreRecordManager handleError: error];
	return ret;
}

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext
{
	return [[AZCoreRecordManager sharedManager] managedObjectContext];
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
	return [[AZCoreRecordManager sharedManager] contextForCurrentThread];
}

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext
{
	NSManagedObjectContext *context = [[[self class] alloc] initWithConcurrencyType: NSConfinementConcurrencyType];
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
	NSManagedObjectContext *context = [[AZCoreRecordManager sharedManager] managedObjectContext];
	[context performBlockAndWait: ^{
		[context reset];
	}];
}
+ (void) resetContextForCurrentThread 
{
	[[NSManagedObjectContext contextForCurrentThread] reset];
}

#pragma mark - Data saving

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block
{
	NSParameterAssert(block != nil);
	
	NSManagedObjectContext *localContext = [self newChildContext];
	
	NSMergePolicy *backupMergePolicy = self.mergePolicy;
	self.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
	localContext.mergePolicy = NSOverwriteMergePolicy;

	if (self.concurrencyType == NSConfinementConcurrencyType) {
		block(localContext);
	} else {
		[self performBlock: ^{
			block(localContext);
		}];
	}
	
	[localContext saveWithErrorHandler: NULL];
	
	self.mergePolicy = backupMergePolicy;
}

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block
{
	[self saveDataInBackgroundWithBlock: block completion: NULL];
}

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (AZCoreRecordVoidBlock) callback
{
	NSParameterAssert(block != nil);

	dispatch_queue_t currentQueue = dispatch_get_current_queue();

	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		[self saveDataWithBlock: block];

		if (callback)
			dispatch_async(currentQueue, callback);
	});
}

@end
