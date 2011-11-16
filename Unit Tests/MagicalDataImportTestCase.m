//
//  MagicalDataImportTestCase.m
//  MagicalRecord
//
//  Created by Saul Mora on 8/16/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import "MagicalRecord+Private.h"

@implementation MagicalDataImportTestCase

@synthesize testEntityData = testEntityData__;
@synthesize testEntity = testEntity__;

- (void) setUp
{
	[MagicalRecord setDefaultModelName:@"TestModel.momd"];
	[MagicalRecord setupCoreDataStackWithInMemoryStore];
	
	if ([self respondsToSelector:@selector(setupTestData)])
	{
		[self performSelector:@selector(setupTestData)];
	}
	
	self.testEntityData = [self dataFromJSONFixture];
}

- (void) tearDown
{
	[MagicalRecord _cleanUp];
}

- (Class) testEntityClass;
{
	return [NSManagedObject class];
}

-(BOOL)shouldRunOnMainThread
{
	return YES;
}

@end
