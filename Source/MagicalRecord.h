//
//  MagicalRecord.h
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#if ((defined(__GNUC__) && ((__GNUC__ >= 4) || (__GNUC__ >= 5))) || defined(__clang__))
#define DEPRECATED_ATTRIBUTE_M(...) __attribute__((deprecated (__VA_ARGS__)))
#else
#define DEPRECATED_ATTRIBUTE_M(...) DEPRECATED_ATTRIBUTE
#endif

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
- (void)handleError:(NSError *)error;
+ (void)handleError:(NSError *)error;
@end

@interface MagicalRecord : NSObject

+ (void)setDefaultModelName:(NSString *)modelName;

+ (void)setupCoreDataStackWithStoreNamed:(NSString *)storeName;
+ (void)setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL;
+ (void)setupAutoMigratingCoreDataStack;
+ (void)setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;
+ (void)setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL;
+ (void)setupCoreDataStackWithInMemoryStore;

+ (void)cleanUp DEPRECATED_ATTRIBUTE_M("Your app will do this automatically on exit.");

+ (void)handleError:(NSError *)error;
+ (void)handleErrors:(NSError *)error DEPRECATED_ATTRIBUTE;

+ (void)setErrorHandler:(MRErrorBlock)block;
+ (MRErrorBlock)errorHandler;

+ (void)setErrorHandlerTarget:(id <MRErrorHandler>)target;
+ (id <MRErrorHandler>)errorHandlerTarget;

/** @name Data commit */

+ (void) saveDataWithBlock:(MRContextBlock)block;

+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block;
+ (void) saveDataInBackgroundWithBlock:(MRContextBlock)block completion:(MRBlock)callback;

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block;
+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block success:(MRBlock)callback;
+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options block:(MRContextBlock)block success:(MRBlock)callback failure:(MRErrorBlock)errorCallback;

@end

@compatibility_alias MagicalRecordHelpers MagicalRecord;
@compatibility_alias MRCoreDataAction MagicalRecord;