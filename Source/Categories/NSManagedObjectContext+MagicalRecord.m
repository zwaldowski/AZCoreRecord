//
//  NSManagedObjectContext+MagicalRecord.m
//  MagicalRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSManagedObjectContext+MagicalRecord.h"
#import <objc/runtime.h>

static NSManagedObjectContext *defaultManagedObjectContext_ = nil;
static NSString const *kMagicalRecordManagedObjectContextKey = @"MagicalRecordManagedObjectContexts";
static const char *kNotfiesMainContextKey = "notifiesMainContext_";

@interface NSManagedObjectContext ()

- (void) mergeChangesFromNotification:(NSNotification *)notification;
- (void) mergeChangesOnMainThread:(NSNotification *)notification;

@end

@implementation NSManagedObjectContext (MagicalRecord)

+ (void)_resetDefaultStoreCoordinator {
    if (!defaultManagedObjectContext_)
        return;
    
    defaultManagedObjectContext_.persistentStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
}

+ (NSManagedObjectContext *)defaultContext
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		defaultManagedObjectContext_ = [NSManagedObjectContext new];
		[self _resetDefaultStoreCoordinator];
	});
	return defaultManagedObjectContext_;
}

+ (NSManagedObjectContext *) contextForCurrentThread
{
	if ([NSThread isMainThread])
		return [self defaultContext];
    
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	NSManagedObjectContext *threadContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextKey];
	if (threadContext == nil)
	{
		threadContext = [self contextThatNotifiesDefaultContextOnMainThread];
		[threadDict setObject:threadContext forKey:kMagicalRecordManagedObjectContextKey];
	}
	return threadContext;
    
}

+ (void) resetDefaultContext
{
	[[NSManagedObjectContext defaultContext] performSelectorOnMainThread:@selector(reset) withObject:nil waitUntilDone:NO];
}

+ (void) resetContextForCurrentThread 
{
	[[NSManagedObjectContext contextForCurrentThread] reset];
}

- (void) observeContext:(NSManagedObjectContext *)otherContext
{
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mergeChangesFromNotification:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:otherContext];
}

- (void) observeContextOnMainThread:(NSManagedObjectContext *)otherContext
{
	//	ARLog(@"Start Observing on Main Thread");
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(mergeChangesOnMainThread:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:otherContext];
}

- (void) stopObservingContext:(NSManagedObjectContext *)otherContext
{
	//	ARLog(@"Stop Observing Context");
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:NSManagedObjectContextDidSaveNotification
												  object:otherContext];
}

- (void) mergeChangesFromNotification:(NSNotification *)notification
{
	ARLog(@"Merging changes to %@context%@", 
		  self == [NSManagedObjectContext defaultContext] ? @"*** DEFAULT *** " : @"",
		  ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
	
	[self mergeChangesFromContextDidSaveNotification:notification];
}

- (void) mergeChangesOnMainThread:(NSNotification *)notification
{
	if ([NSThread isMainThread])
	{
		[self mergeChangesFromNotification:notification];
	}
	else
	{
		[self performSelectorOnMainThread:@selector(mergeChangesFromNotification:) withObject:notification waitUntilDone:YES];
	}
}

- (BOOL) save
{
	return [self saveWithErrorHandler:nil];
}

- (BOOL) saveWithErrorHandler:(void(^)(NSError *))errorCallback
{
	NSError *error = nil;
	BOOL saved = NO;
	
	@try
	{
		ARLog(@"Saving %@Context%@", 
			  self == [[self class] defaultContext] ? @" *** Default *** ": @"", 
			  ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
		
		saved = [self save:&error];
	}
	@catch (NSException *exception)
	{
		ARLog(@"Problem saving: %@", (id)[exception userInfo] ?: (id)[exception reason]);	
	}
	@finally 
	{
		if (!saved)
		{
			if (errorCallback)
			{
				errorCallback(error);
			}
			else if (error)
			{
				[MagicalRecordHelpers handleErrors:error];
			}
		}
	}
	return saved && error == nil;
}

- (void) saveWrapper
{
	@autoreleasepool {
		[self save];
	}
}

- (BOOL) saveOnBackgroundThread
{
	[self performSelectorInBackground:@selector(saveWrapper) withObject:nil];

	return YES;
}

- (BOOL) saveOnMainThread
{
	[self performSelectorOnMainThread:@selector(saveWrapper) withObject:nil waitUntilDone:YES];

	return YES;
}

- (BOOL) notifiesMainContextOnSave
{
	NSNumber *notifies = objc_getAssociatedObject(self, kNotfiesMainContextKey);
	return [notifies boolValue];
}

- (void) setNotifiesMainContextOnSave:(BOOL)enabled
{
	NSManagedObjectContext *mainContext = [[self class] defaultContext];
	if (self != mainContext) 
	{
		objc_setAssociatedObject(self, kNotfiesMainContextKey, [NSNumber numberWithBool:enabled], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
		if (enabled)
			[mainContext observeContextOnMainThread:self];
		else
			[mainContext stopObservingContext:self];
	}
}

+ (NSManagedObjectContext *) contextWithStoreCoordinator:(NSPersistentStoreCoordinator *)coordinator
{
	if (!coordinator)
		return nil;
	
	ARLog(@"Creating MOContext %@", [NSThread isMainThread] ? @" *** On Main Thread ***" : @"");
	NSManagedObjectContext *context = [NSManagedObjectContext new];
	[context setPersistentStoreCoordinator:coordinator];
	return context;
}

+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThreadWithCoordinator:(NSPersistentStoreCoordinator *)coordinator;
{
	NSManagedObjectContext *context = [self contextWithStoreCoordinator:coordinator];
	context.notifiesMainContextOnSave = YES;
	return context;
}

+ (NSManagedObjectContext *)context
{
	return [self contextWithStoreCoordinator:[NSPersistentStoreCoordinator defaultStoreCoordinator]];
}

+ (NSManagedObjectContext *) contextThatNotifiesDefaultContextOnMainThread
{
	NSManagedObjectContext *context = [self context];
	context.notifiesMainContextOnSave = YES;
	return context;
}

@end
