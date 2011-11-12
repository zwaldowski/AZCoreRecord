//
//  MRCoreDataAction.h
//  MagicalRecord
//
//  Created by Saul Mora on 2/24/11.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

typedef enum {
    MRCoreDataSaveOptionNone               = 0,
    MRCoreDataSaveOptionInBackground       = 1 << 0,
    MRCoreDataSaveOptionWithNewContext     = 1 << 1
} MRCoreDataSaveOption;

@interface MRCoreDataAction : NSObject

+ (void) saveDataWithBlock:(void(^)(NSManagedObjectContext *))block;
+ (void) saveDataWithBlock:(void(^)(NSManagedObjectContext *))block errorHandler:(void (^)(NSError *))errorHandler;

+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *))block;
+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *))block completion:(void(^)())callback;
+ (void) saveDataInBackgroundWithBlock:(void(^)(NSManagedObjectContext *))block completion:(void(^)())callback errorHandler:(void (^)(NSError *))errorHandler;

+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *))block;
+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void(^)(NSManagedObjectContext *))block completion:(void(^)(void))callback;
+ (void) saveDataWithOptions:(MRCoreDataSaveOption)options withBlock:(void (^)(NSManagedObjectContext *))block completion:(void (^)(void))callback errorHandler:(void(^)(NSError *))errorCallback;

@end
