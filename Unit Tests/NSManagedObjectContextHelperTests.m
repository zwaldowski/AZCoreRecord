//
//  NSManagedObjectContextHelperTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectContextHelperTests.h"
#import "AZCoreRecordManager.h"

@implementation NSManagedObjectContextHelperTests {
    AZCoreRecordManager *_localManager;
}

- (void)setUpClass {
    _localManager = [[AZCoreRecordManager alloc] initWithStackName: @"TestStore.storefile"];
    _localManager.stackShouldUseInMemoryStore = YES;
}

- (void)tearDownClass {
    _localManager = nil;
}

- (void) testCanCreateContextForCurrentThead
{
	NSManagedObjectContext *firstContext = [_localManager contextForCurrentThread];
	NSManagedObjectContext *secondContext = [_localManager contextForCurrentThread];
	
	assertThat(firstContext, is(equalTo(secondContext)));
}

- (void) testCanCreateChildContext
{
	NSManagedObjectContext *defaultContext = _localManager.managedObjectContext;
	NSManagedObjectContext *childContext = [defaultContext newChildContext];
	
	assertThat(childContext.parentContext, is(equalTo(defaultContext)));
}


@end
