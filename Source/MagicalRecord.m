//
//  MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MagicalRecord+Private.h"
#import <objc/runtime.h>

static dispatch_queue_t backgroundQueue = nil;

#if __has_feature(objc_arc_weak)
static __weak id <MRErrorHandler> errorHandlerTarget = nil;
#else
static __unsafe_unretained id <MRErrorHandler> errorHandlerTarget = nil;
#endif

static MRErrorBlock errorHandlerBlock = NULL;
static BOOL errorHandlerIsClassMethod = NO;

static BOOL stackShouldAutoMigrate = NO;
static BOOL stackShouldUseUbiquity = NO;
static BOOL stackShouldUseInMemoryStore = NO;
static NSString *stackStoreName = nil;
static NSURL *stackStoreURL = nil;
static NSString *stackModelName = nil;
static NSURL *stackModelURL = nil;
static NSDictionary *stackUbiquityOptions = nil;

dispatch_queue_t mr_get_background_queue(void)
{
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		backgroundQueue = dispatch_queue_create("com.magicalpanda.MagicalRecord.backgroundQueue", 0);
	});
	
	return backgroundQueue;
}

extern void mr_swizzle_support(Class cls, SEL oldSel, SEL newSel) {
	Method origMethod = class_getInstanceMethod(cls, oldSel);
	Method newMethod = class_getInstanceMethod(cls, newSel);
	
	if (class_addMethod(cls, oldSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(cls, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

@implementation MagicalRecord

#pragma mark - Stack settings

static void mr_resetStoreCoordinator(void) {
	if ([NSPersistentStoreCoordinator _hasDefaultStoreCoordinator])
		[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:nil];
	if ([NSManagedObjectContext _hasDefaultContext])
		[NSManagedObjectContext _setDefaultContext:nil];
}

+ (BOOL)_stackShouldAutoMigrateStore
{
	return stackShouldAutoMigrate;
}
+ (void)setStackShouldAutoMigrateStore:(BOOL)shouldMigrate
{
	stackShouldAutoMigrate = shouldMigrate;	
	mr_resetStoreCoordinator();
}

+ (BOOL)_stackShouldUseInMemoryStore
{
	return stackShouldUseInMemoryStore;
}
+ (void)setStackShouldUseInMemoryStore:(BOOL)inMemory
{
	stackShouldUseInMemoryStore = inMemory;
	mr_resetStoreCoordinator();
}

+ (NSString *)_stackStoreName
{
	if (!stackStoreName.pathExtension)
		return [stackStoreName stringByAppendingPathExtension:@"sqlite"];
	return stackStoreName;
}
+ (void)setStackStoreName:(NSString *)name
{
	stackStoreName = [name copy];
	mr_resetStoreCoordinator();
}

+ (NSURL *)_stackStoreURL
{
	return stackStoreURL;
}
+ (void)setStackStoreURL:(NSURL *)URL
{
	stackStoreURL = URL;
	mr_resetStoreCoordinator();
}

+ (NSString *)_stackModelName
{
	return stackModelName;
}
+ (void)setStackModelName:(NSString *)name
{
	stackModelName = [name copy];
	[self _cleanUp];
}

+ (NSURL *)_stackModelURL
{
	return stackModelURL;
}
+ (void)setStackModelURL:(NSURL *)URL
{
	stackModelURL = URL;
	[self _cleanUp];
}

#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && defined(__MAC_10_4)
+ (void)setUpStackWithManagedDocument: (NSPersistentDocument *) managedDocument
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && defined(__IPHONE_5_0)
+ (void)setUpStackWithManagedDocument: (UIManagedDocument *) managedDocument
{
	[NSManagedObjectModel _setDefaultModel: managedDocument.managedObjectModel];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: managedDocument.managedObjectContext.persistentStoreCoordinator];
	[NSManagedObjectContext _setDefaultContext: managedDocument.managedObjectContext];
}
#endif

+ (NSDictionary *) _stackUbiquityOptions
{
	return stackUbiquityOptions;
}
+ (void)setStackUbiquityOptions:(NSDictionary *)dict
{
	stackUbiquityOptions = dict;
	reset_storeCoordinator();
}

+ (void) _cleanUp
{
	errorHandlerTarget = nil;
	errorHandlerBlock = NULL;
	errorHandlerIsClassMethod = NO;
	
	stackShouldAutoMigrate = NO;
	stackShouldUseInMemoryStore = NO;
	stackStoreName = nil;
	stackStoreURL = nil;
	stackModelName = nil;
	stackModelURL = nil;
	stackUbiquityOptions = nil;
	
	if (backgroundQueue) dispatch_release(backgroundQueue), backgroundQueue = nil;
	
	if ([NSManagedObjectContext _hasDefaultContext])
		[NSManagedObjectContext _setDefaultContext: nil];
	
	if ([NSManagedObjectModel _hasDefaultModel])
		[NSManagedObjectModel _setDefaultModel: nil];
	
	if ([NSPersistentStoreCoordinator _hasDefaultStoreCoordinator]) {
		[NSPersistentStore _setDefaultPersistentStore: nil];
		[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: nil];		
	}
}

#pragma mark - Ubiquity Support

+ (BOOL)supportsUbiquity
{
	return [NSPersistentStore URLForUbiquitousContainer:nil] != nil;
}

+ (BOOL)isUbiquityEnabled
{
	if (![self supportsUbiquity])
		return NO;
		
	if (![self _stackUbiquityOptions].count)
		return NO;
	
	return stackShouldUseUbiquity;
}

+ (void)setUbiquityEnabled:(BOOL)enabled {
	if (stackShouldUseUbiquity == enabled)
		return;
	
	stackShouldUseUbiquity = enabled;
	
	if (![self _stackUbiquityOptions])
		[self setUbiquitousContainer:nil contentNameKey:nil cloudStorePathComponent:nil];
	
	if (![NSPersistentStoreCoordinator _hasDefaultStoreCoordinator])
		return;
	
	NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	
	if ([NSManagedObjectContext _hasDefaultContext]) {
		NSManagedObjectContext *moc = [NSManagedObjectContext defaultContext];
		if (enabled)
			[moc startObservingUbiquitousChangesInCoordinator:psc];
		else
			[moc stopObservingUbiquitousChangesInCoordinator:psc];
	}
	
	[psc _setUbiquityEnabled:enabled];
}

+ (void)setUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key cloudStorePathComponent:(NSString *)pathComponent
{
	NSURL *cloudURL = [NSPersistentStore URLForUbiquitousContainer: containerID];
	if (pathComponent) cloudURL = [cloudURL URLByAppendingPathComponent:pathComponent];
	
	if (!key) key = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 key, NSPersistentStoreUbiquitousContentNameKey,
							 cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
	[self setStackUbiquityOptions:options];
}

#pragma mark - Error Handling

+ (NSString *) currentStack
{
	NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];
	
	[status appendFormat: @"Context:     %@\n", [NSManagedObjectContext defaultContext]];
	[status appendFormat: @"Model:       %@\n", [NSManagedObjectModel defaultModel]];
	[status appendFormat: @"Coordinator: %@\n", [NSPersistentStoreCoordinator defaultStoreCoordinator]];
	[status appendFormat: @"Store:       %@\n", [NSPersistentStore defaultPersistentStore]];
	
	return [status copy];
}

+ (void) handleError: (NSError *) error
{
	if (!error) return;
	
	MRErrorBlock block = [self errorHandler];
	if (block)
	{
		block(error);
		return;
	}
	
	id target = [self errorHandlerTarget];
	if (target)
	{
		if (errorHandlerIsClassMethod) target = [target class];
		[target performSelector: @selector(handleError:) withObject: error];
		return;
	}
	
	// Default Error Handler
	MRLog(@"Error: %@", error);
}

+ (MRErrorBlock) errorHandler
{
	return errorHandlerBlock;
}
+ (void) setErrorHandler: (MRErrorBlock) block
{
	errorHandlerBlock = [block copy];
}

+ (id<MRErrorHandler>) errorHandlerTarget
{
	return errorHandlerTarget;
}
+ (void) setErrorHandlerTarget: (id<MRErrorHandler>) target
{	
	if (target)
	{
		if ([target respondsToSelector: @selector(handleError:)])
			errorHandlerIsClassMethod = NO;
		else if ([[target class] respondsToSelector: @selector(handleError:)])
			errorHandlerIsClassMethod = YES;
		else
			NSAssert(NO, @"Error handler target must conform to the MRErrorHandler protocol");
	}
	
	errorHandlerTarget = target;
}

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (MRContextBlock) block
{   
    [self saveDataWithOptions: MRCoreDataSaveOptionsNone block: block success: NULL failure: NULL];
}

+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block
{
    [self saveDataWithOptions: MRCoreDataSaveOptionsBackground block: block success: NULL failure: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block completion: (MRBlock) callback
{
    [self saveDataWithOptions: MRCoreDataSaveOptionsBackground block: block success: callback failure: NULL];
}

+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (MRContextBlock) block
{
    [self saveDataWithOptions: options block: block success: NULL failure: NULL];
}
+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (MRContextBlock) block success: (MRBlock) callback
{
    [self saveDataWithOptions: options block: block success: callback failure:  NULL];
}
+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (MRContextBlock) block success: (MRBlock) callback failure: (MRErrorBlock) errorCallback
{
	BOOL wantsBackground = (options & MRCoreDataSaveOptionsBackground);
	BOOL wantsMainThread = (options & MRCoreDataSaveOptionsMainThread);
	
	NSParameterAssert(block);
	NSParameterAssert(!(wantsBackground && wantsMainThread));
	
	BOOL wantsAsync		 = (options & MRCoreDataSaveOptionsAsynchronous);
	BOOL usesNewContext	 = wantsBackground || (![NSThread isMainThread] && !wantsBackground && !wantsMainThread);
	
	dispatch_queue_t callbackBlock = wantsMainThread ? dispatch_get_main_queue() : dispatch_get_current_queue();
	
	dispatch_block_t queueBlock = ^{
		NSManagedObjectContext *defaultContext  = [NSManagedObjectContext defaultContext];
		NSManagedObjectContext *localContext = defaultContext;
		
		id backupMergePolicy = defaultContext.mergePolicy;
		
		if (usesNewContext)
		{
			localContext = [defaultContext newChildContext];
			defaultContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			localContext.mergePolicy = NSOverwriteMergePolicy;
		}
		
		block(localContext);
		
		if (localContext.hasChanges)
			[localContext saveWithErrorHandler:errorCallback];
		
		defaultContext.mergePolicy = backupMergePolicy;
		
		if (callback)
			dispatch_async(callbackBlock, callback);
	};
	
	if (!wantsMainThread && !wantsBackground && !wantsAsync) {
		queueBlock();
		return;
	}
	
	dispatch_queue_t queue = NULL;
	
	if (wantsBackground)
		queue = mr_get_background_queue();
	else if (wantsMainThread)
		queue = dispatch_get_main_queue();
	else
		queue = dispatch_get_current_queue();
	
	if (wantsAsync)
		dispatch_async(queue, queueBlock);
	else
		dispatch_sync(queue, queueBlock);
}

@end
