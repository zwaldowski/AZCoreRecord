//
//  MagicalRecord.h
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#ifdef MR_LOGGING
	#define ARLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#else
	#define ARLog(...)
#endif

typedef void (^MRContextBlock)(NSManagedObjectContext *);
typedef void (^MRBlock)(void);
typedef void (^MRErrorBlock)(NSError *);
typedef enum {
	MRCoreDataSaveOptionNone			   = 0,
	MRCoreDataSaveOptionInBackground	   = 1 << 0,
	MRCoreDataSaveOptionWithNewContext	 = 1 << 1
} MRCoreDataSaveOption;

@protocol MRErrorHandler <NSObject>
@optional
- (void)handleErrors:(NSError *)error;
+ (void)handleErrors:(NSError *)error;
@end

@interface MagicalRecord : NSObject

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName;
+ (void) setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL;
+ (void) setupAutoMigratingCoreDataStack;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;
+ (void) setupCoreDataStackWithInMemoryStore;

+ (void) cleanUp;

+ (void) handleErrors:(NSError *)error;

+ (void)setErrorHandler:(MRErrorBlock)block;
+ (MRErrorBlock)errorHandler;

+ (void)setErrorHandlerTarget:(id <MRErrorHandler>)target;
+ (id <MRErrorHandler>)errorHandlerTarget;

/** @name Data commit */

+ (void) saveDataWithBlock:(MRContextBlock)block;
+ (void) saveDataWithBlock:(MRContextBlock)block errorHandler:(MRErrorBlock)errorHandler;

+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block;
+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block completion:(MRBlock)callback;
+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block completion:(MRBlock)callback errorHandler:(MRErrorBlock)errorHandler;

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block;
+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block success:(MRBlock)callback;
+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block success:(MRBlock)callback failure:(MRErrorBlock)errorCallback;

@end

@compatibility_alias MagicalRecordHelpers MagicalRecord;
@compatibility_alias MRCoreDataAction MagicalRecord;