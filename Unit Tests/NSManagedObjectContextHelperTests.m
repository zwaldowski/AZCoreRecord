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
    [self prepare];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSManagedObjectContext *firstContext = [_localManager contextForCurrentThread];
        NSManagedObjectContext *secondContext = [_localManager contextForCurrentThread];
        
        assertThat(firstContext, is(equalTo(secondContext)));
        
        [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testCanCreateContextForCurrentThead)];
    });
    
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:1.0];
}

- (void) testCanCreateChildContext
{
	NSManagedObjectContext *defaultContext = _localManager.managedObjectContext;
	NSManagedObjectContext *childContext = [defaultContext newChildContext];
	
	assertThat(childContext.parentContext, is(equalTo(defaultContext)));
}


@end
