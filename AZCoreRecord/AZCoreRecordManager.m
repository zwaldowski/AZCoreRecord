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
#import "NSManagedObject+AZCoreRecord.h"
#import "NSManagedObject+AZCoreRecordImport.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

NSString *const AZCoreRecordDidFinishSeedingPersistentStoreNotification = @"AZCoreRecordDidFinishSeedingPersistentStoreNotification";
NSString *const AZCoreRecordManagerDidAddFallbackStoreNotification = @"AZCoreRecordManagerDidAddFallbackStoreNotification";
NSString *const AZCoreRecordManagerDidAddUbiquitousStoreNotification = @"AZCoreRecordManagerDidAddUbiquitousStoreNotification";
NSString *const AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification = @"AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification";
NSString *const AZCoreRecordManagerShouldRunDeduplicationNotification = @"AZCoreRecordManagerShouldRunDeduplicationNotification";
NSString *const AZCoreRecordManagerWillAddUbiquitousStoreNotification = @"AZCoreRecordManagerWillAddUbiquitousStoreNotification";
NSString *const AZCoreRecordManagerWillBeginAddingPersistentStoresNotification = @"AZCoreRecordManagerWillBeginAddingPersistentStoresNotification";

NSString *const AZCoreRecordDeduplicationIdentityAttributeKey = @"identityAttribute";
NSString *const AZCoreRecordLocalStoreConfigurationNameKey = @"LocalStore";
NSString *const AZCoreRecordUbiquitousStoreConfigurationNameKey = @"UbiquitousStore";

@interface AZCoreRecordManager ()

@property (nonatomic, weak) id <AZCoreRecordErrorHandler> errorDelegate;
@property (nonatomic, copy) AZCoreRecordErrorBlock errorHandler;

@property (nonatomic, strong) NSFileManager *fileManager;

@property (nonatomic) dispatch_semaphore_t loadSemaphore;
@property (nonatomic) dispatch_semaphore_t semaphore;

@property (nonatomic, readonly) NSURL *stackStoreURL;
@property (nonatomic, strong) NSMutableDictionary *conflictResolutionHandlers;
@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite) id <NSObject, NSCopying, NSCoding> ubiquityToken;

- (NSDictionary *) azcr_lightweightMigrationOptions;

- (void) azcr_didChangeUbiquityIdentityNotification:(NSNotification *)note;
- (void) azcr_didRecieveDeduplicationNotification:(NSNotification *)note;
- (void) azcr_loadPersistentStores;
- (void) azcr_resetStack;

@end

@implementation AZCoreRecordManager

#pragma mark - Setup and teardown

- (id) init
{
	[NSException raise: NSInvalidArgumentException format: @"AZCoreRecordManager must be initialized using -initWithStackName:"];
	return nil;
}
- (id) initWithStackName: (NSString *) name
{
	NSParameterAssert(name);
	
	if ((self = [super init]))
	{
		_stackName = [name copy];
		_semaphore = dispatch_semaphore_create(1);
		_loadSemaphore = dispatch_semaphore_create(1);
		
		self.conflictResolutionHandlers = [NSMutableDictionary dictionary];
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

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	dispatch_release(_semaphore);
	dispatch_release(_loadSemaphore);
}

#pragma mark - Stack storage

- (NSManagedObjectContext *) contextForCurrentThread
{
	if ([NSThread isMainThread])
		return self.managedObjectContext;
	
	NSManagedObjectContext *context = nil;
	
	dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	
	NSThread *thread = [NSThread currentThread];
	NSMutableDictionary *dict = [thread threadDictionary];
	NSString *key = self.stackName;
	context = [dict objectForKey: self.stackName];
	if (!context)
	{
		context = [self.managedObjectContext newChildContext];
		[dict setObject: context forKey: key];
		
		__block id observer = [[NSNotificationCenter defaultCenter] addObserverForName: NSThreadWillExitNotification object: thread queue: nil usingBlock: ^(NSNotification *note) {
			NSThread *thread = [note object];
			NSManagedObjectContext *context = [thread.threadDictionary objectForKey: key];
			[context reset];
			[[NSNotificationCenter defaultCenter] removeObserver: observer];
		}];
	}
	
	dispatch_semaphore_signal(self.semaphore);
	
	return context;
}
- (NSManagedObjectContext *) managedObjectContext
{
	if (!_managedObjectContext)
	{
		NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
		managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
		self.managedObjectContext = managedObjectContext;
	}
	
	return _managedObjectContext;
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
	
	if (_managedObjectContext) {
		if (isUbiquitous)
			[_managedObjectContext startObservingUbiquitousChanges];
		
		[[NSNotificationCenter defaultCenter] addObserver: _managedObjectContext selector: @selector(save) name: key object: nil];
	}
}

#pragma mark - Helpers

- (BOOL) isReadOnly
{
	if (!self.stackShouldUseUbiquity)
		return NO;
	
	return [(NSData *) self.ubiquityToken length] && !![self.fileManager URLForUbiquityContainerIdentifier: nil];
}

- (NSURL *) fallbackStoreURL
{
	return [self.stackStoreURL URLByAppendingPathComponent: @"FallbackStore.sqlite"];
}
- (NSURL *) localStoreURL
{
	return [self.stackStoreURL URLByAppendingPathComponent: @"LocalStore.sqlite"];
}
- (NSURL *) stackStoreURL
{
	static dispatch_once_t onceToken;
	static NSURL *appSupportURL = nil;
	dispatch_once(&onceToken, ^{
		NSURL *appSupportRoot = [[self.fileManager URLsForDirectory: NSApplicationSupportDirectory inDomains: NSUserDomainMask] lastObject];
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
		appSupportURL = [appSupportRoot URLByAppendingPathComponent: applicationName isDirectory: YES];
	});
	
	NSString *storeName = self.stackName.lastPathComponent;
	NSURL *storeDirectory = [storeName isEqualToString: appSupportURL.lastPathComponent] ? appSupportURL : [appSupportURL URLByAppendingPathComponent: storeName isDirectory: YES];
	
	if (![self.fileManager fileExistsAtPath: storeDirectory.path])
	{
		NSError *error = nil;
		[self.fileManager createDirectoryAtURL: storeDirectory withIntermediateDirectories: YES attributes: nil error: &error];
		[AZCoreRecordManager handleError: error];
	}
	
	return storeDirectory;
}
- (NSURL *) ubiquitousStoreURL
{
	if (![(NSData *) self.ubiquityToken length])
		return nil;
	
	NSURL *tokenURL = [self.stackStoreURL URLByAppendingPathComponent: @"TokenFoldersData.plist"];
	NSData *tokenData = [NSData dataWithContentsOfURL: tokenURL];
	
	NSMutableDictionary *foldersByToken = nil;
	
	if (tokenData)
		foldersByToken = [NSKeyedUnarchiver unarchiveObjectWithData: tokenData];
	else
		foldersByToken = [NSMutableDictionary dictionary];
	
	NSString *storeDirectoryUUID = [foldersByToken objectForKey: self.ubiquityToken];
	if (!storeDirectoryUUID)
	{
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		storeDirectoryUUID = (__bridge_transfer NSString *) CFUUIDCreateString(kCFAllocatorDefault, uuid);
		CFRelease(uuid);
		
		[foldersByToken setObject: storeDirectoryUUID forKey: self.ubiquityToken];
		tokenData = [NSKeyedArchiver archivedDataWithRootObject: foldersByToken];
		[tokenData writeToFile: tokenURL.path atomically: YES];
	}
	
	NSURL *iCloudStoreURL = [self.stackStoreURL URLByAppendingPathComponent: storeDirectoryUUID];
	
	if (![self.fileManager fileExistsAtPath: iCloudStoreURL.path])
	{
		NSError *error = nil;
		[self.fileManager createDirectoryAtURL: iCloudStoreURL withIntermediateDirectories: YES attributes: nil error: &error];
		[AZCoreRecordManager handleError: error];
	}
	
	return [iCloudStoreURL URLByAppendingPathComponent: @"UbiquitousStore.sqlite"];
}

#pragma mark - Persistent stores

- (NSDictionary *) azcr_lightweightMigrationOptions
{
	static NSDictionary *lightweightMigrationOptions = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		lightweightMigrationOptions = @{
			NSMigratePersistentStoresAutomaticallyOption : @(YES),
			NSInferMappingModelAutomaticallyOption : @(YES)
		};
	});
	
	return lightweightMigrationOptions;
}

- (void) azcr_didChangeUbiquityIdentityNotification: (NSNotification *) note
{
	dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(globalQueue, ^{
		dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
		
		[self azcr_resetStack];
		
		self.ubiquityToken = [[AZCoreRecordUbiquitySentinel sharedSentinel] ubiquityIdentityToken];
		
		[self azcr_loadPersistentStores];
		
		dispatch_semaphore_signal(self.semaphore);
	});
}
- (void) azcr_didRecieveDeduplicationNotification: (NSNotification *) note
{
	[[NSNotificationCenter defaultCenter] postNotificationName: AZCoreRecordManagerShouldRunDeduplicationNotification object: self];
	
	if (!self.conflictResolutionHandlers.count)
		return;
	
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
		dispatch_semaphore_wait(self.loadSemaphore, DISPATCH_TIME_FOREVER);
		
		[self saveDataInBackgroundWithBlock: ^(NSManagedObjectContext *context) {
			[self.conflictResolutionHandlers enumerateKeysAndObjectsUsingBlock: ^(NSString *entityName, AZCoreRecordDeduplicationHandlerBlock handler, BOOL *stop) {
				BOOL includesSubentities = NO;
				if ([entityName hasPrefix: @"+"])
				{
					includesSubentities = YES;
					entityName = [entityName substringFromIndex: 1];
				}
				
				NSEntityDescription *entityDescription = [context.persistentStoreCoordinator.managedObjectModel.entitiesByName objectForKey: entityName];
				NSArray *identityAttributes = [[entityDescription.userInfo objectForKey: AZCoreRecordDeduplicationIdentityAttributeKey] componentsSeparatedByString: @","];
				
				NSFetchRequest *masterFetchRequest = [[NSFetchRequest alloc] init];
				masterFetchRequest.entity = entityDescription;
				masterFetchRequest.fetchBatchSize = [NSManagedObject defaultBatchSize];
				masterFetchRequest.includesPendingChanges = NO;
				masterFetchRequest.includesSubentities = includesSubentities;
				masterFetchRequest.resultType = NSDictionaryResultType;
				
				NSMutableArray *propertiesToFetch = [NSMutableArray arrayWithCapacity: identityAttributes.count * 2];
				NSMutableArray *propertiesToGroupBy = [NSMutableArray arrayWithCapacity: identityAttributes.count];
				
				[identityAttributes enumerateObjectsUsingBlock: ^(NSString *identityAttribute, NSUInteger idx, BOOL *stop) {
					NSAttributeDescription *attributeDescription = [entityDescription.propertiesByName objectForKey: identityAttribute];
					[propertiesToFetch addObject: attributeDescription];
					[propertiesToGroupBy addObject: attributeDescription];
					
					NSExpressionDescription *countExpressionDescription = [[NSExpressionDescription alloc] init];
					countExpressionDescription.name = [NSString stringWithFormat: @"%@Count", identityAttribute];
					countExpressionDescription.expression = [NSExpression expressionWithFormat: @"count:(%K)", identityAttribute];
					countExpressionDescription.expressionResultType = NSInteger64AttributeType;
					[propertiesToFetch addObject: countExpressionDescription];
				}];
				
				masterFetchRequest.propertiesToFetch = propertiesToFetch;
				masterFetchRequest.propertiesToGroupBy = propertiesToGroupBy;
				
				NSError *error;
				NSMutableArray *dictionaryResults = [[context executeFetchRequest: masterFetchRequest error: &error] mutableCopy];
				[AZCoreRecordManager handleError: error];
				
				NSFetchRequest *fetchRequestTemplate = [[NSFetchRequest alloc] init];
				fetchRequestTemplate.entity = entityDescription;
				fetchRequestTemplate.fetchBatchSize = [NSManagedObject defaultBatchSize];
				fetchRequestTemplate.includesPendingChanges = NO;
				fetchRequestTemplate.includesSubentities = includesSubentities;

				[dictionaryResults enumerateObjectsUsingBlock: ^(NSDictionary *dictionaryResult, NSUInteger _idx, BOOL *stop) {
					__block BOOL hasDuplicates = YES;
					
					[propertiesToFetch enumerateObjectsUsingBlock: ^(NSExpressionDescription *expressionDescription, NSUInteger idx, BOOL *stop) {
						if (idx % 2 == 0) return;
						
						NSNumber *value = [dictionaryResult objectForKey: expressionDescription.name];
						if ([value integerValue] < 2)
						{
							hasDuplicates = NO;
							*stop = YES;
						}
					}];

					if (!hasDuplicates)
						return;
					
					NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity: identityAttributes.count];
					[identityAttributes enumerateObjectsUsingBlock: ^(NSString *identityAttribute, NSUInteger idx, BOOL *stop) {
						NSPredicate *subpredicate = [NSPredicate predicateWithFormat: @"%K == %@", identityAttribute, [dictionaryResult valueForKey: identityAttribute]];
						[subpredicates addObject: subpredicate];
					}];
					
					NSFetchRequest *fetchRequest = [fetchRequestTemplate copy];
					fetchRequest.predicate = [NSCompoundPredicate andPredicateWithSubpredicates: subpredicates];;
					
					NSError *error;
					NSMutableArray *duplicateGroup = [[context executeFetchRequest: fetchRequest error: &error] mutableCopy];
					[AZCoreRecordManager handleError: error];
					
					NSArray *resultingObjects = handler(duplicateGroup, identityAttributes);
					if (resultingObjects.count)
					{
						[resultingObjects enumerateObjectsUsingBlock: ^(id resultingObject, NSUInteger idx, BOOL *stop) {
							if ([resultingObject isKindOfClass: [NSManagedObject class]])
							{
								[duplicateGroup removeObject: resultingObject];
							}
							else if ([resultingObjects isKindOfClass: [NSDictionary class]])
							{
								NSManagedObject *managedObject = [[NSManagedObject alloc] initWithEntity: entityDescription insertIntoManagedObjectContext: context];
								[managedObject updateValuesFromDictionary: resultingObject];
							}
							else
							{
								NSAssert1(NO, @"Resulting object of unexpected class %@ was returned", [resultingObject class]);
							}
						}];
						
						[duplicateGroup makeObjectsPerformSelector: @selector(deleteInContext:) withObject: context];
					}
				}];
			}];
		} completion: ^{
			// LASTLY, signal the load semaphore
			dispatch_semaphore_signal(self.loadSemaphore);
		}];
	});
}
- (void) azcr_loadPersistentStores
{
	dispatch_semaphore_wait(self.loadSemaphore, DISPATCH_TIME_FOREVER);

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc postNotificationName: AZCoreRecordManagerWillBeginAddingPersistentStoresNotification object: self];
	
	[self azcr_resetStack];
	
	NSString *localConfiguration = [self.stackModelConfigurations objectForKey: AZCoreRecordLocalStoreConfigurationNameKey];
	NSString *ubiquitousConfiguration = [self.stackModelConfigurations objectForKey: AZCoreRecordUbiquitousStoreConfigurationNameKey];
	NSURL *localURL = self.localStoreURL;
	NSURL *fallbackURL = self.fallbackStoreURL;
	NSURL *ubiquityURL = self.ubiquitousStoreURL;
	NSURL *ubiquityContainer = [self.fileManager URLForUbiquityContainerIdentifier:nil];
	
	NSDictionary *options = (self.stackShouldUseUbiquity || self.stackShouldAutoMigrateStore) ? [self azcr_lightweightMigrationOptions] : [NSDictionary dictionary];
	
	if (localConfiguration.length)
	{
		if (![self.fileManager fileExistsAtPath: localURL.path])
		{
			NSURL *bundleURL = [[NSBundle mainBundle] URLForResource: localURL.lastPathComponent.stringByDeletingPathExtension withExtension: localURL.pathExtension];
			if (bundleURL)
			{
				NSError *error = nil;
				if (![self.fileManager copyItemAtURL: bundleURL toURL: localURL error: &error])
				{
					[AZCoreRecordManager handleError: error];
					return;
				}
			}
		}
		
		[self.persistentStoreCoordinator addStoreAtURL: localURL configuration: localConfiguration options: options];
	}
	
	dispatch_block_t addFallback = ^{
		
		NSMutableDictionary *storeOptions = [options mutableCopy];
		
		if (self.stackShouldUseInMemoryStore)
			[self.persistentStoreCoordinator addInMemoryStoreWithConfiguration: ubiquitousConfiguration options: storeOptions];
		else
			[self.persistentStoreCoordinator addStoreAtURL: fallbackURL configuration: ubiquitousConfiguration options: storeOptions];
		
		[nc postNotificationName: AZCoreRecordManagerDidAddFallbackStoreNotification object: self];
		_ubiquityEnabled = NO;
	};
	
	dispatch_block_t finish = ^{
		[nc postNotificationName: AZCoreRecordManagerDidFinishAdddingPersistentStoresNotification object: self];
		dispatch_semaphore_signal(self.loadSemaphore);
	};
	
	if (self.stackShouldUseUbiquity && ubiquityURL) {
		[nc postNotificationName: AZCoreRecordManagerWillAddUbiquitousStoreNotification object: self];
		
		dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
		dispatch_async(globalQueue, ^{
			NSMutableDictionary *storeOptions = [options mutableCopy];
			BOOL fallback = NO;
			
			if (ubiquityContainer)
			{
				[storeOptions setObject: @"UbiquitousStore" forKey: NSPersistentStoreUbiquitousContentNameKey];
				[storeOptions setObject: [ubiquityContainer URLByAppendingPathComponent:@"UbiquitousData"] forKey: NSPersistentStoreUbiquitousContentURLKey];
			}
			else
			{
				[storeOptions setObject: [NSNumber numberWithBool: YES] forKey: NSReadOnlyPersistentStoreOption];
				fallback = YES;
			}
			
			if ([self.persistentStoreCoordinator addStoreAtURL: ubiquityURL configuration: ubiquitousConfiguration options: storeOptions])
			{
				[nc postNotificationName: AZCoreRecordManagerDidAddUbiquitousStoreNotification object: self];
				_ubiquityEnabled = YES;
			}
			else
			{
				fallback = YES;
			}
			
			if (fallback) addFallback();
			
			finish();
		});
	} else {
		addFallback();
		finish();
	}
}
- (void) azcr_resetStack
{
	if (_managedObjectContext)
	{
		[self.managedObjectContext performBlockAndWait: ^{
			[self.managedObjectContext reset];
		}];
	}
	
	if (_persistentStoreCoordinator)
	{
		[self.persistentStoreCoordinator.persistentStores enumerateObjectsUsingBlock:^(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
			NSError *error = nil;
			[self.persistentStoreCoordinator removePersistentStore: store error: &error];
			[AZCoreRecordManager handleError: error];
		}];
	}
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

+ (BOOL) supportsUbiquity
{
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
		NSString *applicationName = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
		sharedManager = [[AZCoreRecordManager alloc] initWithStackName: applicationName];
	});
	
	return sharedManager;
}

+ (void) setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate
{
	[[self sharedManager] setStackShouldAutoMigrateStore: shouldMigrate];
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
+ (void) setUpDefaultStackWithManagedDocument: (id) managedObject
{
	[[self sharedManager] configureWithManagedDocument: managedObject];
}

#pragma mark - Deduplication

- (void) registerDeduplicationHandler: (AZCoreRecordDeduplicationHandlerBlock) handler forEntityName: (NSString *) entityName includeSubentities: (BOOL) includeSubentities
{
	NSParameterAssert(entityName != nil);
	NSParameterAssert(handler != nil);
	
	if (includeSubentities) entityName = [@"+" stringByAppendingString: entityName];
	[self.conflictResolutionHandlers setObject: [handler copy] forKey: entityName];
}

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error
{
	if (!error)
		return;
	
	dispatch_async(dispatch_get_main_queue(), ^{
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
	});
}

+ (AZCoreRecordErrorBlock) errorHandler
{
	return [[self sharedManager] errorHandler];
}
+ (void) setErrorHandler: (AZCoreRecordErrorBlock) block
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

- (void) saveDataWithBlock: (AZCoreRecordContextBlock) block
{
	[self.managedObjectContext saveDataWithBlock: block];
}
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block
{
	[self.managedObjectContext saveDataInBackgroundWithBlock: block completion: NULL];
}
- (void) saveDataInBackgroundWithBlock: (AZCoreRecordContextBlock) block completion: (void (^)(void)) callback
{
	[self.managedObjectContext saveDataInBackgroundWithBlock: block completion: callback];
}

@end
