//
//  MagicalRecordHelpers.m
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import "MagicalRecord+Private.h"
#import <objc/runtime.h>

static const char *kErrorHandlerTargetKey = "errorHandlerTarget_";
static const char *kErrorHandlerIsClassKey = "errorHandlerIsClass_";
static const char *kErrorHandlerBlockKey = "errorHandler_";

@implementation MagicalRecordHelpers

+ (void) cleanUp
{
	objc_removeAssociatedObjects(self);
	[NSManagedObjectContext _setDefaultContext:nil];
	[NSManagedObjectModel _setDefaultManagedObjectModel:nil];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:nil];
	[NSPersistentStore _setDefaultPersistentStore:nil];
}

+ (NSString *) currentStack
{
	NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];
	
	[status appendFormat:@"Context:	 %@\n", [NSManagedObjectContext defaultContext]];
	[status appendFormat:@"Model:	   %@\n", [NSManagedObjectModel defaultManagedObjectModel]];
	[status appendFormat:@"Coordinator: %@\n", [NSPersistentStoreCoordinator defaultStoreCoordinator]];
	[status appendFormat:@"Store:	   %@\n", [NSPersistentStore defaultPersistentStore]];
	
	return status;
}

+ (void)handleErrors:(NSError *)error
{
	if (!error)
		return;
	
	id target = [self errorHandlerTarget];
	CoreDataError block = [self errorHandler];
	
	if (block) {
		block(error);
		return;
	}
	
	if (target) {
		BOOL isClassSelector = [objc_getAssociatedObject(self, kErrorHandlerIsClassKey) boolValue];
		[(isClassSelector ? [target class] : target) performSelector:@selector(handleErrors:) withObject:error];
		return;
	}
	
	// default error handler
	NSDictionary *userInfo = [error userInfo];
	for (NSArray *detailedError in [userInfo allValues])
	{
		if ([detailedError isKindOfClass:[NSArray class]])
		{
			for (NSError *e in detailedError)
			{
				if ([e respondsToSelector:@selector(userInfo)])
				{
					ARLog(@"Error Details: %@", [e userInfo]);
				}
				else
				{
					ARLog(@"Error Details: %@", e);
				}
			}
		}
		else
		{
			ARLog(@"Error: %@", detailedError);
		}
	}
	ARLog(@"Error Domain: %@", [error domain]);
	ARLog(@"Recovery Suggestion: %@", [error localizedRecoverySuggestion]);
}

+ (void)setErrorHandler:(CoreDataError)block
{
	objc_setAssociatedObject(self, kErrorHandlerBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (CoreDataError)errorHandler
{
	return objc_getAssociatedObject(self, kErrorHandlerBlockKey);
}

+ (id <MRErrorHandler>) errorHandlerTarget
{
	return objc_getAssociatedObject(self, kErrorHandlerTargetKey);
}

+ (void) setErrorHandlerTarget:(id <MRErrorHandler>)target
{
	NSNumber *isClassMethodNumber = nil;
	if ([target respondsToSelector:@selector(handleErrors:)])
		isClassMethodNumber = [NSNumber numberWithBool:NO];
	else if ([[target class] respondsToSelector:@selector(handleErrors:)])
		isClassMethodNumber = [NSNumber numberWithBool:YES];
	objc_setAssociatedObject(self, kErrorHandlerIsClassKey, isClassMethodNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	objc_setAssociatedObject(self, kErrorHandlerTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void) setupAutoMigratingCoreDataStack
{
	[self setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kMagicalRecordDefaultStoreFileName];
}

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreNamed:storeName];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithStoreAtURL:(NSURL *)storeURL
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreAtURL:storeURL];
	[NSPersistentStoreCoordinator setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreNamed:storeName];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreAtURL:(NSURL *)storeURL
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreAtURL:storeURL];
	[NSPersistentStoreCoordinator setDefaultStoreCoordinator:coordinator];
}

+ (void) setupCoreDataStackWithInMemoryStore
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithInMemoryStore];
	[NSPersistentStoreCoordinator _setDefaultStoreCoordinator:coordinator];
}

@end

NSDate * MRDateAdjustForDST(NSDate *date)
{
	NSTimeInterval dstOffset = [[NSTimeZone localTimeZone] daylightSavingTimeOffsetForDate:date];
	NSDate *actualDate = [date dateByAddingTimeInterval:dstOffset];
	return actualDate;
}

NSDate * MRDateFromString(NSString *value, NSString *format)
{
	static dispatch_once_t onceToken;
	static NSDateFormatter *helperFormatter;
	dispatch_once(&onceToken, ^{
		helperFormatter = [NSDateFormatter new];
		[helperFormatter setTimeZone:[NSTimeZone localTimeZone]];
		[helperFormatter setLocale:[NSLocale currentLocale]];
	});
	[helperFormatter setDateFormat:format];
	return [helperFormatter dateFromString:value];
}

id MRColorFromString(NSString *serializedColor)
{
	NSScanner *colorScanner = [NSScanner scannerWithString:serializedColor];
	NSString *colorType;
	[colorScanner scanUpToString:@"(" intoString:&colorType];
	
	NSInteger *componentValues = calloc(4, sizeof(NSInteger));
	if ([colorType hasPrefix:@"rgba"])
	{
		NSCharacterSet *rgbaCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@"(,)"];
		
		NSInteger *componentValue = componentValues;
		while (![colorScanner isAtEnd]) 
		{
			[colorScanner scanCharactersFromSet:rgbaCharacterSet intoString:nil];
			[colorScanner scanInteger:componentValue];
			componentValue++;
		}
	}
	
	id color = nil;
#if TARGET_OS_IPHONE
	color = [UIColor colorWithRed:(componentValues[0] / 255.)
									 green:(componentValues[1] / 255.)
									  blue:(componentValues[2] / 255.)
									 alpha:componentValues[3]];
#else
	color = [NSColor colorWithDeviceRed:(componentValues[0] / 255.)
										   green:(componentValues[1] / 255.)
											blue:(componentValues[2] / 255.)
										   alpha:componentValues[3]];
#endif
	free(componentValues);
	return color;
}
