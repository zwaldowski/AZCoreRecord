//
//  MagicalRecordHelpers.h
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2010 Magical Panda Software, LLC All rights reserved.
//

#if TARGET_OS_IPHONE == 0
#define MAC_PLATFORM_ONLY YES
#endif

#ifdef NS_BLOCKS_AVAILABLE

@class NSManagedObjectContext;
typedef void (^CoreDataBlock)(NSManagedObjectContext *context);

#endif

@interface MagicalRecordHelpers : NSObject {}

+ (NSString *) currentStack;

+ (void) cleanUp;

+ (void) handleErrors:(NSError *)error;
- (void) handleErrors:(NSError *)error;

+ (void) setErrorHandlerTarget:(id)target action:(SEL)action;
+ (SEL) errorHandlerAction;
+ (id) errorHandlerTarget;

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

