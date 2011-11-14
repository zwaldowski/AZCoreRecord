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

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName;
+ (void) setupAutoMigratingCoreDataStack;
+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName;
+ (void) setupCoreDataStackWithInMemoryStore;

+ (void) cleanUp;

+ (NSString *) currentStack;

+ (void) handleErrors:(NSError *)error;

+ (void)setErrorHandler:(CoreDataError)block;
+ (CoreDataError)errorHandler;

+ (void)setErrorHandlerTarget:(id <MRErrorHandler>)target;
+ (id <MRErrorHandler>)errorHandlerTarget;

@end

#pragma mark - Helper Functions

//Helper Functions
extern NSDate *MRDateAdjustForDST(NSDate *date);
extern NSDate *MRDateFromString(NSString *value, NSString *format);
extern id MRColorFromString(NSString *serializedColor);

@compatibility_alias MagicalRecord MagicalRecordHelpers;