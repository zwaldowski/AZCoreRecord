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

NSString *const AZCoreRecordDidMergeUbiquitousChangesNotification = @"AZCoreRecordDidMergeUbiquitousChanges";
static void *kParentContextKey;

@implementation NSManagedObjectContext (AZCoreRecord)

+ (void)load {
	azcr_swizzle(@selector(azcr_setParentContext:), @selector(setParentContext:));
	azcr_swizzle(@selector(azcr_parentContext), @selector(parentContext));
}

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

#pragma mark - Child Contexts

- (NSManagedObjectContext *) newChildContext
{
	return [self newChildContextWithConcurrencyType:NSConfinementConcurrencyType];
}
- (NSManagedObjectContext *) newChildContextWithConcurrencyType: (NSManagedObjectContextConcurrencyType) concurrencyType
{
	NSManagedObjectContext *context = nil;

	if ([self respondsToSelector:@selector(initWithConcurrencyType:)])
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType: concurrencyType];
	else {
		context = [NSManagedObjectContext contextWithStoreCoordinator:self.persistentStoreCoordinator];
		context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy;
	}
	
	context.parentContext = self;
	
	return context;
}

#pragma mark - Parent Context

@dynamic parentContext;

- (NSManagedObjectContext *) azcr_parentContext
{
	NSManagedObjectContext *parentContext = objc_getAssociatedObject(self, &kParentContextKey);	
	if (!parentContext && [self respondsToSelector: @selector(azcr_parentContext)])
	{
		return [self azcr_parentContext];
	}
	return parentContext;
}
- (void) azcr_setParentContext:(NSManagedObjectContext *)parentContext
{
	if ([parentContext respondsToSelector:@selector(concurrencyType)] && parentContext.concurrencyType != NSConfinementConcurrencyType)
	{
		[self azcr_setParentContext:parentContext];
		return;
	}
	
	NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
	if (self.parentContext) [dnc removeObserver: self.parentContext name: NSManagedObjectContextDidSaveNotification object: self];
	objc_setAssociatedObject(self, &kParentContextKey, parentContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[dnc addObserver: parentContext selector: @selector(mergeChangesFromContextDidSaveNotification:) name: NSManagedObjectContextDidSaveNotification object: self];
}

#pragma mark - Default Contexts

+ (NSManagedObjectContext *) defaultContext
{
    return [[AZCoreRecordManager sharedManager] managedObjectContext];
}
+ (NSManagedObjectContext *) contextForCurrentThread
{
	if ([NSThread isMainThread])
	{
		return [self defaultContext];
	}
	
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

+ (NSManagedObjectContext *) context
{
	return [self contextWithStoreCoordinator: [NSPersistentStoreCoordinator defaultStoreCoordinator]];
}
+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator
{
	NSAssert1(coordinator, @"%s must be passed a persistent store coordinator", sel_getName(_cmd));
		
	NSManagedObjectContext *context = nil;
	
	if ([self instancesRespondToSelector:@selector(initWithConcurrencyType:)]) {
		context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
	} else {
		context = [NSManagedObjectContext new];
	}

	context.persistentStoreCoordinator = coordinator;
	
	return context;
}

#pragma mark - Ubiquity Support

- (void)_mergeUbiquitousChanges:(NSNotification *)notification {
	[self performBlock:^{
		[self mergeChangesFromContextDidSaveNotification:notification];
		[[NSNotificationCenter defaultCenter] postNotificationName: AZCoreRecordDidMergeUbiquitousChangesNotification object:self userInfo:[notification userInfo]];
	}];
}

extern NSString *const NSPersistentStoreDidImportUbiquitousContentChangesNotification;

- (void)startObservingUbiquitousChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	if (&NSPersistentStoreDidImportUbiquitousContentChangesNotification) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_mergeUbiquitousChanges:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
	}
}

- (void)stopObservingUbiquitousChangesInCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	if (&NSPersistentStoreDidImportUbiquitousContentChangesNotification) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:coordinator];
	}
}

#pragma mark - Reset Context

+ (void) resetDefaultContext
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[[NSManagedObjectContext defaultContext] reset];
	});
}
+ (void) resetContextForCurrentThread 
{
	[[NSManagedObjectContext contextForCurrentThread] reset];
}

@end
