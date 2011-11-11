//
//  MagicalRecord for Core Data.
//
//  Created by Saul Mora.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

// enable to use caches for the fetchedResultsControllers (iOS only)
#if TARGET_OS_IPHONE
#define STORE_USE_CACHE
#endif

#define kCreateNewCoordinatorOnBackgroundOperations     0

#ifdef MR_LOGGING
#define ENABLE_ACTIVE_RECORD_LOGGING
#endif

#ifdef DEBUG
#define ENABLE_ACTIVE_RECORD_LOGGING
#endif

#ifdef MR_NO_LOGGING
#undef ENABLE_ACTIVE_RECORD_LOGGING
#endif

#ifdef ENABLE_ACTIVE_RECORD_LOGGING
    #define ARLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#else
    #define ARLog(...)
#endif

#import <CoreData/CoreData.h>

#import "MagicalRecordHelpers.h"
#import "MRCoreDataAction.h"

#import "NSManagedObject+MagicalRecord.h"
#import "NSManagedObjectContext+MagicalRecord.h"
#import "NSPersistentStoreCoordinator+MagicalRecord.h"
#import "NSManagedObjectModel+MagicalRecord.h"
#import "NSPersistentStore+MagicalRecord.h"
#import "NSManagedObject+MagicalDataImport.h"