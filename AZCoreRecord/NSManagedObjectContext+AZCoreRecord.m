//
//  NSManagedObjectContext+AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectContext+AZCoreRecord.h"
#import "AZCoreRecordManager+Private.h"
#import <objc/runtime.h>
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIApplication.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#import <AppKit/NSApplication.h>
#endif

NSString *const AZCoreRecordDidMergeUbiquitousChangesNotification = @"AZCoreRecordDidMergeUbiquitousChanges";
static NSManagedObjectContext *_defaultManagedObjectContext = nil;
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
			[AZCoreRecord handleError: error];
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

+ (BOOL) azcr_hasDefaultContext
{
	return !!_defaultManagedObjectContext;
}

+ (NSManagedObjectContext *) defaultContext
{
    if (!_defaultManagedObjectContext)
	{
		NSManagedObjectContext *newDefault = nil;
        if ([self instancesRespondToSelector: @selector(initWithConcurrencyType:)])
		{
            newDefault = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        }
		else
		{
            newDefault = [NSManagedObjectContext new];
        }
		
		newDefault.persistentStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
		[self azcr_setDefaultContext:newDefault];
	}
	
	return _defaultManagedObjectContext;
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

+ (void) azcr_saveDefaultContext: (NSNotification *) note
{
	if ([self azcr_hasDefaultContext]) {
		NSManagedObjectContext *context = [self defaultContext];
		
		if (!context.hasChanges)
			return;
		
		[context save];
	}
}

+ (void) azcr_setDefaultContext: (NSManagedObjectContext *) newDefault
{
	BOOL isUbiquitous = [AZCoreRecord isUbiquityEnabled];
	NSPersistentStoreCoordinator *coordinator = coordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	
	if (isUbiquitous)
		[_defaultManagedObjectContext stopObservingUbiquitousChangesInCoordinator:coordinator];

	_defaultManagedObjectContext = newDefault;
	
	if (isUbiquitous)
		[_defaultManagedObjectContext startObservingUbiquitousChangesInCoordinator:coordinator];
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(azcr_saveDefaultContext:) name: UIApplicationWillTerminateNotification object: [UIApplication sharedApplication]];
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(azcr_saveDefaultContext:) name: NSApplicationWillTerminateNotification object: [NSApplication sharedApplication]];
#endif
	});
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
