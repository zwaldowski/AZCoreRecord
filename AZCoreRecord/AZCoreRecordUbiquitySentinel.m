//
//  AZCoreRecordUbiquitySentinel.m
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 6/22/12.
//  Copyright 2012 The Mental Faculty BV. Licensed under BSD.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordUbiquitySentinel.h"

#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIApplication.h>
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
#import <AppKit/NSApplication.h>
#endif

#ifdef NSUbiquityIdentityDidChangeNotification
#error here
#endif

#if (__IPHONE_OS_VERSION_MAX_ALLOWED < 60000) || (__MAC_OS_X_VERSION_MAX_ALLOWED < 1080)
NSString *const AZUbiquityIdentityDidChangeNotification = @"NSUbiquityIdentityDidChangeNotification";
#else
NSString *const AZUbiquityIdentityDidChangeNotification = NSUbiquityIdentityDidChangeNotification;
#endif

@interface AZCoreRecordUbiquitySentinel ()

@property (nonatomic) BOOL haveSentResetNotification;
@property (nonatomic) BOOL performingDeviceRegistrationCheck;
@property (nonatomic, strong) NSMetadataQuery *devicesListMetadataQuery;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, copy) NSURL *ubiquityURL;

- (void)startMonitoringDevicesList;
- (void)stopMonitoringDevicesList;
- (void)updateDevicesList;
- (void)syncURLWithCloud:(NSURL *)URL completion:(void (^)(BOOL success, NSError *error))block;
- (void)updateFromPersistentStoreCoordinatorNotification:(NSNotification *)note;
- (void)devicesListDidUpdate:(NSNotification *)notif;

@end

@implementation AZCoreRecordUbiquitySentinel

@synthesize ubiquityURL = _ubiquityURL, fileManager = _fileManager, devicesListMetadataQuery = _devicesListMetadataQuery;
@synthesize haveSentResetNotification = _haveSentResetNotification, performingDeviceRegistrationCheck = _performingDeviceRegistrationCheck;

+ (void)load {
	@autoreleasepool {
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver: [self sharedSentinel] selector: @selector(updateFromPersistentStoreCoordinatorNotification:) name: NSPersistentStoreCoordinatorStoresDidChangeNotification object: nil];
#ifdef __IPHONE_OS_VERSION_MIN_REQUIRED
		id termination = UIApplicationWillTerminateNotification;
		id resume = UIApplicationDidBecomeActiveNotification;
#elif defined(__MAC_OS_X_VERSION_MIN_REQUIRED)
		id termination = NSApplicationWillTerminateNotification;
		id resume = NSApplicationDidBecomeActiveNotification;
#endif
		[nc addObserver: [self sharedSentinel] selector: @selector(stopMonitoringDevicesList) name: termination object: nil];
		[nc addObserver: [self sharedSentinel] selector: @selector(updateDevicesList) name: resume object: nil];
	}
}

+ (AZCoreRecordUbiquitySentinel *)sharedSentinel {
	static dispatch_once_t onceToken;
	static AZCoreRecordUbiquitySentinel *sharedSentinel = nil;
	dispatch_once(&onceToken, ^{
		sharedSentinel = [self new];
	});
	return sharedSentinel;
}

- (id)init {
	if ((self = [super init])) {
		self.fileManager = [NSFileManager new];
	}
	return self;
}

-(void)dealloc
{
    [self stopMonitoringDevicesList];
}

#pragma mark - Helpers

- (void)syncURLWithCloud:(NSURL *)URL completion:(void (^)(BOOL success, NSError *error))block
{
	NSParameterAssert(block);
	
    NSError *error;
    NSNumber *downloaded;
    BOOL success = [URL getResourceValue:&downloaded forKey:NSURLUbiquitousItemIsDownloadedKey error:&error];
    if ( !success ) {
        // Resource doesn't exist
        block(YES, nil);
        return;
    }
    
    if ( !downloaded.boolValue ) {
        NSNumber *downloading;
        BOOL success = [URL getResourceValue:&downloading forKey:NSURLUbiquitousItemIsDownloadingKey error:&error];
        if ( !success ) {
            block(NO, error);
            return;
        }
        
        if ( !downloading.boolValue ) {
            BOOL success = [[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL: URL error:&error];
            if ( !success ) {
                block(NO, error);
                return;
            }
        }
        
        // Download not complete. Schedule another check.
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
        dispatch_queue_t queue = dispatch_get_current_queue();
        dispatch_retain(queue);
        dispatch_after(popTime, queue, ^{
            [self syncURLWithCloud: URL completion: [block copy]];
            dispatch_release(queue);
        });
    }
    else {
        block(YES, nil);
    }
}

#pragma mark - Internal

- (void)stopMonitoringDevicesList {
    [NSFileCoordinator removeFilePresenter:self];
    [self.devicesListMetadataQuery disableUpdates];
    [self.devicesListMetadataQuery stopQuery];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.devicesListMetadataQuery = nil;
}

- (void)startMonitoringDevicesList {
	self.devicesListMetadataQuery = [NSMetadataQuery new];
	self.devicesListMetadataQuery.searchScopes = [NSArray arrayWithObject:NSMetadataQueryUbiquitousDataScope];
	self.devicesListMetadataQuery.predicate = [NSPredicate predicateWithFormat:@"%K like %@", NSMetadataItemFSNameKey, self.presentedItemURL.lastPathComponent];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(devicesListDidUpdate:) name:NSMetadataQueryDidUpdateNotification object: self.devicesListMetadataQuery];
	[NSFileCoordinator addFilePresenter:self];
}

#pragma mark - Notifications

- (void)updateFromPersistentStoreCoordinatorNotification:(NSNotification *)note {
	if (!self.ubiquityAvailable)
		return;
	
	self.ubiquityURL = [self.fileManager URLForUbiquityContainerIdentifier: nil];
	
	NSArray *newStores = [note.userInfo objectForKey: NSAddedPersistentStoresKey];
	NSUInteger foundIndex = [newStores indexOfObjectPassingTest:^BOOL(NSPersistentStore *store, NSUInteger idx, BOOL *stop) {
		NSDictionary *storeOptions = store.options;
		return ([storeOptions objectForKey: NSPersistentStoreUbiquitousContentNameKey] != nil && [storeOptions objectForKey: NSPersistentStoreUbiquitousContentURLKey] != nil);
	}];
	
	if (foundIndex != NSNotFound)
		[self updateDevicesList];
}

-(void)devicesListDidUpdate:(NSNotification *)notif
{
    if ( self.haveSentResetNotification || self.performingDeviceRegistrationCheck ) return;
    [self.devicesListMetadataQuery disableUpdates];
    self.performingDeviceRegistrationCheck = YES;
	
	dispatch_queue_t completionQueue = dispatch_get_current_queue();
	dispatch_retain(completionQueue);
	
	NSURL *url = self.presentedItemURL;
	[self syncURLWithCloud: self.presentedItemURL completion: ^(BOOL success, NSError *error) {
		NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
		[coordinator coordinateReadingItemAtURL:url options:0 error:NULL byAccessor:^(NSURL *readURL) {
			NSArray *devices = [NSArray arrayWithContentsOfURL:readURL];
			NSString *deviceId = [self ubiquityIdentityToken];
			BOOL deviceIsRegistered = [devices containsObject:deviceId];
			dispatch_async(completionQueue, ^{
				self.performingDeviceRegistrationCheck = NO;
				if ( !deviceIsRegistered ) {
					self.haveSentResetNotification = YES;
					[self stopMonitoringDevicesList];
					[[NSNotificationCenter defaultCenter] postNotificationName: AZUbiquityIdentityDidChangeNotification object:self userInfo:nil];
				}
				else {
					[self.devicesListMetadataQuery enableUpdates];
				}
				
				dispatch_release(completionQueue);
			});
		}];
	}];
}

-(void)updateDevicesList
{
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[self syncURLWithCloud: self.presentedItemURL completion: ^(BOOL success, NSError *error) {
            if ( !success ) return;
            
            __block BOOL updated = NO;
            __block NSMutableArray *devices = nil;
            NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:self];
            [coordinator coordinateReadingItemAtURL: self.presentedItemURL options:0 error:NULL byAccessor:^(NSURL *readURL) {
                devices = [NSMutableArray arrayWithContentsOfURL:readURL];
                if ( !devices ) devices = [NSMutableArray array];
                NSString *deviceId = [self ubiquityIdentityToken];
                
                if ( ![devices containsObject:deviceId] ) {
                    [devices addObject:deviceId];
                    updated = YES;
                }
            }];
            
            [coordinator coordinateWritingItemAtURL: self.ubiquityURL options:0 error:NULL byAccessor:^(NSURL *newURL) {
                NSFileManager *fm = [[NSFileManager alloc] init];
                [fm createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:NULL];
            }];
            
            if ( updated ) [coordinator coordinateWritingItemAtURL: self.presentedItemURL options:NSFileCoordinatorWritingForReplacing error:NULL byAccessor:^(NSURL *writeURL) {
                [devices writeToURL:writeURL atomically:YES];
            }];
		}];
    });
}

#pragma mark - Utilities

- (void)setUbiquityURL:(NSURL *)ubiquityURL {
	if (self.devicesListMetadataQuery)
		[self stopMonitoringDevicesList];
	_ubiquityURL = [ubiquityURL copy];
	if (self.ubiquityURL)
		[self startMonitoringDevicesList];
}

- (BOOL)isUbiquityAvailable {
	return !![self.fileManager URLForUbiquityContainerIdentifier: nil];
}

- (NSString *)ubiquityIdentityToken {
	if (!self.ubiquityAvailable)
		return nil;
	
    static NSString * const key = @"ApplicationUbiquityUniqueID";
    NSUserDefaults *sud = [NSUserDefaults standardUserDefaults];
    NSString *uniqueID = [sud stringForKey: key];
    if ( !uniqueID ) {
        uniqueID = [[NSProcessInfo processInfo] globallyUniqueString];
        [sud setObject: uniqueID forKey: key];
        [sud synchronize];
    }
    return uniqueID;
}

#pragma mark - NSFilePresenter

- (NSURL *)presentedItemURL {
	if (!self.ubiquityURL)
		return nil;
	
	return [self.ubiquityURL URLByAppendingPathComponent: @"UbiquitousSyncingDevices.plist"];
}

- (NSOperationQueue *)presentedItemOperationQueue {
	static dispatch_once_t onceToken;
	static NSOperationQueue *presentedItemOperationQueue = nil;
	dispatch_once(&onceToken, ^{
		presentedItemOperationQueue = [NSOperationQueue new];
	});
	return presentedItemOperationQueue;
}

-(void)presentedItemDidChange
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateDevicesList];
	});
}

- (void)accommodatePresentedItemDeletionWithCompletionHandler:(void (^)(NSError *))completionHandler {
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateDevicesList];
		[[NSNotificationCenter defaultCenter] postNotificationName: AZUbiquityIdentityDidChangeNotification object: nil];
		completionHandler(NULL);
	});
}

#pragma mark -

@end
