//
//  Magical Record for Core Data
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import <CoreData/CoreData.h>

#if defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && defined(__IPHONE_5_0)
#import <UIKit/UIManagedDocument.h>
#endif

typedef void (^MRBlock)(void);
typedef void (^MRContextBlock)(NSManagedObjectContext *);
typedef void (^MRErrorBlock)(NSError *);

#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "NSManagedObjectModel+MagicalRecord.h"
#import "NSPersistentStore+MagicalRecord.h"
#import "NSManagedObject+MagicalDataImport.h"

#ifdef MR_LOGGING
	#define MRLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat: __VA_ARGS__])
#else
	#define MRLog(...)
#endif

typedef enum {
	MRCoreDataSaveOptionsNone			= 0,
	MRCoreDataSaveOptionsBackground		= 1 << 0,
	MRCoreDataSaveOptionsMainThread		= 1 << 1,
	MRCoreDataSaveOptionsAsynchronous	= 1 << 2
} MRCoreDataSaveOptions;

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

#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && defined(__MAC_10_4)
+ (void)setUpStackWithManagedDocument: (NSPersistentDocument *) managedDocument NS_AVAILABLE_MAC(10_4)
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED) && defined(__IPHONE_5_0)
+ (void)setUpStackWithManagedDocument: (UIManagedDocument *) managedDocument NS_AVAILABLE_IOS(5_0);
#endif

#pragma mark - Ubiquity Support

+ (BOOL)supportsUbiquity;

+ (void)setUbiquityEnabled:(BOOL)enabled;
+ (BOOL)isUbiquityEnabled;

+ (void)setUbiquitousContainer:(NSString *)containerID contentNameKey:(NSString *)key cloudStorePathComponent:(NSString *)pathComponent;

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

+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (MRContextBlock) block;
+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (MRContextBlock) block success: (MRBlock) callback;
+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (MRContextBlock) block success: (MRBlock) callback failure: (MRErrorBlock) errorCallback;

@end