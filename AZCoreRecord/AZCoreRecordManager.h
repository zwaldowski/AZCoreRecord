//
//  AZCoreRecord.h
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

@protocol AZCoreRecordErrorHandler <NSObject>
@required

- (void) handleError: (NSError *) error;

@end

@interface AZCoreRecordManager : NSObject {
	__weak id <AZCoreRecordErrorHandler> _errorDelegate;	
	void (^_errorHandler)(NSError *);
	
	dispatch_semaphore_t _semaphore;
	
	BOOL _stackShouldAutoMigrate;
	BOOL _stackShouldUseUbiquity;
	BOOL _stackShouldUseInMemoryStore;
	NSString *_stackStoreName;
	NSURL *_stackStoreURL;
	NSString *_stackModelName;
	NSURL *_stackModelURL;
	NSDictionary *_stackUbiquityOptions;
	
	NSManagedObjectContext *_managedObjectContext;
	NSManagedObjectModel *_managedObjectModel;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

+ (AZCoreRecordManager *)sharedManager;

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic) BOOL stackShouldAutoMigrateStore;
@property (nonatomic) BOOL stackShouldUseInMemoryStore;
@property (nonatomic) BOOL stackShouldUseUbiquity;
@property (nonatomic, copy) NSString *stackStoreName;
@property (nonatomic, copy) NSURL *stackStoreURL;
@property (nonatomic, copy) NSString *stackModelName;
@property (nonatomic, copy) NSURL *stackModelURL;

@property (nonatomic, strong, readonly) NSDictionary *stackUbiquityOptions;
- (void) setUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent;

- (void) configureWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Ubiquity Support

+ (void) setDefaultUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent;

@property (nonatomic, getter = isUbiquityEnabled) BOOL ubiquityEnabled;

+ (BOOL) supportsUbiquity;

#pragma mark - Default stack settings

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
+ (void) setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory;
+ (void) setDefaultStackStoreName: (NSString *) name;
+ (void) setDefaultStackStoreURL: (NSURL *) name;
+ (void) setDefaultStackModelName: (NSString *) name;
+ (void) setDefaultStackModelURL: (NSURL *) name;

+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error;

+ (void (^)(NSError *error)) errorHandler;
+ (void) setErrorHandler: (void (^)(NSError *error)) block;

+ (id <AZCoreRecordErrorHandler>) errorDelegate;
+ (void) setErrorDelegate: (id <AZCoreRecordErrorHandler>) target;

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *context)) block;

+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block;
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block completion: (void (^)(void)) callback;

@end
