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

static void *kErrorHandlerTargetKey;
static void *kErrorHandlerIsClassKey;
static void *kErrorHandlerBlockKey;

@implementation MagicalRecord

#pragma mark - Stack Setup

+ (void) setModelName: (NSString *) modelName
{
	NSAssert1(![NSManagedObjectModel _hasDefaultManagedObjectModel], @"%s must be run before the default managed object model is created", sel_getName(_cmd));
	NSManagedObjectModel *model = [NSManagedObjectModel newManagedObjectModelNamed: modelName];
	[NSManagedObjectModel _setDefaultManagedObjectModel: model];
}
+ (void) setModelURL: (NSURL *) modelURL
{
	NSAssert1(![NSManagedObjectModel _hasDefaultManagedObjectModel], @"%s must be run before the default managed object model is created", sel_getName(_cmd));
	NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
	[NSManagedObjectModel _setDefaultManagedObjectModel: model];
}

+ (void) setupAutoMigratingCoreDataStack
{
	[self setupCoreDataStackWithAutoMigratingSqliteStoreNamed: kMagicalRecordDefaultStoreFileName];
}
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreAtURL: storeURL];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: coordinator];
}
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed: (NSString *) storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreNamed: storeName];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: coordinator];
}
+ (void) setupCoreDataStackWithInMemoryStore
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithInMemoryStore];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: coordinator];
}
+ (void) setupCoreDataStackWithStoreAtURL: (NSURL *) storeURL
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreAtURL: storeURL];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: coordinator];
}
+ (void) setupCoreDataStackWithStoreNamed: (NSString *) storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreNamed: storeName];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: coordinator];
}

+ (void) cleanUp
{
	[self _cleanUp];
}
+ (void) _cleanUp
{
	objc_removeAssociatedObjects(self);
	[NSManagedObjectContext _setDefaultContext: nil];
	[NSManagedObjectModel _setDefaultManagedObjectModel: nil];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator: nil];
	[NSPersistentStore _setDefaultPersistentStore: nil];
}

#pragma mark - Error Handling

+ (NSString *) currentStack
{
	NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];
	
	[status appendFormat: @"Context:     %@\n", [NSManagedObjectContext defaultContext]];
	[status appendFormat: @"Model:       %@\n", [NSManagedObjectModel defaultManagedObjectModel]];
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
	ARLog(@"Error: %@", error);
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
	
	dispatch_queue_t queue = nil;
	if (wantsBackground)
	{
		static dispatch_once_t once;
		static dispatch_queue_t MRBackgroundSaveQueue;
		dispatch_once(&once, ^{
			MRBackgroundSaveQueue = dispatch_queue_create("com.magicalpanda.magicalrecord.backgroundsaves", 0);
		});
		
		queue = MRBackgroundSaveQueue;
	}
	else
	{
		queue = dispatch_get_current_queue();
	}
	
	dispatch_async(queue, ^{
		NSManagedObjectContext *mainContext  = [NSManagedObjectContext defaultContext];
		NSManagedObjectContext *localContext = mainContext;
		
		id bkpMergyPolicy = mainContext.mergePolicy;
		
		if (!wantsBackground || wantsNewContext) {
			localContext = [NSManagedObjectContext contextThatNotifiesDefaultContextOnMainThread];
			
			mainContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			localContext.mergePolicy = NSOverwriteMergePolicy;
		}
		
		block(localContext);
		
		if (localContext.hasChanges)
		{
			// -[NSManagedObjectContext saveWithErrorHandler:] handles a NULL block
			[localContext saveWithErrorHandler: errorCallback];
		}
		
		localContext.notifiesMainContextOnSave = NO;
		mainContext.mergePolicy = bkpMergyPolicy;
		
		if (callback)
			dispatch_async(dispatch_get_main_queue(), callback);
	});
}

@end
