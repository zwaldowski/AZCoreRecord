//
//  Magical Record for Core Data
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "NSManagedObjectModel+MagicalRecord.h"
#import "NSPersistentStore+MagicalRecord.h"
#import "NSManagedObject+MagicalDataImport.h"
#import "NSFetchedResultsController+MagicalRecord.h"

#ifdef MR_LOGGING
	#define MRLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat: __VA_ARGS__])
#else
	#define MRLog(...)
#endif

typedef enum {
	MRCoreDataSaveOptionsNone			= 0,
	MRCoreDataSaveOptionsBackground		= 1 << 0,
	MRCoreDataSaveOptionsMainThread		= 1 << 1,
	MRCoreDataSaveOptionsAsynchronous		= 1 << 2
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

+ (void)setUpStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Ubiquity Support

+ (BOOL)supportsUbiquity;

+ (void)setUbiquityEnabled: (BOOL) enabled;
+ (BOOL)isUbiquityEnabled;

+ (void)setUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent;

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error;

+ (void (^)(NSError *)) errorHandler;
+ (void) setErrorHandler: (void (^)(NSError *)) block;

+ (id<MRErrorHandler>) errorHandlerTarget;
+ (void) setErrorHandlerTarget: (id<MRErrorHandler>) target;

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *)) block;

+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block;
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback;

+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block;
+ (void) saveDataWithOptions: (MRCoreDataSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block success: (void (^)(void)) callback failure: (void (^)(NSError *)) errorCallback;

@end