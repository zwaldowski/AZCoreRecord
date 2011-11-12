//
//  MagicalRecordHelpers.h
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#ifdef MR_LOGGING
#define ARLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#else
#define ARLog(...)
#endif

@class NSManagedObjectContext;
typedef void (^CoreDataBlock)(NSManagedObjectContext *context);
typedef void (^CoreDataError)(NSError *error);

@protocol MRErrorHandler <NSObject>

@optional
- (void)handleErrors:(NSError *)error;
+ (void)handleErrors:(NSError *)error;

@end

@interface MagicalRecordHelpers : NSObject

+ (NSString *) currentStack;

+ (void) cleanUp;

+ (void) handleErrors:(NSError *)error;

+ (void)setErrorHandler:(CoreDataError)block;
+ (CoreDataError)errorHandler;

+ (void)setErrorHandlerTarget:(id <MRErrorHandler>)target;
+ (id <MRErrorHandler>)errorHandlerTarget;

//global options
// enable/disable logging
// add logging provider
// autocreate new PSC per Store
// autoassign new instances to default store
+ (BOOL) shouldAutoCreateManagedObjectModel;
+ (void) setShouldAutoCreateManagedObjectModel:(BOOL)shouldAutoCreate;
+ (BOOL) shouldAutoCreateDefaultPersistentStoreCoordinator;
+ (void) setShouldAutoCreateDefaultPersistentStoreCoordinator:(BOOL)shouldAutoCreate;

+ (void) setupCoreDataStack;
+ (void) setupCoreDataStackWithInMemoryStore;
+ (void) setupAutoMigratingCoreDataStack;

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;

@end

#pragma mark - Helper Functions

//Helper Functions
NSDate * adjustDateForDST(NSDate *date);
NSDate * dateFromString(NSString *value, NSString *format);

#if TARGET_OS_IPHONE
UIColor * UIColorFromString(NSString *serializedColor);
#else
NSColor * NSColorFromString(NSString *serializedColor);
#endif
id (*colorFromString)(NSString *);

