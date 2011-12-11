//
//  Magical Record for Core Data
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import <CoreData/CoreData.h>

typedef void (^MRBlock)(void);
typedef void (^MRContextBlock)(NSManagedObjectContext *);
typedef void (^MRErrorBlock)(NSError *);

#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "NSManagedObjectModel+MagicalRecord.h"
#import "NSPersistentStore+MagicalRecord.h"
#import "NSManagedObject+MagicalDataImport.h"

#if __has_attribute(deprecated)
	#define DEPRECATED_ATTRIBUTE_M(...) __attribute__((deprecated(__VA_ARGS__)))
#else
	#define DEPRECATED_ATTRIBUTE_M(...) DEPRECATED_ATTRIBUTE
#endif

#ifdef MR_LOGGING
	#define MRLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat: __VA_ARGS__])
#else
	#define MRLog(...)
#endif

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

#pragma mark - Stack settings

+ (void)setStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
+ (void)setStackShouldUseInMemoryStore: (BOOL) inMemory;
+ (void)setStackStoreName: (NSString *) name;
+ (void)setStackStoreURL: (NSURL *) name;
+ (void)setStackModelName: (NSString *) name;
+ (void)setStackModelURL: (NSURL *) name;

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error;

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

#pragma mark Deprecated

+ (void) cleanUp DEPRECATED_ATTRIBUTE_M("Your app will do this automatically on exit.");

+ (void) handleErrors: (NSError *) error DEPRECATED_ATTRIBUTE;

+ (void) setupAutoMigratingCoreDataStack DEPRECATED_ATTRIBUTE_M("Use +[MagicalRecord setStackShouldAutoMigrateStore:] instead");
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL: (NSURL *) storeURL DEPRECATED_ATTRIBUTE_M("Use +[MagicalRecord setStackShouldAutoMigrateStore:] and +[MagicalRecord setStackStoreURL:] instead");
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed: (NSString *) storeName DEPRECATED_ATTRIBUTE_M("Use  +[MagicalRecord setStackShouldAutoMigrateStore:] and +[MagicalRecord setStackStoreName:] instead");
+ (void) setupCoreDataStackWithInMemoryStore DEPRECATED_ATTRIBUTE_M("Use +[MagicalRecord setStackShouldUseInMemoryStore:] instead");
+ (void) setupCoreDataStackWithStoreAtURL: (NSURL *) storeURL DEPRECATED_ATTRIBUTE_M("Use +[MagicalRecord setStackStoreURL:]");
+ (void) setupCoreDataStackWithStoreNamed: (NSString *) storeName DEPRECATED_ATTRIBUTE_M("Use +[MagicalRecord setStackStoreName:]");

@end

@compatibility_alias MagicalRecordHelpers MagicalRecord;
@compatibility_alias MRCoreDataAction MagicalRecord;
