//
//  AZCoreRecord.h
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "NSManagedObject+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"
#import "NSPersistentStore+AZCoreRecord.h"
#import "NSManagedObject+AZCoreRecord.h"
#import "NSFetchedResultsController+AZCoreRecord.h"

typedef enum _AZCoreRecordSaveOptions {
	AZCoreRecordSaveOptionsNone			= 0,
	AZCoreRecordSaveOptionsBackground		= 1 << 0,
	AZCoreRecordSaveOptionsMainThread		= 1 << 1,
	AZCoreRecordSaveOptionsAsynchronous		= 1 << 2
} AZCoreRecordSaveOptions;

@protocol AZCoreRecordErrorHandler <NSObject>
@optional

- (void) handleError: (NSError *) error;
+ (void) handleError: (NSError *) error;

@end

@interface AZCoreRecord : NSObject

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

+ (id<AZCoreRecordErrorHandler>) errorHandlerTarget;
+ (void) setErrorHandlerTarget: (id<AZCoreRecordErrorHandler>) target;

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *)) block;

+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block;
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback;

+ (void) saveDataWithOptions: (AZCoreRecordSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block;
+ (void) saveDataWithOptions: (AZCoreRecordSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block success: (void (^)(void)) callback failure: (void (^)(NSError *)) errorCallback;

@end