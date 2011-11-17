//
//  MagicalRecord.h
//  Magical Record
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#if __has_attribute(deprecated)
	#define DEPRECATED_ATTRIBUTE_M(...) __attribute__((deprecated(__VA_ARGS__)))
#else
	#define DEPRECATED_ATTRIBUTE_M(...) DEPRECATED_ATTRIBUTE
#endif

#ifdef MR_LOGGING
	#define ARLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat: __VA_ARGS__])
#else
	#define ARLog(...)
#endif

typedef void (^MRBlock)(void);
typedef void (^MRContextBlock)(NSManagedObjectContext *);
typedef void (^MRErrorBlock)(NSError *);

typedef enum {
	MRCoreDataSaveOptionNone			= 0,
	MRCoreDataSaveOptionInBackground	= 1 << 0,
	MRCoreDataSaveOptionWithNewContext	= 1 << 1
} MRCoreDataSaveOption;

@protocol MRErrorHandler <NSObject>
@optional

- (void) handleError: (NSError *) error;
+ (void) handleError: (NSError *) error;

@end

@interface MagicalRecord : NSObject

#pragma mark - Stack Setup

+ (void) setModelName: (NSString *) modelName;
+ (void) setModelURL: (NSURL *) modelURL;

+ (void) setupAutoMigratingCoreDataStack;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed: (NSString *) storeName;
+ (void) setupCoreDataStackWithInMemoryStore;
+ (void) setupCoreDataStackWithStoreAtURL: (NSURL *) storeURL;
+ (void) setupCoreDataStackWithStoreNamed: (NSString *) storeName;

+ (void) cleanUp DEPRECATED_ATTRIBUTE_M("Your app will do this automatically on exit.");

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error;
+ (void) handleErrors: (NSError *) error DEPRECATED_ATTRIBUTE;

+ (MRErrorBlock) errorHandler;
+ (void) setErrorHandler: (MRErrorBlock) block;

+ (id<MRErrorHandler>) errorHandlerTarget;
+ (void) setErrorHandlerTarget: (id<MRErrorHandler>) target;

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (MRContextBlock) block;

+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block;
+ (void) saveDataInBackgroundWithBlock: (MRContextBlock) block completion: (MRBlock) callback;

+ (void) saveDataWithOptions: (MRCoreDataSaveOption) options block: (MRContextBlock) block;
+ (void) saveDataWithOptions: (MRCoreDataSaveOption) options block: (MRContextBlock) block success: (MRBlock) callback;
+ (void) saveDataWithOptions: (MRCoreDataSaveOption) options block: (MRContextBlock) block success: (MRBlock) callback failure: (MRErrorBlock) errorCallback;

@end

@compatibility_alias MagicalRecordHelpers MagicalRecord;
@compatibility_alias MRCoreDataAction MagicalRecord;
