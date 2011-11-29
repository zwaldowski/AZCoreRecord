//
//  MagicalRecord.m
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import "MagicalRecord.h"
#import "MagicalRecord+Private.h"
#import <objc/runtime.h>

static dispatch_queue_t backgroundQueue = nil;

static void *kErrorHandlerTargetKey;
static void *kErrorHandlerIsClassKey;
static void *kErrorHandlerBlockKey;

static void *kStackShouldAutoMigrateKey;
static void *kStackShouldUseInMemoryStoreKey;
static void *kStackStoreNameKey;
static void *kStackStoreURLKey;
static void *kStackModelNameKey;
static void *kStackModelURLKey;

dispatch_queue_t mr_get_background_queue(void)
{
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		backgroundQueue = dispatch_queue_create("com.magicalpanda.MagicalRecord.backgroundQueue", 0);
	});
	
	return backgroundQueue;
}

IMP mr_getSupersequent(id obj, SEL selector)
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
	return [objc_getAssociatedObject(self, &kStackShouldAutoMigrateKey) boolValue];
}
+ (void)setStackShouldAutoMigrateStore:(BOOL)shouldMigrate
{
	objc_setAssociatedObject(self, &kStackShouldAutoMigrateKey, [NSNumber numberWithBool:shouldMigrate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);	
	reset_storeCoordinator();
}

+ (BOOL)_stackShouldUseInMemoryStore
{
	return [objc_getAssociatedObject(self, &kStackShouldUseInMemoryStoreKey) boolValue];
}
+ (void)setStackShouldUseInMemoryStore:(BOOL)inMemory
{
	objc_setAssociatedObject(self, &kStackShouldUseInMemoryStoreKey, [NSNumber numberWithBool:inMemory], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	reset_storeCoordinator();
}

+ (NSString *)_stackStoreName
{
	return objc_getAssociatedObject(self, &kStackStoreNameKey);
}
+ (void)setStackStoreName:(NSString *)name
{
	objc_setAssociatedObject(self, &kStackStoreNameKey, name, OBJC_ASSOCIATION_COPY_NONATOMIC);
	reset_storeCoordinator();
}

+ (NSURL *)_stackStoreURL
{
	return objc_getAssociatedObject(self, &kStackStoreURLKey);
}
+ (void)setStackStoreURL:(NSURL *)name
{
	objc_setAssociatedObject(self, &kStackStoreURLKey, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	reset_storeCoordinator();
}

+ (NSString *)_stackModelName
{
	return objc_getAssociatedObject(self, &kStackModelNameKey);
}
+ (void)setStackModelName:(NSString *)name
{
	objc_setAssociatedObject(self, &kStackModelNameKey, name, OBJC_ASSOCIATION_COPY_NONATOMIC);
	[self _cleanUp];
}

+ (NSURL *)_stackModelURL
{
	return objc_getAssociatedObject(self, &kStackModelURLKey);
}
+ (void)setStackModelURL:(NSURL *)name
{
	objc_setAssociatedObject(self, &kStackModelURLKey, name, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	[self _cleanUp];
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
	objc_removeAssociatedObjects(self);
	if (backgroundQueue) dispatch_release(backgroundQueue), backgroundQueue = nil;
	
	[NSManagedObjectContext _setDefaultContext: nil];
	[NSManagedObjectModel _setDefaultModel: nil];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: nil];
	[NSPersistentStore _setDefaultPersistentStore: nil];
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
		BOOL isClassSelector = [objc_getAssociatedObject(self, &kErrorHandlerIsClassKey) boolValue];
		[(isClassSelector ? [target class] : target) performSelector: @selector(handleError:) withObject: error];
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
	return objc_getAssociatedObject(self, &kErrorHandlerBlockKey);
}
+ (void) setErrorHandler: (MRErrorBlock) block
{
	objc_setAssociatedObject(self, &kErrorHandlerBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (id<MRErrorHandler>) errorHandlerTarget
{
	return objc_getAssociatedObject(self, &kErrorHandlerTargetKey);
}
+ (void) setErrorHandlerTarget: (id<MRErrorHandler>) target
{
	NSNumber *isClassMethodNumber = nil;
	
	if (target)
	{
		if ([target respondsToSelector: @selector(handleError:)])
			isClassMethodNumber = [NSNumber numberWithBool: NO];
		else if ([[target class] respondsToSelector: @selector(handleError:)])
			isClassMethodNumber = [NSNumber numberWithBool: YES];
		else
			NSAssert(NO, @"Error handler target must conform to the MRErrorHandler protocol");
	}
	
	objc_setAssociatedObject(self, &kErrorHandlerIsClassKey, isClassMethodNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(self, &kErrorHandlerTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (MRContextBlock) block
{   
    [self saveDataWithOptions: MRCoreDataSaveOptionNone block: block success: NULL failure: NULL];
}

+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block
{
    [self saveDataWithOptions: MRCoreDataSaveOptionInBackground block: block success: NULL failure: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block completion: (MRBlock) callback
{
    [self saveDataWithOptions: MRCoreDataSaveOptionInBackground block: block success: callback failure: NULL];
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
	NSParameterAssert(block);
	
	BOOL wantsBackground = (options & MRCoreDataSaveOptionInBackground);
	BOOL wantsNewContext = (options & MRCoreDataSaveOptionWithNewContext) || ![NSThread isMainThread];
	
	dispatch_queue_t queue = (wantsBackground) ? mr_get_background_queue() : dispatch_get_current_queue();
	dispatch_async(queue, ^{
		NSManagedObjectContext *mainContext  = [NSManagedObjectContext defaultContext];
		NSManagedObjectContext *localContext = mainContext;
		
		id bkpMergyPolicy = mainContext.mergePolicy;
		
		if (!wantsBackground || wantsNewContext) {
			localContext = [[self defaultContext] newChildContext];
			
			mainContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			localContext.mergePolicy = NSOverwriteMergePolicy;
		}
		
		block(localContext);
		
		if (localContext.hasChanges)
		{
			// -[NSManagedObjectContext saveWithErrorHandler:] handles a NULL block
			[localContext saveWithErrorHandler: errorCallback];
		}
		
		mainContext.mergePolicy = bkpMergyPolicy;
		
		if (callback) dispatch_async(dispatch_get_main_queue(), callback);
	});
}

@end
