//
//  AZCoreRecordImportTestCase.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/16/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordImportTestCase.h"
#import "AZCoreRecordManager.h"

@interface AZCoreRecordManager ()
- (void)azcr_cleanUp;
@end

@implementation AZCoreRecordImportTestCase

@synthesize testEntityData = _testEntityData;
@synthesize testEntity = _testEntity;

- (void) setUp
{
	[AZCoreRecordManager setDefaultStackModelName:@"TestModel.momd"];
	[AZCoreRecordManager setDefaultStackShouldUseInMemoryStore:YES];
	
	if ([self respondsToSelector:@selector(setupTestData)])
	{
		[self performSelector:@selector(setupTestData)];
	}
	
	self.testEntityData = [self dataFromJSONFixture];
}

- (void)tearDown {
	[[AZCoreRecordManager sharedManager] azcr_cleanUp];
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
