//
//  AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecord+Private.h"
#import <objc/runtime.h>

#if __has_feature(objc_arc_weak)
static __weak id <AZCoreRecordErrorHandler> errorHandlerTarget = nil;
#else
static __unsafe_unretained id <AZCoreRecordErrorHandler> errorHandlerTarget = nil;
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

extern void azcr_swizzle_support(Class cls, SEL oldSel, SEL newSel) {
	Method origMethod = class_getInstanceMethod(cls, oldSel);
	Method newMethod = class_getInstanceMethod(cls, newSel);
	
	if (class_addMethod(cls, oldSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(cls, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

@implementation AZCoreRecord

#pragma mark - Stack settings

static void azcr_resetStoreCoordinator(void) {
	if ([NSPersistentStoreCoordinator azcr_hasDefaultStoreCoordinator])
		[NSPersistentStoreCoordinator azcr_setDefaultStoreCoordinator:nil];
	if ([NSManagedObjectContext azcr_hasDefaultContext])
		[NSManagedObjectContext azcr_setDefaultContext:nil];
}

+ (BOOL)azcr_stackShouldAutoMigrateStore
{
	return stackShouldAutoMigrate;
}
+ (void)setStackShouldAutoMigrateStore:(BOOL)shouldMigrate
{
	stackShouldAutoMigrate = shouldMigrate;	
	azcr_resetStoreCoordinator();
}

+ (BOOL)azcr_stackShouldUseInMemoryStore
{
	return stackShouldUseInMemoryStore;
}
+ (void)setStackShouldUseInMemoryStore:(BOOL)inMemory
{
	stackShouldUseInMemoryStore = inMemory;
	azcr_resetStoreCoordinator();
}

+ (NSString *)azcr_stackStoreName
{
	if (!stackStoreName.pathExtension)
		return [stackStoreName stringByAppendingPathExtension:@"sqlite"];
	return stackStoreName;
}
+ (void)setStackStoreName:(NSString *)name
{
	stackStoreName = [name copy];
	azcr_resetStoreCoordinator();
}

+ (NSURL *)azcr_stackStoreURL
{
	return stackStoreURL;
}
+ (void)setStackStoreURL:(NSURL *)URL
{
	stackStoreURL = URL;
	azcr_resetStoreCoordinator();
}

+ (NSString *)azcr_stackModelName
{
	return stackModelName;
}
+ (void)setStackModelName:(NSString *)name
{
	stackModelName = [name copy];
	[self azcr_cleanUp];
}

+ (NSURL *)azcr_stackModelURL
{
	return stackModelURL;
}
+ (void)setStackModelURL:(NSURL *)URL
{
	stackModelURL = URL;
	[self azcr_cleanUp];
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
	[NSManagedObjectModel azcr_setDefaultModel: [managedDocument managedObjectModel]];
	[NSPersistentStoreCoordinator azcr_setDefaultStoreCoordinator: [[managedDocument managedObjectContext] persistentStoreCoordinator]];
	[NSManagedObjectContext azcr_setDefaultContext: [managedDocument managedObjectContext]];
}

+ (NSDictionary *) azcr_stackUbiquityOptions
{
	return stackUbiquityOptions;
}
+ (void)setStackUbiquityOptions:(NSDictionary *)dict
{
	stackUbiquityOptions = dict;
	azcr_resetStoreCoordinator();
}

+ (void) azcr_cleanUp
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
	
	if ([NSManagedObjectContext azcr_hasDefaultContext])
		[NSManagedObjectContext azcr_setDefaultContext: nil];
	
	if ([NSManagedObjectModel azcr_hasDefaultModel])
		[NSManagedObjectModel azcr_setDefaultModel: nil];
	
	if ([NSPersistentStoreCoordinator azcr_hasDefaultStoreCoordinator]) {
		[NSPersistentStore azcr_setDefaultPersistentStore: nil];
		[NSPersistentStoreCoordinator azcr_setDefaultStoreCoordinator: nil];		
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
		
	if (![self azcr_stackUbiquityOptions].count)
		return NO;
	
	return stackShouldUseUbiquity;
}

+ (void)setUbiquityEnabled:(BOOL)enabled {
	if (stackShouldUseUbiquity == enabled)
		return;
	
	stackShouldUseUbiquity = enabled;
	
	if (![self azcr_stackUbiquityOptions])
		[self setUbiquitousContainer:nil contentNameKey:nil cloudStorePathComponent:nil];
	
	if (![NSPersistentStoreCoordinator azcr_hasDefaultStoreCoordinator])
		return;
	
	NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	
	if ([NSManagedObjectContext azcr_hasDefaultContext]) {
		NSManagedObjectContext *moc = [NSManagedObjectContext defaultContext];
		if (enabled)
			[moc startObservingUbiquitousChangesInCoordinator:psc];
		else
			[moc stopObservingUbiquitousChangesInCoordinator:psc];
	}
	
	[psc azcr_setUbiquityEnabled:enabled];
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
}

+ (void (^)(NSError *)) errorHandler
{
	return errorHandlerBlock;
}
+ (void) setErrorHandler: (void (^)(NSError *)) block
{
	errorHandlerBlock = [block copy];
}

+ (id<AZCoreRecordErrorHandler>) errorHandlerTarget
{
	return errorHandlerTarget;
}
+ (void) setErrorHandlerTarget: (id<AZCoreRecordErrorHandler>) target
{	
	if (target)
	{
		if ([target respondsToSelector: @selector(handleError:)])
			errorHandlerIsClassMethod = NO;
		else if ([[target class] respondsToSelector: @selector(handleError:)])
			errorHandlerIsClassMethod = YES;
		else
			NSAssert(NO, @"Error handler target must conform to the AZCoreRecordErrorHandler protocol");
	}
	
	errorHandlerTarget = target;
}

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (void (^)(NSManagedObjectContext *)) block
{   
    [self saveDataWithOptions: AZCoreRecordSaveOptionsNone block: block success: NULL failure: NULL];
}

+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block
{
    [self saveDataWithOptions: AZCoreRecordSaveOptionsBackground block: block success: NULL failure: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback
{
    [self saveDataWithOptions: AZCoreRecordSaveOptionsBackground block: block success: callback failure: NULL];
}

+ (void) saveDataWithOptions: (AZCoreRecordSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block
{
    [self saveDataWithOptions: options block: block success: NULL failure: NULL];
}
+ (void) saveDataWithOptions: (AZCoreRecordSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block success: (void (^)(void)) callback failure: (void (^)(NSError *)) errorCallback
{
	BOOL wantsBackground = (options & AZCoreRecordSaveOptionsBackground);
	BOOL wantsMainThread = (options & AZCoreRecordSaveOptionsMainThread);
	
	NSParameterAssert(block);
	NSParameterAssert(!(wantsBackground && wantsMainThread));
	
	BOOL wantsAsync		 = (options & AZCoreRecordSaveOptionsAsynchronous);
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
