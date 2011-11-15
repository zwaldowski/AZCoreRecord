//
//  MRCoreDataAction.m
//  MagicalRecord
//
//  Created by Saul Mora on 2/24/11.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "MRCoreDataAction.h"

@implementation MRCoreDataAction

+ (void) saveDataWithBlock:(void(^)(NSManagedObjectContext *))block
{   
	[self saveDataWithOptions:MRCoreDataSaveOptionNone withBlock:block completion:NULL errorHandler:NULL];
}

+ (void) saveDataWithBlock:(void (^)(NSManagedObjectContext *))block errorHandler:(void (^)(NSError *))errorHandler
{
	[self saveDataWithOptions:MRCoreDataSaveOptionNone withBlock:block completion:NULL errorHandler:errorHandler];
}

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *))block
{
	[self saveDataWithOptions:MRCoreDataSaveOptionInBackground withBlock:block completion:NULL errorHandler:NULL];
}

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *))block completion:(void(^)())callback
{
	[self saveDataWithOptions:MRCoreDataSaveOptionInBackground withBlock:block completion:callback errorHandler:NULL];
}

+ (void) saveDataInBackgroundWithBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)())callback errorHandler:(void (^)(NSError *))errorHandler
{
	[self saveDataWithOptions:MRCoreDataSaveOptionInBackground withBlock:block completion:callback errorHandler:errorHandler];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *))block;
{
	[self saveDataWithOptions:options withBlock:block completion:NULL errorHandler:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *))block completion:(void(^)(void))callback;
{
	[self saveDataWithOptions:options withBlock:block completion:callback errorHandler:NULL];
}

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)(void))callback errorHandler:(void(^)(NSError *))errorCallback
{
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