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
#import "NSPersistentStore+AZCoreRecord.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

@interface AZCoreRecordManager ()

@property (nonatomic, weak) id <AZCoreRecordErrorHandler> errorDelegate;
@property (nonatomic, copy) void(^errorHandler)(NSError *);

@property (nonatomic) dispatch_semaphore_t semaphore;

@property (nonatomic, strong, readwrite, setter = azcr_setManagedObjectContext:) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite, setter = azcr_setManagedObjectModel:) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite, setter = azcr_setPersistentStoreCoordinator:) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite, setter = azcr_setStackUbiquityOptions:) NSDictionary *stackUbiquityOptions;
@property (nonatomic, readonly, getter = azcr_storeOptions) NSDictionary *storeOptions;

@end

@implementation AZCoreRecordManager

@synthesize errorDelegate = _errorDelegate;
@synthesize errorHandler = _errorHandler;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize semaphore = _semaphore;
@synthesize stackShouldAutoMigrateStore = _stackShouldAutoMigrate;
@synthesize stackShouldUseInMemoryStore = _stackShouldUseInMemoryStore;
@synthesize stackShouldUseUbiquity = _stackShouldUseUbiquity;
@synthesize stackStoreName = _stackStoreName;
@synthesize stackStoreURL = _stackStoreURL;
@synthesize stackModelName = _stackModelName;
@synthesize stackModelURL = _stackModelURL;
@synthesize stackUbiquityOptions = _stackUbiquityOptions;

- (id) init
{
	if ((self = [super init]))
	{
		self.semaphore = dispatch_semaphore_create(1);
	}
	
	return self;
}

- (void) dealloc
{
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

- (void) azcr_setManagedObjectContext: (NSManagedObjectContext *) managedObjectContext
{
	BOOL isUbiquitous = self.ubiquityEnabled;
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
	
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
	id key = UIApplicationWillTerminateNotification;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
	id key = NSApplicationWillTerminateNotification;
#endif
	
	[[NSNotificationCenter defaultCenter] removeObserver: _managedObjectContext name: key object: nil];
	
	if (isUbiquitous && _managedObjectContext)
		[_managedObjectContext stopObservingUbiquitousChangesInCoordinator:coordinator];
	
	_managedObjectContext = managedObjectContext;
	
	if (isUbiquitous && _managedObjectContext)
		[_managedObjectContext startObservingUbiquitousChangesInCoordinator:coordinator];
	
	if (_managedObjectContext)
		[[NSNotificationCenter defaultCenter] addObserver: _managedObjectContext selector: @selector(save) name: key object: nil];
}

- (NSManagedObjectModel *) managedObjectModel
{
	if (!_managedObjectModel)
	{
		NSURL *storeURL = self.stackModelURL;
		NSString *storeName = self.stackModelName;
		
		if (!storeURL && storeName)
			_managedObjectModel = [NSManagedObjectModel modelNamed:storeName];
		else if (storeURL) 
			_managedObjectModel = [NSManagedObjectModel modelAtURL:storeURL];
		else
			_managedObjectModel = [NSManagedObjectModel model];
	}
	
	return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
	if (!_persistentStoreCoordinator)
	{
		NSURL *storeURL = self.stackStoreURL ?: [NSPersistentStore URLForStoreName: nil];
		NSString *storeType = self.stackShouldUseInMemoryStore ? NSInMemoryStoreType : NSSQLiteStoreType;
		_persistentStoreCoordinator = [NSPersistentStoreCoordinator coordinatorWithStoreAtURL: storeURL ofType: storeType options: [self azcr_storeOptions]];
	}
	
	return _persistentStoreCoordinator;
}

#pragma mark - Utilities

- (NSDictionary *) azcr_storeOptions
{
	BOOL shouldAutoMigrate = self.stackShouldAutoMigrateStore;
	BOOL shouldUseCloud = self.stackUbiquityOptions != nil;
	NSMutableDictionary *options = shouldAutoMigrate || shouldUseCloud ? [NSMutableDictionary dictionary] : nil;
	
	if (shouldAutoMigrate)
	{
		static NSDictionary *lightweightMigrationOptions = nil;
		static dispatch_once_t once;
		dispatch_once(&once, ^{
			lightweightMigrationOptions = [NSDictionary dictionaryWithObjectsAndKeys:
					   (__bridge id) kCFBooleanTrue, NSMigratePersistentStoresAutomaticallyOption,
					   (__bridge id) kCFBooleanTrue, NSInferMappingModelAutomaticallyOption, nil];
		});
		
		[options addEntriesFromDictionary: lightweightMigrationOptions];
	}
	
	if (shouldUseCloud)
	{
		[options addEntriesFromDictionary: self.stackUbiquityOptions];
	}
	
	return options;
}

#pragma mark - Stack Settings

- (NSString *) stackStoreName
{
	if (!_stackStoreName.pathExtension)
		return [_stackStoreName stringByAppendingPathExtension:@"sqlite"];
	
	return _stackStoreName;
}

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
	self.managedObjectModel = [managedDocument managedObjectModel];
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
- (void) setStackStoreName: (NSString *) stackStoreName
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackStoreName = [stackStoreName copy];
	
	dispatch_semaphore_signal(self.semaphore);
}
- (void) setStackStoreURL: (NSURL *) stackStoreURL
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	_stackStoreURL = [stackStoreURL copy];
	
	dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Ubiquity Support

+ (BOOL) supportsUbiquity {
	return [[AZCoreRecordUbiquitySentinel sharedSentinel] isUbiquityAvailable];
}

- (void) setUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent
{
	NSURL *cloudURL = [[NSFileManager new] URLForUbiquityContainerIdentifier: nil];
	if (pathComponent) cloudURL = [cloudURL URLByAppendingPathComponent:pathComponent];
	
	if (!key) key = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 key, NSPersistentStoreUbiquitousContentNameKey,
							 cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
	
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	[self azcr_resetStack];
	self.stackUbiquityOptions = options;
	
	dispatch_semaphore_signal(self.semaphore);
}

- (BOOL) isUbiquityEnabled
{
	if (![[self class] supportsUbiquity])
		return NO;
	
	if (!self.stackUbiquityOptions.count)
		return NO;
	
	return _stackShouldUseUbiquity;
}
- (void) setUbiquityEnabled: (BOOL) enabled
{
	if (_stackShouldUseUbiquity == enabled)
		return;
	
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

	do
	{
		if (enabled && !self.stackUbiquityOptions.count)
			[self setUbiquitousContainer:nil contentNameKey:nil cloudStorePathComponent:nil];
		
		if (!_persistentStoreCoordinator)
			break;
		
		NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
		
		if (_managedObjectContext)
		{
			if (enabled)
				[_managedObjectContext startObservingUbiquitousChangesInCoordinator:psc];
			else
				[_managedObjectContext stopObservingUbiquitousChangesInCoordinator:psc];
		}
		
		NSPersistentStore *storeToChange = nil;
		
		if (!enabled)
		{
			NSUInteger cloudStoreIndex = [_persistentStoreCoordinator.persistentStores indexOfObjectPassingTest: ^BOOL(NSPersistentStore *obj, NSUInteger idx, BOOL *stop) {
				return ([obj.options objectForKey: NSPersistentStoreUbiquitousContentURLKey] != nil);
			}];
			
			if (cloudStoreIndex == NSNotFound)
				break;
			
			storeToChange = [_persistentStoreCoordinator.persistentStores objectAtIndex: cloudStoreIndex];
		}
		else if (_persistentStoreCoordinator.persistentStores.count == 1)
		{
			storeToChange = _persistentStoreCoordinator.persistentStores.lastObject;
		}
		else
		{
			NSUInteger notCloudStoreIndex = [_persistentStoreCoordinator.persistentStores indexOfObjectPassingTest: ^BOOL(NSPersistentStore *obj, NSUInteger idx, BOOL *stop) {
				return ![obj.options objectForKey: NSPersistentStoreUbiquitousContentURLKey] && [obj.type isEqualToString: NSSQLiteStoreType];
			}];
			
			if (notCloudStoreIndex == NSNotFound)
				break;
			
			storeToChange = [_persistentStoreCoordinator.persistentStores objectAtIndex: notCloudStoreIndex];
		}
		
		NSError *err = nil;
		[psc migratePersistentStore: storeToChange toURL: storeToChange.URL options: self.storeOptions withType: storeToChange.type error: &err];
		[AZCoreRecordManager handleError: err];
	} while (0);
	
	dispatch_semaphore_signal(self.semaphore);
}

#pragma mark - Default stack settings

+ (AZCoreRecordManager *) sharedManager
{
	static dispatch_once_t onceToken;
	static AZCoreRecordManager *sharedManager = nil;
	dispatch_once(&onceToken, ^{
		sharedManager = [self new];
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
+ (void) setDefaultStackStoreName: (NSString *) name
{
	[[self sharedManager] setStackStoreName: name];
}
+ (void) setDefaultStackStoreURL: (NSURL *) name
{
	[[self sharedManager] setStackStoreURL: name];
}
+ (void) setDefaultStackModelName: (NSString *) name
{
	[[self sharedManager] setStackModelName: name];
}
+ (void) setDefaultStackModelURL: (NSURL *) name
{
	[[self sharedManager] setStackModelURL: name];
}

+ (void) setDefaultUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent
{
	[[self sharedManager] setUbiquitousContainer: containerID contentNameKey: key cloudStorePathComponent: pathComponent];
}

+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0)
{
	[[self sharedManager] configureWithManagedDocument: managedObject];
}

#pragma mark - Stack cleanup

- (void) azcr_resetStack
{
	if (self.managedObjectContext)
		self.managedObjectContext = nil;
	
	if (self.persistentStoreCoordinator)
		self.persistentStoreCoordinator = nil;
	
	if (self.managedObjectModel)
		self.managedObjectModel = nil;
}

- (void) azcr_resetStackOptions
{
	_stackShouldAutoMigrate = NO;
	_stackShouldUseInMemoryStore = NO;
	_stackShouldUseUbiquity = NO;
	_stackStoreName = nil;
	_stackStoreURL = nil;
	_stackModelName = nil;
	_stackModelURL = nil;
	_stackUbiquityOptions = nil;
}

- (void) azcr_cleanUp
{
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);

	self.errorDelegate = nil;
	self.errorHandler = NULL;
	[self azcr_resetStackOptions];
	[self azcr_resetStack];
	
	dispatch_semaphore_signal(self.semaphore);
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
	}
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
