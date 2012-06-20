//
//  AZCoreRecord.m
//  AZCoreRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordManager.h"
#import <objc/runtime.h>
#import "NSPersistentStore+AZCoreRecord.h"
#import "NSPersistentStoreCoordinator+AZCoreRecord.h"
#import "NSManagedObjectContext+AZCoreRecord.h"
#import "NSManagedObjectModel+AZCoreRecord.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIApplication.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#import <AppKit/NSApplication.h>
#endif

void azcr_swizzle_support(Class cls, SEL oldSel, SEL newSel) {
	Method origMethod = class_getInstanceMethod(cls, oldSel);
	Method newMethod = class_getInstanceMethod(cls, newSel);
	
	if (class_addMethod(cls, oldSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
		class_replaceMethod(cls, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
	else
		method_exchangeImplementations(origMethod, newMethod);
}

static NSDictionary *azcr_automaticLightweightMigrationOptions(void) {
	static NSDictionary *options = nil;
	static dispatch_once_t once;
	dispatch_once(&once, ^{
		id yes = (__bridge id)kCFBooleanTrue;
		options = [NSDictionary dictionaryWithObjectsAndKeys:
				   yes, NSMigratePersistentStoresAutomaticallyOption,
				   yes, NSInferMappingModelAutomaticallyOption, nil];
	});
	return options;
}

@interface AZCoreRecordManager ()

#if __has_feature(objc_arc_weak)
@property (weak) id <AZCoreRecordErrorHandler> errorDelegate;
#else
@property (unsafe_unretained) id <AZCoreRecordErrorHandler> errorDelegate;
#endif
@property (copy) void(^errorHandler)(NSError *);

@property (nonatomic, strong, readwrite, setter = azcr_setManagedObjectContext:) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite, setter = azcr_setManagedObjectModel:) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite, setter = azcr_setPersistentStore:) NSPersistentStore *persistentStore;
@property (nonatomic, strong, readwrite, setter = azcr_setPersistentStoreCoordinator:) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, strong, readwrite, setter = azcr_setStackUbiquityOptions:) NSDictionary *stackUbiquityOptions;
@property (nonatomic, readonly, getter = azcr_storeOptions) NSDictionary *storeOptions;

@end

@implementation AZCoreRecordManager

@synthesize errorDelegate = _errorDelegate;
@synthesize errorHandler = _errorHandler;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStore = _persistentStore;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize stackShouldAutoMigrateStore = _stackShouldAutoMigrate;
@synthesize stackShouldUseInMemoryStore = _stackShouldUseInMemoryStore;
@synthesize stackShouldUseUbiquity = _stackShouldUseUbiquity;
@synthesize stackStoreName = _stackStoreName;
@synthesize stackStoreURL = _stackStoreURL;
@synthesize stackModelName = _stackModelName;
@synthesize stackModelURL = _stackModelURL;
@synthesize stackUbiquityOptions = _stackUbiquityOptions;

+ (AZCoreRecordManager *)sharedManager {
	static dispatch_once_t onceToken;
	static AZCoreRecordManager *sharedManager = nil;
	dispatch_once(&onceToken, ^{
		sharedManager = [self new];
	});
	return sharedManager;
}

#pragma mark - Stack storage

- (NSManagedObjectContext *)managedObjectContext {
	if (!_managedObjectContext)
	{
		NSManagedObjectContext *managedObjectContext = nil;
        if ([NSManagedObjectContext instancesRespondToSelector: @selector(initWithConcurrencyType:)])
		{
            managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
        }
		else
		{
            managedObjectContext = [NSManagedObjectContext new];
        }
		
		managedObjectContext.persistentStoreCoordinator = [NSPersistentStoreCoordinator defaultStoreCoordinator];
		self.managedObjectContext = managedObjectContext;
	}
	
	return _managedObjectContext;
}

- (void)azcr_setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext {
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

- (NSManagedObjectModel *)managedObjectModel {
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

- (void)setPersistentStoreCoordinator:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	_persistentStoreCoordinator = persistentStoreCoordinator;
	
	// NB: If `_defaultCoordinator` is nil, then `persistentStores` is also nil, so `count` returns 0
	if (!_persistentStore && _persistentStoreCoordinator.persistentStores.count)
		[self azcr_setPersistentStore: [_persistentStoreCoordinator.persistentStores objectAtIndex: 0]];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	if (!_persistentStoreCoordinator)
	{
		NSURL *storeURL = self.stackStoreURL ?: [NSPersistentStore defaultLocalStoreURL];
		NSString *storeType = self.stackShouldUseInMemoryStore ? NSInMemoryStoreType : NSSQLiteStoreType;
		_persistentStoreCoordinator = [NSPersistentStoreCoordinator coordinatorWithStoreAtURL: storeURL ofType: storeType options: [self azcr_storeOptions]];
	}
	
	return _persistentStoreCoordinator;
}

#pragma mark - Utilities

- (NSDictionary *) azcr_storeOptions {
	BOOL shouldAutoMigrate = self.stackShouldAutoMigrateStore;
	BOOL shouldUseCloud = self.stackUbiquityOptions != nil;
	NSMutableDictionary *options = shouldAutoMigrate || shouldUseCloud ? [NSMutableDictionary dictionary] : nil;
	
	if (shouldAutoMigrate)
		[options addEntriesFromDictionary:azcr_automaticLightweightMigrationOptions()];
	
	if (shouldUseCloud)
		[options addEntriesFromDictionary: self.stackUbiquityOptions];
	
	return options;
}

#pragma mark - Stack settings

- (void)setStackShouldAutoMigrateStore:(BOOL)stackShouldAutoMigrateStore {
	@synchronized(self) {
		[self azcr_resetStack];
		_stackShouldAutoMigrate = stackShouldAutoMigrateStore;
	}
}

- (void)setStackShouldUseInMemoryStore:(BOOL)stackShouldUseInMemoryStore {
	@synchronized(self) {
		[self azcr_resetStack];
		_stackShouldUseInMemoryStore = stackShouldUseInMemoryStore;
	}
}

- (void)setStackShouldUseUbiquity:(BOOL)stackShouldUseUbiquity {
	@synchronized(self) {
		[self azcr_resetStack];
		_stackShouldUseUbiquity = stackShouldUseUbiquity;
	}
}

- (void)setStackStoreName:(NSString *)stackStoreName {
	@synchronized(self) {
		[self azcr_resetStack];
		_stackStoreName = [stackStoreName copy];
	}
}

- (NSString *)stackStoreName {
	if (!_stackStoreName.pathExtension)
		return [_stackStoreName stringByAppendingPathExtension:@"sqlite"];
	return _stackStoreName;
}

- (void)setStackStoreURL:(NSURL *)stackStoreURL {
	@synchronized(self) {
		[self azcr_resetStack];
		_stackStoreURL = [stackStoreURL copy];
	}
}

- (void)setStackModelName:(NSString *)stackModelName {
	@synchronized (self) {
		[self azcr_resetStack];
		_stackModelName = [stackModelName copy];
	}
}

- (void)setStackModelURL:(NSURL *)stackModelURL {
	@synchronized (self) {
		[self azcr_resetStack];
		_stackModelURL = [stackModelURL copy];
	}
}

- (void)setUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent {
	NSURL *cloudURL = [NSPersistentStore URLForUbiquitousContainer: containerID];
	if (pathComponent) cloudURL = [cloudURL URLByAppendingPathComponent:pathComponent];
	
	if (!key) key = [[NSBundle mainBundle] objectForInfoDictionaryKey: (NSString *) kCFBundleNameKey];
	NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
							 key, NSPersistentStoreUbiquitousContentNameKey,
							 cloudURL, NSPersistentStoreUbiquitousContentURLKey, nil];
	
	@synchronized(self) {
		[self azcr_resetStack];
		self.stackUbiquityOptions = options;
	}
}

- (void)configureWithManagedDocument: (id) managedDocument  {
	Class documentClass = NULL;
#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
	documentClass = NSClassFromString(@"UIManagedDocument");
#else
	documentClass = NSClassFromString(@"NSPersistentDocument");
#endif
	NSAssert(documentClass, @"Not available on this OS.");
	NSParameterAssert([managedDocument isKindOfClass:documentClass]);
	
	@synchronized(self) {
		[self azcr_resetStack];
		self.managedObjectModel = [managedDocument managedObjectModel];
		self.persistentStoreCoordinator = [[managedDocument managedObjectContext] persistentStoreCoordinator];
		self.managedObjectContext = [managedDocument managedObjectContext];
	}
}

#pragma mark - Default stack settings

+ (void)setDefaultStackShouldAutoMigrateStore: (BOOL) shouldMigrate {
	[[self sharedManager] setStackShouldUseInMemoryStore: shouldMigrate];
}
+ (void)setDefaultStackShouldUseInMemoryStore: (BOOL) inMemory {
	[[self sharedManager] setStackShouldUseInMemoryStore: inMemory];
}
+ (void)setDefaultStackStoreName: (NSString *) name {
	[[self sharedManager] setStackStoreName: name];
}
+ (void)setDefaultStackStoreURL: (NSURL *) name {
	[[self sharedManager] setStackStoreURL: name];
}
+ (void)setDefaultStackModelName: (NSString *) name {
	[[self sharedManager] setStackModelName: name];
}
+ (void)setDefaultStackModelURL: (NSURL *) name {
	[[self sharedManager] setStackModelURL: name];
}

+ (void)setDefaultUbiquitousContainer: (NSString *) containerID contentNameKey: (NSString *) key cloudStorePathComponent: (NSString *) pathComponent {
	[[self sharedManager] setUbiquitousContainer: containerID contentNameKey: key cloudStorePathComponent: pathComponent];
}

+ (void)setUpDefaultStackWithManagedDocument: (id) managedObject NS_AVAILABLE(10_4, 5_0) {
	[[self sharedManager] configureWithManagedDocument: managedObject];
}


#pragma mark - Stack cleanup

- (void)azcr_resetStack {
	if (self.managedObjectContext)
		self.managedObjectContext = nil;
	
	if (self.persistentStoreCoordinator) {
		[self azcr_setPersistentStore: nil];
		[self azcr_setPersistentStoreCoordinator: nil];
	}
	
	if (self.managedObjectModel) {
		[self azcr_setManagedObjectModel: nil];
	}
}

- (void)azcr_resetStackOptions {
	_stackShouldAutoMigrate = NO;
	_stackShouldUseInMemoryStore = NO;
	_stackShouldUseUbiquity = NO;
	_stackStoreName = nil;
	_stackStoreURL = nil;
	_stackModelName = nil;
	_stackModelURL = nil;
	_stackUbiquityOptions = nil;
}

- (void)azcr_cleanUp {
	@synchronized (self) {
		self.errorDelegate = nil;
		self.errorHandler = NULL;
		[self azcr_resetStackOptions];
		[self azcr_resetStack];
	}
}

#pragma mark - Ubiquity Support

+ (BOOL)supportsUbiquity
{
	return [NSPersistentStore URLForUbiquitousContainer:nil] != nil;
}

- (BOOL)isUbiquityEnabled {
	if (![[self class] supportsUbiquity])
		return NO;
	
	if (!self.stackUbiquityOptions.count)
		return NO;
	
	return _stackShouldUseUbiquity;
}

- (void)setUbiquityEnabled:(BOOL)enabled {
	if (_stackShouldUseUbiquity == enabled)
		return;
		
	@synchronized(self) {
		if (enabled && !self.stackUbiquityOptions.count)
			[self setUbiquitousContainer:nil contentNameKey:nil cloudStorePathComponent:nil];
		
		if (!_persistentStoreCoordinator)
			return;
		
		NSPersistentStoreCoordinator *psc = [NSPersistentStoreCoordinator defaultStoreCoordinator];
		
		if (_managedObjectContext) {
			if (enabled)
				[_managedObjectContext startObservingUbiquitousChangesInCoordinator:psc];
			else
				[_managedObjectContext stopObservingUbiquitousChangesInCoordinator:psc];
		}
		
		if ((([_persistentStore.options objectForKey:NSPersistentStoreUbiquitousContentURLKey]) != nil) == enabled)
			return;
				
		NSError *err = nil;
		[psc migratePersistentStore: _persistentStore toURL: _persistentStore.URL options: self.storeOptions withType: _persistentStore.type error: &err];
		[AZCoreRecordManager handleError:err];
	}
}

#pragma mark - Error Handling

+ (void) handleError: (NSError *) error
{
	if (!error) return;
	
	AZCoreRecordManager *shared = [self sharedManager];
	
	void (^block)(NSError *) = shared.errorHandler;
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

+ (void (^)(NSError *)) errorHandler
{
	return [[self sharedManager] errorHandler];
}
+ (void) setErrorHandler: (void (^)(NSError *)) block
{
	[[self sharedManager] setErrorHandler: block];
}

+ (id<AZCoreRecordErrorHandler>) errorDelegate
{
	return [[self sharedManager] errorDelegate];
}
+ (void) setErrorDelegate: (id<AZCoreRecordErrorHandler>) target
{
	[[self sharedManager] setErrorDelegate: target];
}

#pragma mark - Data Commit

+ (void) saveDataWithBlock: (void (^)(NSManagedObjectContext *)) block
{   
    [self saveDataWithOptions: AZCoreRecordSaveOptionsNone block: block success: NULL failure: NULL];
}

+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block
{
    [self saveDataWithOptions: AZCoreRecordSaveOptionsBackground block: block success: NULL failure: NULL];
}
+ (void) saveDataInBackgroundWithBlock: (void (^)(NSManagedObjectContext *)) block completion: (void (^)(void)) callback
{
    [self saveDataWithOptions: AZCoreRecordSaveOptionsBackground block: block success: callback failure: NULL];
}

+ (void) saveDataWithOptions: (AZCoreRecordSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block
{
    [self saveDataWithOptions: options block: block success: NULL failure: NULL];
}
+ (void) saveDataWithOptions: (AZCoreRecordSaveOptions) options block: (void (^)(NSManagedObjectContext *)) block success: (void (^)(void)) callback failure: (void (^)(NSError *)) errorCallback
{
	BOOL wantsBackground = (options & AZCoreRecordSaveOptionsBackground);
	BOOL wantsMainThread = (options & AZCoreRecordSaveOptionsMainThread);
	
	NSParameterAssert(block);
	NSParameterAssert(!(wantsBackground && wantsMainThread));
	
	BOOL wantsAsync		 = (options & AZCoreRecordSaveOptionsAsynchronous);
	BOOL usesNewContext	 = wantsBackground || (![NSThread isMainThread] && !wantsBackground && !wantsMainThread);
	
	dispatch_queue_t callbackBlock = wantsMainThread ? dispatch_get_main_queue() : dispatch_get_current_queue();
	
	dispatch_block_t queueBlock = ^{
		NSManagedObjectContext *defaultContext  = [NSManagedObjectContext defaultContext];
		NSManagedObjectContext *localContext = defaultContext;
		
		id backupMergePolicy = defaultContext.mergePolicy;
		
		if (usesNewContext)
		{
			localContext = [defaultContext newChildContext];
			defaultContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
			localContext.mergePolicy = NSOverwriteMergePolicy;
		}
		
		block(localContext);
		
		if (localContext.hasChanges)
			[localContext saveWithErrorHandler:errorCallback];
		
		defaultContext.mergePolicy = backupMergePolicy;
		
		if (callback)
			dispatch_async(callbackBlock, callback);
	};
	
	if (!wantsMainThread && !wantsBackground && !wantsAsync) {
		queueBlock();
		return;
	}
	
	dispatch_queue_t queue = NULL;
	
	if (wantsBackground)
		queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	else if (wantsMainThread)
		queue = dispatch_get_main_queue();
	else
		queue = dispatch_get_current_queue();
	
	if (wantsAsync)
		dispatch_async(queue, queueBlock);
	else
		dispatch_sync(queue, queueBlock);
}

@end
