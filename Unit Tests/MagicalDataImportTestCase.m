//
//  MagicalDataImportTestCase.m
//  Magical Record
//
//  Created by Saul Mora on 8/16/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#import "MagicalDataImportTestCase.h"
#import "MagicalRecord+Private.h"

@implementation MagicalDataImportTestCase

@synthesize testEntityData = _testEntityData;
@synthesize testEntity = _testEntity;

- (void) setUp
{
	[MagicalRecord setStackModelName:@"TestModel.momd"];
	[MagicalRecord setStackShouldUseInMemoryStore:YES];
	
	if ([self respondsToSelector:@selector(setupTestData)])
	{
		[self performSelector:@selector(setupTestData)];
	}
	
	self.testEntityData = [self dataFromJSONFixture];
}

- (void)tearDown {
	[MagicalRecord _cleanUp];
}

- (Class) testEntityClass
{
	return [NSManagedObject class];
}

-(BOOL)shouldRunOnMainThread
{
	return YES;
}

@end
