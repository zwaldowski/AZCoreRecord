//
//  NSManagedObjectContext+MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 11/23/09.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "NSManagedObjectContext+MagicalRecord.h"
#import "MagicalRecord+Private.h"
#import <objc/runtime.h>

NSString *const MagicalRecordDidMergeUbiquitousChangesNotification = @"MagicalRecordDidMergeUbiquitousChanges";
static NSManagedObjectContext *_defaultManagedObjectContext = nil;
static NSString const *kMagicalRecordManagedObjectContextKey = @"MRManagedObjectContext";
static void *kParentContextKey;

@implementation NSManagedObjectContext (MagicalRecord)

+ (void)load {
	mr_swizzle(@selector(_mr_setParentContext:), @selector(setParentContext:));
	mr_swizzle(@selector(_mr_parentContext), @selector(parentContext));
}

#pragma mark - Instance Methods

- (BOOL) save
{
	return [self saveWithErrorHandler: NULL];
}
- (BOOL) saveWithErrorHandler: (MRErrorBlock) errorCallback
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
			[MagicalRecord handleError: error];
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
	else
		context = [NSManagedObjectContext contextWithStoreCoordinator:self.persistentStoreCoordinator];
	
	context.parentContext = self;
	
	return context;
}

#pragma mark - Parent Context

@dynamic parentContext;

- (NSManagedObjectContext *) _mr_parentContext
{
	NSManagedObjectContext *parentContext = objc_getAssociatedObject(self, &kParentContextKey);	
	if (!parentContext && [self respondsToSelector: @selector(_mr_parentContext)])
	{
		return [self _mr_parentContext];
	}
	return parentContext;
}
- (void) _mr_setParentContext:(NSManagedObjectContext *)parentContext
{
	if ([parentContext respondsToSelector:@selector(concurrencyType)] && parentContext.concurrencyType != NSConfinementConcurrencyType)
	{
		[self _mr_setParentContext:parentContext];
		return;
	}
	
	NSNotificationCenter *dnc = [NSNotificationCenter defaultCenter];
	if (self.parentContext) [dnc removeObserver: self.parentContext name: NSManagedObjectContextDidSaveNotification object: self];
	objc_setAssociatedObject(self, &kParentContextKey, parentContext, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[dnc addObserver: parentContext selector: @selector(mergeChangesFromContextDidSaveNotification:) name: NSManagedObjectContextDidSaveNotification object: self];
}

#pragma mark - Default Contexts

+ (BOOL) _hasDefaultContext
{
	return !!_defaultManagedObjectContext;
}

+ (NSManagedObjectContext *) defaultContext
{
    if (!_defaultManagedObjectContext)
	{
        if ([self instancesRespondToSelector: @selector(initWithConcurrencyType:)])
		{
            _defaultManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        }
		else
		{
            _defaultManagedObjectContext = [NSManagedObjectContext new];
        }
		
		_defaultManagedObjectContext.persistentStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	}
	
	return _defaultManagedObjectContext;
}
+ (NSManagedObjectContext *) contextForCurrentThread
{
	if ([NSThread isMainThread])
	{
		return [self defaultContext];
	}
	
	NSMutableDictionary *threadDict = [[NSThread currentThread] threadDictionary];
	NSManagedObjectContext *threadContext = [threadDict objectForKey:kMagicalRecordManagedObjectContextKey];
	if (!threadContext)
	{
		threadContext = [[self defaultContext] newChildContext];
		[threadDict setObject: threadContext forKey: kMagicalRecordManagedObjectContextKey];
	}
	
	return threadContext;
}

+ (void) _setDefaultContext: (NSManagedObjectContext *) newDefault
{
	BOOL isUbiquitous = [MagicalRecord _isUbiquityEnabled];
	BOOL isManagedDocument = NO;
	if ([newDefault respondsToSelector:@selector(concurrencyType)]) {
		isManagedDocument = (newDefault.concurrencyType == NSMainQueueConcurrencyType && newDefault.parentContext.concurrencyType == NSPrivateQueueConcurrencyType && !newDefault.parentContext.parentContext);
	}
	
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	if (isUbiquitous && !isManagedDocument)
		[_defaultManagedObjectContext stopObservingUbiquitousChangesInCoordinator:coordinator];
	_defaultManagedObjectContext = newDefault;
	if (isUbiquitous && !isManagedDocument)
		[_defaultManagedObjectContext startObservingUbiquitousChangesInCoordinator:coordinator];
}

#pragma mark - Context Factory Methods

+ (NSManagedObjectContext *) context
{
	return [self contextWithStoreCoordinator: [NSPersistentStoreCoordinator defaultStoreCoordinator]];
}
+ (NSManagedObjectContext *) contextWithStoreCoordinator: (NSPersistentStoreCoordinator *) coordinator
{
	NSAssert1(coordinator, @"%s must be passed a persistent store coordinator", sel_getName(_cmd));
	
	MRLog(@"Creating managed object context%@...", [NSThread isMainThread] ? @" on main thread" : @"");
	
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
		MRLog(@"Merging changes From iCloud %@context%@", self == [NSManagedObjectContext MR_defaultContext] ? @"*** DEFAULT *** " : @"", ([NSThread isMainThread] ? @" *** on Main Thread ***" : @""));
		[self mergeChangesFromContextDidSaveNotification:notification];
		[[NSNotificationCenter defaultCenter] postNotificationName:MagicalRecordDidMergeUbiquitousChangesNotification object:self userInfo:[notification userInfo]];
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
