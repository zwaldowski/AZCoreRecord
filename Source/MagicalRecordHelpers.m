//
//  MagicalRecordHelpers.m
//  MagicalRecord
//
//  Created by Saul Mora on 3/11/10.
//  Copyright 2011 Magical Panda Software. All rights reserved.
//

#import "CoreData+MagicalRecord.h"
#import <objc/runtime.h>

static char *kErrorHandlerTargetKey = "errorHandlerTarget_";
static char *kErrorHandlerActionKey = "errorHandlerAction_";
static char *kErrorHandlerBlockKey = "errorHandlern_";
static char *kShouldAutoCreateMOMKey = "shouldAutoCreateManagedObjectModel_";
static char *kShouldAutoCreatePSCKey = "shouldAutoCreateDefaultPersistentStoreCoordinator_";

@implementation MagicalRecordHelpers

+ (void) cleanUp
{
	[MRCoreDataAction cleanUp];
	[NSManagedObjectContext setDefaultContext:nil];
	[NSManagedObjectModel setDefaultManagedObjectModel:nil];
	[NSPersistentStoreCoordinator setDefaultStoreCoordinator:nil];
	[NSPersistentStore setDefaultPersistentStore:nil];
}

+ (NSString *) currentStack
{
    NSMutableString *status = [NSMutableString stringWithString:@"Current Default Core Data Stack: ---- \n"];
    
    [status appendFormat:@"Context:     %@\n", [NSManagedObjectContext defaultContext]];
    [status appendFormat:@"Model:       %@\n", [NSManagedObjectModel defaultManagedObjectModel]];
    [status appendFormat:@"Coordinator: %@\n", [NSPersistentStoreCoordinator defaultStoreCoordinator]];
    [status appendFormat:@"Store:       %@\n", [NSPersistentStore defaultPersistentStore]];
    
    return status;
}

+ (void) handleErrors:(NSError *)error
{
    if (!error)
        return;
    
    id target = [self errorHandlerTarget];
    SEL action = [self errorHandlerAction];
    CoreDataError block = [self errorHandler];
    
    // If a custom error handler is set, call that
    if (target && action) 
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [target performSelector:action withObject:error];
#pragma clank diagnostic pop
    }
    else if (block)
    {
        block(error);	
    }
}

+ (void)setErrorHandler:(CoreDataError)block {
    if (!block) {
        block = ^(NSError *error){
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
        };
    }
    
    objc_setAssociatedObject(self, kErrorHandlerBlockKey, block, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (CoreDataError)errorHandler {
    return objc_getAssociatedObject(self, kErrorHandlerBlockKey);
}

+ (id) errorHandlerTarget
{
    return objc_getAssociatedObject(self, kErrorHandlerTargetKey);
}

+ (SEL) errorHandlerAction
{
    return NSSelectorFromString(objc_getAssociatedObject(self, kErrorHandlerActionKey));
}

+ (void) setErrorHandlerTarget:(id)target action:(SEL)action
{
    objc_setAssociatedObject(self, kErrorHandlerActionKey, NSStringFromSelector(action), OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, kErrorHandlerTargetKey, target, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (void) initialize
{
    if (self == [MagicalRecordHelpers class]) 
    {
        [self setShouldAutoCreateManagedObjectModel:YES];
        [self setShouldAutoCreateDefaultPersistentStoreCoordinator:YES];
    }
}

+ (void) setupCoreDataStack
{
    NSManagedObjectContext *context = [NSManagedObjectContext context];
	[NSManagedObjectContext setDefaultContext:context];
}

+ (void) setupAutoMigratingCoreDataStack
{
    [self setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kMagicalRecordDefaultStoreFileName];
}

+ (void) setupCoreDataStackWithStoreNamed:(NSString *)storeName
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithSqliteStoreNamed:storeName];
	[NSPersistentStoreCoordinator setDefaultStoreCoordinator:coordinator];
	
	NSManagedObjectContext *context = [NSManagedObjectContext contextWithStoreCoordinator:coordinator];
	[NSManagedObjectContext setDefaultContext:context];
}

+ (void) setupCoreDataStackWithAutoMigratingSqliteStoreNamed:(NSString *)storeName
{
    NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithAutoMigratingSqliteStoreNamed:storeName];
    [NSPersistentStoreCoordinator setDefaultStoreCoordinator:coordinator];
    
    NSManagedObjectContext *context = [NSManagedObjectContext contextWithStoreCoordinator:coordinator];
    [NSManagedObjectContext setDefaultContext:context];
}

+ (void) setupCoreDataStackWithInMemoryStore
{
	NSPersistentStoreCoordinator *coordinator = [NSPersistentStoreCoordinator coordinatorWithInMemoryStore];
	[NSPersistentStoreCoordinator setDefaultStoreCoordinator:coordinator];
	
	NSManagedObjectContext *context = [NSManagedObjectContext contextWithStoreCoordinator:coordinator];
	[NSManagedObjectContext setDefaultContext:context];
}

+ (BOOL) shouldAutoCreateManagedObjectModel;
{
    return [objc_getAssociatedObject(self, kShouldAutoCreateMOMKey) boolValue];
}

+ (void) setShouldAutoCreateManagedObjectModel:(BOOL)shouldAutoCreate;
{
    objc_setAssociatedObject(self, kShouldAutoCreateMOMKey, [NSNumber numberWithBool:shouldAutoCreate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL) shouldAutoCreateDefaultPersistentStoreCoordinator;
{
    return [objc_getAssociatedObject(self, kShouldAutoCreatePSCKey) boolValue];
}

+ (void) setShouldAutoCreateDefaultPersistentStoreCoordinator:(BOOL)shouldAutoCreate;
{
    objc_setAssociatedObject(self, kShouldAutoCreatePSCKey, [NSNumber numberWithBool:shouldAutoCreate], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

NSDate * adjustDateForDST(NSDate *date)
{
    NSTimeInterval dstOffset = [[NSTimeZone localTimeZone] daylightSavingTimeOffsetForDate:date];
    NSDate *actualDate = [date dateByAddingTimeInterval:dstOffset];
    return actualDate;
}

static NSDateFormatter *helperFormatter = nil;

NSDate * dateFromString(NSString *value, NSString *format)
{
    if (!helperFormatter) {
        helperFormatter = [NSDateFormatter new];
        [helperFormatter setTimeZone:[NSTimeZone localTimeZone]];
        [helperFormatter setLocale:[NSLocale currentLocale]];
    }
    [helperFormatter setDateFormat:format];
    return [helperFormatter dateFromString:value];
}

NSInteger* newColorComponentsFromString(NSString *serializedColor);
NSInteger* newColorComponentsFromString(NSString *serializedColor)
{
    NSScanner *colorScanner = [NSScanner scannerWithString:serializedColor];
    NSString *colorType;
    [colorScanner scanUpToString:@"(" intoString:&colorType];
    
    NSInteger *componentValues = malloc(4 * sizeof(NSInteger));
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
    return componentValues;
}

#if TARGET_OS_IPHONE

UIColor * UIColorFromString(NSString *serializedColor)
{
    NSInteger *componentValues = newColorComponentsFromString(serializedColor);
    UIColor *color = [UIColor colorWithRed:(componentValues[0] / 255.)
                                     green:(componentValues[1] / 255.)
                                      blue:(componentValues[2] / 255.)
                                     alpha:componentValues[3]];
    
    free(componentValues);
    return color;
}
id (*colorFromString)(NSString *) = UIColorFromString;

#else

NSColor * NSColorFromString(NSString *serializedColor)
{
    NSInteger *componentValues = newColorComponentsFromString(serializedColor);
    NSColor *color = [NSColor colorWithDeviceRed:(componentValues[0] / 255.)
                                      green:(componentValues[1] / 255.)
                                       blue:(componentValues[2] / 255.)
                                      alpha:componentValues[3]];
    free(componentValues);
    return color;
}
id (*colorFromString)(NSString *) = NSColorFromString;


#endif
