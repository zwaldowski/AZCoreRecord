//
//  AZCoreRecordImportTestCase.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/16/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordImportTestCase.h"
#import "AZCoreRecordManager+Private.h"

@implementation AZCoreRecordImportTestCase

@synthesize testEntityData = _testEntityData;
@synthesize testEntity = _testEntity;

- (void) setUp
{
	[AZCoreRecord setStackModelName:@"TestModel.momd"];
	[AZCoreRecord setStackShouldUseInMemoryStore:YES];
	
	if ([self respondsToSelector:@selector(setupTestData)])
	{
		[self performSelector:@selector(setupTestData)];
	}
	
	self.testEntityData = [self dataFromJSONFixture];
}

- (void)tearDown {
	[AZCoreRecord azcr_cleanUp];
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
