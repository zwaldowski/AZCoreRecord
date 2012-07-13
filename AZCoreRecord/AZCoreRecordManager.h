//
//  AZCoreRecord.h
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <CoreData/CoreData.h>

extern NSString *const AZCoreRecordManagerWillAddUbiquitousStoreNotification;
extern NSString *const AZCoreRecordManagerDidAddUbiquitousStoreNotification;
extern NSString *const AZCoreRecordManagerDidAddFallbackStoreNotification;
extern NSString *const AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification;
extern NSString *const AZCoreRecordManagerShouldRunDeduplicationNotification;
extern NSString *const AZCoreRecordDidFinishSeedingPersistentStoreNotification;

extern NSString *const AZCoreRecordLocalStoreConfigurationNameKey;
extern NSString *const AZCoreRecordUbiquitousStoreConfigurationNameKey;

@protocol AZCoreRecordErrorHandler <NSObject>
@required

- (void) handleError: (NSError *) error;

@end

@interface AZCoreRecordManager : NSObject
{
@private
	__weak id <AZCoreRecordErrorHandler> _errorDelegate;	
	void (^_errorHandler)(NSError *);
	
	dispatch_semaphore_t _semaphore;
	
	BOOL _stackShouldAutoMigrate;
	BOOL _stackShouldUseUbiquity;
	BOOL _stackShouldUseInMemoryStore;
	NSString *_stackName;
	NSString *_stackModelName;
	NSURL *_stackModelURL;
	NSDictionary *_stackModelConfigurations;
	
	NSManagedObjectContext *_managedObjectContext;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
	NSString *_ubiquityToken;
}

- (id)initWithStackName: (NSString *) name;

@property (nonatomic, readonly) NSString *stackName;

#pragma mark - Stack accessors

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readonly) NSString *ubiquityToken;

- (NSManagedObjectContext *)contextForCurrentThread;

#pragma mark - Helpers

@property (nonatomic, readonly) NSURL *ubiquitousStoreURL;
@property (nonatomic, readonly) NSURL *fallbackStoreURL;
@property (nonatomic, readonly) NSURL *localStoreURL;

@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;

#pragma mark - Options

@property (nonatomic) BOOL stackShouldAutoMigrateStore;
@property (nonatomic) BOOL stackShouldUseInMemoryStore;
@property (nonatomic) BOOL stackShouldUseUbiquity;
@property (nonatomic, copy) NSString *stackModelName;
@property (nonatomic, copy) NSURL *stackModelURL;
@property (nonatomic, copy) NSDictionary *stackModelConfigurations;

- (void) configureWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Ubiquity Support

@property (nonatomic, getter = isUbiquityEnabled) BOOL ubiquityEnabled;

+ (BOOL) supportsUbiquity;

#pragma mark - Default stack settings

+ (AZCoreRecordManager *)sharedManager;

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
+ (void) setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory;
+ (void) setDefaultStackShouldUseUbiquity: (BOOL) usesUbiquity;
+ (void) setDefaultStackModelName: (NSString *) name;
+ (void) setDefaultStackModelURL: (NSURL *) name;
+ (void) setDefaultStackModelConfigurations: (NSDictionary *) dictionary;

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
