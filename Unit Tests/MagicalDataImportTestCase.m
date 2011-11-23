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
	[MagicalRecord _cleanUp];
	[NSManagedObjectModel modelNamed: @"TestModel.momd"];
	[NSPersistentStoreCoordinator coordinatorWithInMemoryStore];
	
	if ([self respondsToSelector:@selector(setupTestData)])
	{
		[self performSelector:@selector(setupTestData)];
	}
	
	self.testEntityData = [self dataFromJSONFixture];
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
