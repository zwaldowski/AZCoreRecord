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

extern NSString *const AZCoreRecordDeduplicationIdentityAttributeKey;
extern NSString *const AZCoreRecordLocalStoreConfigurationNameKey;
extern NSString *const AZCoreRecordUbiquitousStoreConfigurationNameKey;

typedef NSArray *(^AZCoreRecordDeduplicationHandlerBlock)(NSArray *conflictingManagedObjects, NSArray *identityAttributes);
typedef void (^AZCoreRecordContextBlock)(NSManagedObjectContext *context);
typedef void (^AZCoreRecordErrorBlock)(NSError *error);
typedef void (^AZCoreRecordSeedBlock)(NSManagedObjectContext *oldMOC, NSManagedObjectContext *newMOC);
typedef void (^AZCoreRecordVoidBlock)(void);

@protocol AZCoreRecordErrorHandler <NSObject>
@required

- (void) handleError: (NSError *) error;

@end

@interface AZCoreRecordManager : NSObject
{
@private
	__weak id <AZCoreRecordErrorHandler> _errorDelegate;	
	AZCoreRecordErrorBlock _errorHandler;
	
	dispatch_semaphore_t _semaphore;
	
	BOOL _stackShouldAutoMigrate;
	BOOL _stackShouldUseUbiquity;
	BOOL _stackShouldUseInMemoryStore;
	id _ubiquityToken;
	NSString *_stackName;
	NSString *_stackModelName;
	NSURL *_stackModelURL;
	NSDictionary *_stackModelConfigurations;
	NSMutableDictionary *_conflictResolutionHandlers;
	
	NSManagedObjectContext *_managedObjectContext;
	NSPersistentStoreCoordinator *_persistentStoreCoordinator;
}

- (id) initWithStackName: (NSString *) name;

@property (nonatomic, readonly) NSString *stackName;

#pragma mark - Stack Accessors

@property (nonatomic, strong, readonly) id <NSObject, NSCopying, NSCoding> ubiquityToken;
@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (NSManagedObjectContext *) contextForCurrentThread;

#pragma mark - Helpers

@property (nonatomic, strong, readonly) NSPersistentStore *fallbackStore;
@property (nonatomic, strong, readonly) NSPersistentStore *localStore;
@property (nonatomic, strong, readonly) NSPersistentStore *ubiquitousStore;

@property (nonatomic, readonly) NSURL *fallbackStoreURL;
@property (nonatomic, readonly) NSURL *localStoreURL;
@property (nonatomic, readonly) NSURL *ubiquitousStoreURL;

@property (nonatomic, readonly, getter = isReadOnly) BOOL readOnly;

#pragma mark - Options

@property (nonatomic) BOOL stackShouldAutoMigrateStore;
@property (nonatomic) BOOL stackShouldUseInMemoryStore;
@property (nonatomic) BOOL stackShouldUseUbiquity;
@property (nonatomic, copy) NSDictionary *stackModelConfigurations;
@property (nonatomic, copy) NSString *stackModelName;
@property (nonatomic, copy) NSURL *stackModelURL;

- (void) configureWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Ubiquity Support

@property (nonatomic, getter = isUbiquityEnabled) BOOL ubiquityEnabled;

+ (BOOL) supportsUbiquity;

#pragma mark - Default stack settings

+ (AZCoreRecordManager *) sharedManager;

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate;
+ (void) setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory;
+ (void) setDefaultStackShouldUseUbiquity: (BOOL) usesUbiquity;
+ (void) setDefaultStackModelName: (NSString *) name;
+ (void) setDefaultStackModelURL: (NSURL *) name;
+ (void) setDefaultStackModelConfigurations: (NSDictionary *) dictionary;

+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0);

#pragma mark - Deduplication

- (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler forEntityName: (NSString *) entityName includeSubentities: (BOOL) includeSubentities;

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error;

+ (AZCoreRecordErrorBlock) errorHandler;
+ (void) setErrorHandler: (AZCoreRecordErrorBlock) block;

+ (id <AZCoreRecordErrorHandler>) errorDelegate;
+ (void) setErrorDelegate: (id <AZCoreRecordErrorHandler>) target;

#pragma mark - Data Commit

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block;

- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block;
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (AZCoreRecordVoidBlock) callback;

@end
