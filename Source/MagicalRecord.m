//
//  MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MagicalRecord+Private.h"
#import <objc/runtime.h>

#if __has_feature(objc_arc_weak)
static __weak id <MRErrorHandler> errorHandlerTarget = nil;
#else
static __unsafe_unretained id <MRErrorHandler> errorHandlerTarget = nil;
#endif

static void (^errorHandlerBlock)(NSError *) = NULL;
static BOOL errorHandlerIsClassMethod = NO;

static BOOL stackShouldAutoMigrate = NO;
static BOOL stackShouldUseUbiquity = NO;
static BOOL stackShouldUseInMemoryStore = NO;
static NSString *stackStoreName = nil;
static NSURL *stackStoreURL = nil;
static NSString *stackModelName = nil;
static NSURL *stackModelURL = nil;
static NSDictionary *stackUbiquityOptions = nil;

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
	if ([NSPersistentStoreCoordinator mr_hasDefaultStoreCoordinator])
		[NSPersistentStoreCoordinator mr_setDefaultStoreCoordinator:nil];
	if ([NSManagedObjectContext mr_hasDefaultContext])
		[NSManagedObjectContext mr_setDefaultContext:nil];
}

+ (BOOL)mr_stackShouldAutoMigrateStore
{
	return stackShouldAutoMigrate;
}
+ (void)setStackShouldAutoMigrateStore:(BOOL)shouldMigrate
{
	stackShouldAutoMigrate = shouldMigrate;	
	mr_resetStoreCoordinator();
}

+ (BOOL)mr_stackShouldUseInMemoryStore
{
	return stackShouldUseInMemoryStore;
}
+ (void)setStackShouldUseInMemoryStore:(BOOL)inMemory
{
	stackShouldUseInMemoryStore = inMemory;
	mr_resetStoreCoordinator();
}

+ (NSString *)mr_stackStoreName
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

+ (NSURL *)mr_stackStoreURL
{
	return stackStoreURL;
}
+ (void)setStackStoreURL:(NSURL *)URL
{
	stackStoreURL = URL;
	mr_resetStoreCoordinator();
}

+ (NSString *)mr_stackModelName
{
	return stackModelName;
}
+ (void)setStackModelName:(NSString *)name
{
	stackModelName = [name copy];
	[self mr_cleanUp];
}

+ (NSURL *)mr_stackModelURL
{
	return stackModelURL;
}
+ (void)setStackModelURL:(NSURL *)URL
{
	stackModelURL = URL;
	[self mr_cleanUp];
}

+ (void)setUpStackWithManagedDocument: (id) managedDocument {
	Class documentClass = NULL;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	documentClass = NSClassFromString(@"UIManagedDocument");
#else
	documentClass = NSClassFromString(@"NSPersistentDocument");
#endif
	NSAssert(documentClass, @"Not available on this OS.");
	NSParameterAssert([managedDocument isKindOfClass:documentClass]);
	[NSManagedObjectModel mr_setDefaultModel: [managedDocument managedObjectModel]];
	[NSPersistentStoreCoordinator mr_setDefaultStoreCoordinator: [[managedDocument managedObjectContext] persistentStoreCoordinator]];
	[NSManagedObjectContext mr_setDefaultContext: [managedDocument managedObjectContext]];
}

+ (NSDictionary *) mr_stackUbiquityOptions
{
	return stackUbiquityOptions;
}
+ (void)setStackUbiquityOptions:(NSDictionary *)dict
{
	stackUbiquityOptions = dict;
	mr_resetStoreCoordinator();
}

+ (void) mr_cleanUp
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
	
	if ([NSManagedObjectContext mr_hasDefaultContext])
		[NSManagedObjectContext mr_setDefaultContext: nil];
	
	if ([NSManagedObjectModel mr_hasDefaultModel])
		[NSManagedObjectModel mr_setDefaultModel: nil];
	
	if ([NSPersistentStoreCoordinator mr_hasDefaultStoreCoordinator]) {
		[NSPersistentStore mr_setDefaultPersistentStore: nil];
		[NSPersistentStoreCoordinator mr_setDefaultStoreCoordinator: nil];		
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
		
	if (![self mr_stackUbiquityOptions].count)
		return NO;
	
	return stackShouldUseUbiquity;
}

+ (void)setUbiquityEnabled:(BOOL)enabled {
	if (stackShouldUseUbiquity == enabled)
		return;
	
	stackShouldUseUbiquity = enabled;
	
	if (![self mr_stackUbiquityOptions])
		[self setUbiquitousContainer:nil contentNameKey:nil cloudStorePathComponent:nil];
	
	if (![NSPersistentStoreCoordinator mr_hasDefaultStoreCoordinator])
		return;
	
	NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	
	if ([NSManagedObjectContext mr_hasDefaultContext]) {
		NSManagedObjectContext *moc = [NSManagedObjectContext defaultContext];
		if (enabled)
			[moc startObservingUbiquitousChangesInCoordinator:psc];
		else
			[moc stopObservingUbiquitousChangesInCoordinator:psc];
	}
	
	[psc mr_setUbiquityEnabled:enabled];
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
	
	void (^block)(NSError *) = [self errorHandler];
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

+ (void (^)(NSError *)) errorHandler
{
	return errorHandlerBlock;
}
+ (void) setErrorHandler: (void (^)(NSError *)) block
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

+ (void) saveDataWithBlock: (void (^)(NSManagedObjectContext *)) block
{   
    [self saveDataWithOptions: MRCoreDataSaveOptionsNone block: block success: NULL failure: NULL];
}

+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block
{
    [self saveDataWithOptions: MRCoreDataSaveOptionsBackground block: block success: NULL failure: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback
{
    [self saveDataWithOptions: MRCoreDataSaveOptionsBackground block: block success: callback failure: NULL];
}

+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block
{
    [self saveDataWithOptions: options block: block success: NULL failure: NULL];
}
+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block success: (void (^)(void)) callback failure: (void (^)(NSError *)) errorCallback
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
		queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
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
