//
//  MagicalRecordHelpers.m
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import "MagicalRecord+Private.h"
#import <objc/runtime.h>

void ARLog(NSString *format, ...) {
#ifdef MR_LOGGING
    va_list arguments;
    va_start(arguments, format);
    NSString *log = [[NSString alloc] initWithFormat:format arguments:arguments];
    NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, log);
    va_end(arguments);
#endif
}

static const char *kErrorHandlerTargetKey = "errorHandlerTarget_";
static const char *kErrorHandlerIsClassKey = "errorHandlerIsClass_";
static const char *kErrorHandlerBlockKey = "errorHandler_";

@implementation MagicalRecordHelpers

+ (void) cleanUp
{
	objc_removeAssociatedObjects(self);
	[NSManagedObjectContext _setDefaultContext:nil];
	[NSManagedObjectModel _setDefaultManagedObjectModel:nil];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:nil];
	[NSPersistentStore _setDefaultPersistentStore:nil];
}

+ (NSString *) currentStack
{
	NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];
	
	[status appendFormat:@"Context:	 %@\n", [NSManagedObjectContext defaultContext]];
	[status appendFormat:@"Model:	   %@\n", [NSManagedObjectModel defaultManagedObjectModel]];
	[status appendFormat:@"Coordinator: %@\n", [NSPersistentStoreCoordinator defaultStoreCoordinator]];
	[status appendFormat:@"Store:	   %@\n", [NSPersistentStore defaultPersistentStore]];
	
	return status;
}

+ (void)handleError:(NSError *)error
{
	if (!error)
		return;
	
	id target = [self errorHandlerTarget];
	MRErrorBlock block = [self errorHandler];
	
	if (block) {
		block(error);
		return;
	}
	
	if (target) {
		BOOL isClassSelector = [objc_getAssociatedObject(self, kErrorHandlerIsClassKey) boolValue];
		[(isClassSelector ? [target class] : target) performSelector:@selector(handleError:) withObject:error];
		return;
	}
	
	// default error handler
	for (NSArray *detailedError in error.userInfo.allValues) {
		ARLog(@"Error: %@", detailedError);
	}
	ARLog(@"Error Domain: %@", [error domain]);
	ARLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

+ (void)handleErrors:(NSError *)error {
    [self handleError:error];
}

+ (void)setErrorHandler:(MRErrorBlock)block
{
	objc_setAssociatedObject(self, kErrorHandlerBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (MRErrorBlock)errorHandler
{
	return objc_getAssociatedObject(self, kErrorHandlerBlockKey);
}

+ (id <MRErrorHandler>) errorHandlerTarget
{
	return objc_getAssociatedObject(self, kErrorHandlerTargetKey);
}

+ (void) setErrorHandlerTarget:(id <MRErrorHandler>)target
{
	NSNumber *isClassMethodNumber = nil;
	if ([target respondsToSelector:@selector(handleError:)])
		isClassMethodNumber = [NSNumber numberWithBool:NO];
	else if ([[target class] respondsToSelector:@selector(handleError:)])
		isClassMethodNumber = [NSNumber numberWithBool:YES];
	objc_setAssociatedObject(self, kErrorHandlerIsClassKey, isClassMethodNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(self, kErrorHandlerTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void) setupAutoMigratingCoreDataStack
{
	[self setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kMagicalRecordDefaultStoreFileName];
}

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreNamed:storeName];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreAtURL:storeURL];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreNamed:storeName];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreAtURL:storeURL];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithInMemoryStore
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithInMemoryStore];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

#pragma mark - Core Data actions

+ (void) saveDataWithBlock:(MRContextBlock)block {   
    [self saveDataWithOptions:MRCoreDataSaveOptionNone block:block success:NULL failure:NULL];
}

+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block {
    [self saveDataWithOptions:MRCoreDataSaveOptionInBackground block:block success:NULL failure:NULL];
}

+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block completion:(MRBlock)callback {
    [self saveDataWithOptions:MRCoreDataSaveOptionInBackground block:block success:callback failure:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block {
    [self saveDataWithOptions:options block:block success:NULL failure:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block success:(MRBlock)callback {
    [self saveDataWithOptions:options block:block success:callback failure:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block success:(MRBlock)callback failure:(MRErrorBlock)errorCallback {
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
		
		if (!wantsBackground || wantsNewContext) {
			localContext = [NSManagedObjectContext contextThatNotifiesDefaultContextOnMainThread];
			
			[mainContext setMergePolicy:NSMergeByPropertyStoreTrumpMergePolicy];
			[localContext setMergePolicy:NSOverwriteMergePolicy];
		}
		
		block(localContext);
		
		if (localContext.hasChanges)
			[localContext saveWithErrorHandler:errorCallback];
		
		localContext.notifiesMainContextOnSave = NO;
		[mainContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
		
		if (callback)
			dispatch_async(dispatch_get_main_queue(), callback);
	});
}

@end