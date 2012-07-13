//
//  AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <objc/runtime.h>

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	#import <UIKit/UIApplication.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
	#import <AppKit/NSApplication.h>
#endif

#import "AZCoreRecordManager.h"
#import "AZCoreRecordUbiquitySentinel.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

NSString *const AZCoreRecordManagerWillAddUbiquitousStoreNotification = @"AZCoreRecordManagerWillAddUbiquitousStoreNotification";
NSString *const AZCoreRecordManagerDidAddUbiquitousStoreNotification = @"AZCoreRecordManagerDidAddUbiquitousStoreNotification";
NSString *const AZCoreRecordManagerDidAddFallbackStoreNotification = @"AZCoreRecordManagerDidAddFallbackStoreNotification";
NSString *const AZCoreRecordManagerShouldRunDeduplicationNotification = @"AZCoreRecordManagerShouldRunDeduplicationNotification";
NSString *const AZCoreRecordDidFinishSeedingPersistentStoreNotification = @"AZCoreRecordDidFinishSeedingPersistentStoreNotification";

NSString *const AZCoreRecordLocalStoreConfigurationNameKey = @"LocalStore";
NSString *const AZCoreRecordUbiquitousStoreConfigurationNameKey = @"UbiquitousStore";

@interface AZCoreRecordManager ()

@property (nonatomic, weak) id <AZCoreRecordErrorHandler> errorDelegate;
@property (nonatomic, copy) void(^errorHandler)(NSError *);

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic) dispatch_semaphore_t loadSemaphore;
@property (nonatomic) dispatch_semaphore_t semaphore;

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) NSString *ubiquityToken;
@property (nonatomic, readonly) NSURL *stackStoreURL;

- (NSDictionary *) azcr_lightweightMigrationOptions;
- (void) azcr_loadPersistentStores;
- (void) azcr_resetStack;
- (void) azcr_didChangeUbiquityIdentityNotification:(NSNotification *)note;
- (void)azcr_didRecieveDeduplicationNotification:(NSNotification *)note;

@end

@implementation AZCoreRecordManager

@synthesize errorDelegate = _errorDelegate;
@synthesize errorHandler = _errorHandler;
@synthesize semaphore = _semaphore, loadSemaphore = _loadSemaphore;
@synthesize fileManager = _fileManager;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize ubiquityToken = _ubiquityToken;
@synthesize stackShouldAutoMigrateStore = _stackShouldAutoMigrate;
@synthesize stackShouldUseInMemoryStore = _stackShouldUseInMemoryStore;
@synthesize stackShouldUseUbiquity = _stackShouldUseUbiquity;
@synthesize stackName = _stackName;
@synthesize stackModelName = _stackModelName;
@synthesize stackModelURL = _stackModelURL;
@synthesize stackModelConfigurations = _stackModelConfigurations;
@synthesize ubiquityEnabled = _ubiquityEnabled;

#pragma mark - Setup and teardown

- (id)initWithStackName:(NSString *)name {
	NSParameterAssert(name);
	
	if ((self = [super init]))
	{
		_stackName = [name copy];
		self.loadSemaphore = dispatch_semaphore_create(1);
		self.semaphore = dispatch_semaphore_create(1);
        self.fileManager = [NSFileManager new];
		self.ubiquityToken = [[AZCoreRecordUbiquitySentinel sharedSentinel] ubiquityIdentityToken];
		
		//subscribe to the account change notification
		[[NSNotificationCenter defaultCenter] addObserver: self
												 selector: @selector(azcr_didChangeUbiquityIdentityNotification:)
													 name: AZUbiquityIdentityDidChangeNotification
												   object: nil];
	}
	
	return self;
	
}

- (id) init
{
	[NSException raise:NSInvalidArgumentException format:@"AZCoreRecordManager must be initialized using -initWithStackName:"];
	return nil;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	dispatch_release(self.loadSemaphore), self.loadSemaphore = NULL;
	dispatch_release(self.semaphore), self.semaphore = NULL;
}

#pragma mark - Stack storage

- (NSManagedObjectContext *) managedObjectContext
{
	if (!_managedObjectContext)
	{
		NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
		managedObjectContext.persistentStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
		self.managedObjectContext = managedObjectContext;
	}
	
	return _managedObjectContext;
}

- (void) setManagedObjectContext: (NSManagedObjectContext *) managedObjectContext
{
	BOOL isUbiquitous = self.ubiquityEnabled;
	
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	id key = UIApplicationWillTerminateNotification;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
	id key = NSApplicationWillTerminateNotification;
#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver: _managedObjectContext name: key object: nil];
	
	if (isUbiquitous && _managedObjectContext)
		[_managedObjectContext stopObservingUbiquitousChanges];
	
	_managedObjectContext = managedObjectContext;
	
	if (isUbiquitous && _managedObjectContext)
		[_managedObjectContext startObservingUbiquitousChanges];
	
	if (_managedObjectContext)
		[[NSNotificationCenter defaultCenter] addObserver: _managedObjectContext selector: @selector(save) name: key object: nil];
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
	if (!_persistentStoreCoordinator)
	{
		NSManagedObjectModel *model = nil;
		NSURL *modelURL = self.stackModelURL;
		NSString *modelName = self.stackModelName;
			
		if (!modelURL && modelName) {
			model = [NSManagedObjectModel modelWithName: modelName];
		} else if (modelURL) {
			model = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
		} else {
			model = [NSManagedObjectModel mergedModelFromBundles: nil];
		}
		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: model];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver: self selector: @selector(azcr_didRecieveDeduplicationNotification:) name: AZCoreRecordDidFinishSeedingPersistentStoreNotification object: _persistentStoreCoordinator];
        [nc addObserver: self selector: @selector(azcr_didRecieveDeduplicationNotification:) name: NSPersistentStoreDidImportUbiquitousContentChangesNotification object: _persistentStoreCoordinator];
        
		[self azcr_loadPersistentStores];
	}
	
	return _persistentStoreCoordinator;
}

#pragma mark - Persistent stores

- (NSDictionary *) azcr_lightweightMigrationOptions
{
	static NSDictionary *lightweightMigrationOptions = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		lightweightMigrationOptions = [NSDictionary dictionaryWithObjectsAndKeys:
									   (__bridge id) kCFBooleanTrue, NSMigratePersistentStoresAutomaticallyOption,
									   (__bridge id) kCFBooleanTrue, NSInferMappingModelAutomaticallyOption, nil];
	});
	return lightweightMigrationOptions;
}

- (void)azcr_loadPersistentStores {
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
		dispatch_semaphore_wait(self.loadSemaphore, DISPATCH_TIME_FOREVER);
        
        NSString *localConfiguration = [self.stackModelConfigurations objectForKey: AZCoreRecordLocalStoreConfigurationNameKey];
        NSString *ubiquitousConfiguration = [self.stackModelConfigurations objectForKey: AZCoreRecordUbiquitousStoreConfigurationNameKey];
        NSURL *localURL = self.localStoreURL;
        NSURL *fallbackURL = self.fallbackStoreURL;
        NSURL *ubiquityURL = self.ubiquitousStoreURL;
        NSURL *ubiquityContainer = [self.fileManager URLForUbiquityContainerIdentifier:nil];
        
        NSDictionary *options = (self.stackShouldUseUbiquity || self.stackShouldAutoMigrateStore) ? [self azcr_lightweightMigrationOptions] : [NSDictionary dictionary];
        
        if (localConfiguration.length) {
            if (![self.fileManager fileExistsAtPath: localURL.path]) {
                NSURL *bundleURL = [[NSBundle mainBundle] URLForResource: localURL.lastPathComponent.stringByDeletingPathExtension withExtension: localURL.pathExtension];
                if (bundleURL) {
                    NSError *error = nil;
                    if (![self.fileManager copyItemAtURL: bundleURL toURL: localURL error: &error]) {
                        [AZCoreRecordManager handleError: error];
                        return;
                    }
                }
            }
            
            [self.persistentStoreCoordinator addStoreAtURL: localURL configuration: localConfiguration options: options];
        }
		
		BOOL fallback = NO;
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		if ([[self class] supportsUbiquity] && self.stackShouldUseUbiquity) {
			[nc postNotificationName: AZCoreRecordManagerWillAddUbiquitousStoreNotification object: self];
            
            NSMutableDictionary *storeOptions = [options mutableCopy];
            
            if (ubiquityContainer) {
                [storeOptions setObject: @"UbiquitousStore" forKey: NSPersistentStoreUbiquitousContentNameKey];
                [storeOptions setObject: [ubiquityContainer URLByAppendingPathComponent:@"UbiquitousData"] forKey: NSPersistentStoreUbiquitousContentURLKey];
            } else {
                [storeOptions setObject: [NSNumber numberWithBool: YES] forKey: NSReadOnlyPersistentStoreOption];
                fallback = YES;
            }
            
            if ([self.persistentStoreCoordinator addStoreAtURL: ubiquityURL configuration: ubiquitousConfiguration options: storeOptions]) {
				[nc postNotificationName: AZCoreRecordManagerDidAddUbiquitousStoreNotification object: self];
                _ubiquityEnabled = YES;
            } else {
				fallback = YES;
            }
		} else {
			fallback = YES;
		}
		
		if (fallback) {
            NSMutableDictionary *storeOptions = [options mutableCopy];
            
            if (self.stackShouldUseInMemoryStore)
                [self.persistentStoreCoordinator addInMemoryStoreWithConfiguration: ubiquitousConfiguration options: storeOptions];
            else
                [self.persistentStoreCoordinator addStoreAtURL: fallbackURL configuration: ubiquitousConfiguration options: storeOptions];
            
			[nc postNotificationName: AZCoreRecordManagerDidAddFallbackStoreNotification object: self];
            _ubiquityEnabled = NO;
		}
		
		dispatch_semaphore_signal(self.loadSemaphore);
    });
}

- (void) azcr_resetStack
{
	if (_managedObjectContext)
		[self.managedObjectContext reset];
	
	if (_persistentStoreCoordinator) {
		__block NSError *error = nil;
		[self.persistentStoreCoordinator.persistentStores enumerateObjectsUsingBlock:^(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
			[self.persistentStoreCoordinator removePersistentStore: store error: &error];
		}];
		[AZCoreRecordManager handleError: error];
	}
}

- (void)azcr_didChangeUbiquityIdentityNotification:(NSNotification *)note
{
    dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(globalQueue, ^{
		dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        
        [self azcr_resetStack];
        
        self.ubiquityToken = [[AZCoreRecordUbiquitySentinel sharedSentinel] ubiquityIdentityToken];
        
        [self azcr_loadPersistentStores];
        
        dispatch_semaphore_signal(self.semaphore);
    });
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
}

- (void)azcr_didRecieveDeduplicationNotification:(NSNotification *)note
{
    [[NSNotificationCenter defaultCenter] postNotificationName: AZCoreRecordManagerShouldRunDeduplicationNotification object: self];
}

#pragma mark - Utilities

- (BOOL)isReadOnly {
	if (!self.stackShouldUseUbiquity)
		return NO;
    
	return self.ubiquityToken.length && !![self.fileManager URLForUbiquityContainerIdentifier: nil];
}

- (NSURL *)stackStoreURL {
	static dispatch_once_t onceToken;
	static NSURL *appSupportURL = nil;
	dispatch_once(&onceToken, ^{
		appSupportURL = [[self.fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
	});
	NSString *storeName = [self.stackName.lastPathComponent stringByDeletingPathExtension];
	NSURL *storeDirectory = [appSupportURL URLByAppendingPathComponent: storeName isDirectory: YES];
    if (![self.fileManager fileExistsAtPath: storeDirectory.path]) {
        NSError *error = nil;
        [self.fileManager createDirectoryAtURL: storeDirectory withIntermediateDirectories: YES attributes: nil error: &error];
        [[self class] handleError: error];
    }
	return storeDirectory;
}

- (NSURL *)ubiquitousStoreURL
{
    NSURL *ubiquityContainer = [self.fileManager URLForUbiquityContainerIdentifier:nil];
    if (!ubiquityContainer)
        return nil;
    NSURL *iCloudStoreURL = [self.stackStoreURL URLByAppendingPathComponent: self.ubiquityToken];
    if (![self.fileManager fileExistsAtPath: iCloudStoreURL.path]) {
        NSError *error = nil;
        [self.fileManager createDirectoryAtURL:iCloudStoreURL withIntermediateDirectories:YES attributes:nil error:&error];
        [[self class] handleError: error];
    }
    return [iCloudStoreURL URLByAppendingPathComponent: @"UbiquitousStore.sqlite"];
}

- (NSURL *)fallbackStoreURL
{
	return [self.stackStoreURL URLByAppendingPathComponent: @"FallbackStore.sqlite"];
}

- (NSURL *)localStoreURL
{
	return [self.stackStoreURL URLByAppendingPathComponent: @"LocalStore.sqlite"];
}

#pragma mark - Stack Settings

- (void) configureWithManagedDocument: (id) managedDocument
{
	Class documentClass = NULL;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	documentClass = NSClassFromString(@"UIManagedDocument");
#else
	documentClass = NSClassFromString(@"NSPersistentDocument");
#endif
	
	NSAssert(documentClass, @"Not available on this OS.");
	NSParameterAssert([managedDocument isKindOfClass:documentClass]);
	
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	self.persistentStoreCoordinator = [[managedDocument managedObjectContext] persistentStoreCoordinator];
	self.managedObjectContext = [managedDocument managedObjectContext];
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackModelName: (NSString *) stackModelName
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackModelName = [stackModelName copy];
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackModelURL: (NSURL *) stackModelURL
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackModelURL = [stackModelURL copy];
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackModelConfigurations:(NSDictionary *)stackModelConfigurations
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackModelConfigurations = [stackModelConfigurations copy];
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackShouldAutoMigrateStore: (BOOL) stackShouldAutoMigrateStore
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackShouldAutoMigrate = stackShouldAutoMigrateStore;
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackShouldUseInMemoryStore: (BOOL) stackShouldUseInMemoryStore
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackShouldUseInMemoryStore = stackShouldUseInMemoryStore;
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackShouldUseUbiquity: (BOOL) stackShouldUseUbiquity
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackShouldUseUbiquity = stackShouldUseUbiquity;
	
	dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Ubiquity Support

+ (BOOL) supportsUbiquity {
	return [[AZCoreRecordUbiquitySentinel sharedSentinel] isUbiquityAvailable];
}

- (void) setUbiquityEnabled: (BOOL) enabled
{
	if (_ubiquityEnabled == enabled)
		return;
	    
    _stackShouldUseUbiquity = enabled;
    
    [self azcr_didChangeUbiquityIdentityNotification: nil];
}

#pragma mark - Default stack settings

+ (AZCoreRecordManager *) sharedManager
{
	static dispatch_once_t onceToken;
	static AZCoreRecordManager *sharedManager = nil;
	dispatch_once(&onceToken, ^{
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
		sharedManager = [[self alloc] initWithStackName: applicationName];
	});
	
	return sharedManager;
}

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate
{
	[[self sharedManager] setStackShouldUseInMemoryStore: shouldMigrate];
}
+ (void) setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory
{
	[[self sharedManager] setStackShouldUseInMemoryStore: inMemory];
}
+ (void) setDefaultStackShouldUseUbiquity: (BOOL) usesUbiquity
{
	[[self sharedManager] setStackShouldUseUbiquity: usesUbiquity];
}
+ (void) setDefaultStackModelName: (NSString *) name
{
	[[self sharedManager] setStackModelName: name];
}
+ (void) setDefaultStackModelURL: (NSURL *) name
{
	[[self sharedManager] setStackModelURL: name];
}
+ (void) setDefaultStackModelConfigurations: (NSDictionary *) dictionary
{
	[[self sharedManager] setStackModelConfigurations: dictionary];
}

+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0)
{
	[[self sharedManager] configureWithManagedDocument: managedObject];
}

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error
{
	if (!error) return;
	
	AZCoreRecordManager *shared = [self sharedManager];
	
	void (^block)(NSError *error) = shared.errorHandler;
	if (block)
	{
		block(error);
		return;
	}
	
	id target = shared.errorDelegate;
	if (target)
	{
		[target performSelector: @selector(handleError:) withObject: error];
		return;
	}
	
#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	[[NSApplication sharedApplication] presentError: error];
#endif
}

+ (void (^)(NSError *error)) errorHandler
{
	return [[self sharedManager] errorHandler];
}
+ (void) setErrorHandler: (void (^)(NSError *error)) block
{
	[[self sharedManager] setErrorHandler: block];
}

+ (id <AZCoreRecordErrorHandler>) errorDelegate
{
	return [[self sharedManager] errorDelegate];
}
+ (void) setErrorDelegate: (id <AZCoreRecordErrorHandler>) target
{
	[[self sharedManager] setErrorDelegate: target];
}

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (void(^)(NSManagedObjectContext *context)) block
{
	[[NSManagedObjectContext contextForCurrentThread] saveDataWithBlock: block];
}
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block
{
	[[NSManagedObjectContext contextForCurrentThread] saveDataInBackgroundWithBlock: block completion: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *context)) block completion: (void (^)(void)) callback
{
	[[NSManagedObjectContext contextForCurrentThread] saveDataInBackgroundWithBlock: block completion: callback];
}

@end
