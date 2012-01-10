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

IMP _mr_getSupersequent(id obj, SEL selector)
{
	BOOL found = NO;
	
	NSUInteger returnAddress = (NSUInteger) __builtin_return_address(0);
	NSUInteger closest = 0;
	
	// Iterate over the class and all superclasses
	Class currentClass = object_getClass(obj);
	while (currentClass)
	{
		// Iterate over all instance methods for this class
		unsigned int methodCount;
		Method *methodList = class_copyMethodList(currentClass, &methodCount);
		
		for (unsigned int i = 0; i < methodCount; i++)
		{
			// Ignore methods with different selectors
			if (method_getName(methodList[i]) != selector)
				continue;
			
			// If this address is closer, use it instead
			NSUInteger address = (NSUInteger) method_getImplementation(methodList[i]);
			if (address < returnAddress && address > closest)
			{
				closest = address;
			}
		}
		
		free(methodList);
		currentClass = class_getSuperclass(currentClass);
	}
	
	IMP skip = (IMP) closest;
	
    currentClass = object_getClass(obj);
    while (currentClass)
    {
        // Get the list of methods for this class
        unsigned int methodCount;
        Method *methodList = class_copyMethodList(currentClass, &methodCount);
		
        // Iterate over all methods
        for (unsigned int i = 0; i < methodCount; ++i)
        {
            // Look for the selector
            if (method_getName(methodList[i]) != selector)
                continue;
			
            IMP implementation = method_getImplementation(methodList[i]);
			
            // Check if this is the "skip" implementation
            if (implementation == skip)
            {
                found = YES;
            }
            else if (found)
            {
                // Return the match.
                free(methodList);
                return implementation;
            }
        }
		
        // No match found. Traverse up through superclass's methods.
        free(methodList);
		
        currentClass = class_getSuperclass(currentClass);
    }
	
    return nil;
}

extern void _mr_swizzle(Class cls, SEL oldSel, SEL newSel) {
	Method origMethod = class_getInstanceMethod(cls, oldSel);
	Method newMethod = class_getInstanceMethod(cls, newSel);
	
	if (class_addMethod(cls, oldSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(cls, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

@implementation MagicalRecord

#pragma mark - Stack settings

#define reset_storeCoordinator() \
do { \
if ([NSPersistentStoreCoordinator _hasDefaultStoreCoordinator]) \
[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:nil]; \
if ([NSManagedObjectContext _hasDefaultContext]) \
[NSManagedObjectContext _setDefaultContext:nil]; \
} while (0)

+ (BOOL)_stackShouldAutoMigrateStore
{
	return stackShouldAutoMigrate;
}
+ (void)setStackShouldAutoMigrateStore:(BOOL)shouldMigrate
{
	stackShouldAutoMigrate = shouldMigrate;	
	reset_storeCoordinator();
}

+ (BOOL)_stackShouldUseInMemoryStore
{
	return stackShouldUseInMemoryStore;
}
+ (void)setStackShouldUseInMemoryStore:(BOOL)inMemory
{
	stackShouldUseInMemoryStore = inMemory;
	reset_storeCoordinator();
}

+ (NSString *)_stackStoreName
{
	return stackStoreName;
}
+ (void)setStackStoreName:(NSString *)name
{
	stackStoreName = [name copy];
	reset_storeCoordinator();
}

+ (NSURL *)_stackStoreURL
{
	return stackStoreURL;
}
+ (void)setStackStoreURL:(NSURL *)URL
{
	stackStoreURL = URL;
	reset_storeCoordinator();
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

+ (BOOL)_isUbiquityEnabled
{
	return ([stackUbiquityOptions count] > 0 && [NSPersistentStore URLForUbiquitousContainer:nil] != nil);
}

+ (BOOL)_isDocumentBacked
{
	BOOL isManagedDocument = NO;
	NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
	if ([context respondsToSelector:@selector(concurrencyType)]) {
		isManagedDocument = (context.concurrencyType == NSMainQueueConcurrencyType && context.parentContext.concurrencyType == NSPrivateQueueConcurrencyType && !context.parentContext.parentContext);
	}
	return isManagedDocument;
}

+ (void) setupAutoMigratingCoreDataStack
{
	[MagicalRecord setStackShouldAutoMigrateStore:YES];
}
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL
{
	[MagicalRecord setStackShouldAutoMigrateStore:YES];
	[MagicalRecord setStackStoreURL:storeURL];
}
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed: (NSString *) storeName
{
	[MagicalRecord setStackShouldAutoMigrateStore:YES];
	[MagicalRecord setStackStoreName:storeName];
}
+ (void) setupCoreDataStackWithInMemoryStore
{
	[MagicalRecord setStackShouldUseInMemoryStore:YES];
}
+ (void) setupCoreDataStackWithStoreAtURL: (NSURL *) storeURL
{	
	[MagicalRecord setStackStoreURL:storeURL];
}
+ (void) setupCoreDataStackWithStoreNamed: (NSString *) storeName
{
	[MagicalRecord setStackStoreName:storeName];
}

+ (void) cleanUp
{
	[self _cleanUp];
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

+ (void)setUbiquitousContainer:(NSString *)containerID
{
	[self setUbiquitousContainer:containerID contentNameKey:nil cloudStorePathComponent:nil];
}

+ (void)setUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key cloudStorePathComponent:(NSString *)pathComponent
{
	NSURL *cloudURL = [[NSPersistentStore URLForUbiquitousContainer:containerID] URLByAppendingPathComponent:pathComponent];
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
+ (void) handleErrors: (NSError *) error
{
    [self handleError: error];
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
    [self saveDataWithOptions: MRCoreDataSaveOptionNone block: block success: NULL failure: NULL];
}

+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block
{
    [self saveDataWithOptions: MRCoreDataSaveOptionBackground block: block success: NULL failure: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block completion: (MRBlock) callback
{
    [self saveDataWithOptions: MRCoreDataSaveOptionBackground block: block success: callback failure: NULL];
}

+ (void) saveDataWithOptions: (MRCoreDataSaveOption) options block: (MRContextBlock) block
{
    [self saveDataWithOptions: options block: block success: NULL failure: NULL];
}
+ (void) saveDataWithOptions: (MRCoreDataSaveOption) options block: (MRContextBlock) block success: (MRBlock) callback
{
    [self saveDataWithOptions: options block: block success: callback failure:  NULL];
}
+ (void) saveDataWithOptions: (MRCoreDataSaveOption) options block: (MRContextBlock) block success: (MRBlock) callback failure: (MRErrorBlock) errorCallback
{
	BOOL wantsBackground = (options & MRCoreDataSaveOptionBackground);
	BOOL wantsMainThread = (options & MRCoreDataSaveOptionMainThread);
	
	NSParameterAssert(block);
	NSParameterAssert(!(wantsBackground && wantsMainThread));
	
	BOOL wantsAsync		 = (options & MRCoreDataSaveOptionAsynchronous);
	BOOL usesNewContext	 = ![NSThread isMainThread] || !wantsMainThread;
	BOOL usesUbiquity	 = [MagicalRecord _isUbiquityEnabled] && ![MagicalRecord _isDocumentBacked];
	
	dispatch_queue_t callbackBlock = wantsMainThread ? dispatch_get_main_queue() : dispatch_get_current_queue();
	
	dispatch_block_t queueBlock = ^{
		NSManagedObjectContext *defaultContext  = [NSManagedObjectContext defaultContext];
		NSManagedObjectContext *localContext = defaultContext;
		NSPersistentStoreCoordinator *defaultStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
		
		id backupMergePolicy = defaultContext.mergePolicy;
		
		if (usesNewContext)
		{
			localContext = [[NSManagedObjectContext defaultContext] newChildContext];
			if (usesUbiquity)
				[localContext startObservingUbiquitousChangesInCoordinator:defaultStoreCoordinator];
			
			defaultContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			localContext.mergePolicy = NSOverwriteMergePolicy;
		}
		
		block(localContext);
		
		if (localContext.hasChanges)
			[localContext saveWithErrorHandler: errorCallback];
		
		if (usesNewContext && usesUbiquity)
			[localContext stopObservingUbiquitousChangesInCoordinator:defaultStoreCoordinator];
		
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
