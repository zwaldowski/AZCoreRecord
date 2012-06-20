//
//  NSManagedObjectContextHelperTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectContextHelperTests.h"
#import "AZCoreRecordManager+Private.h"

@implementation NSManagedObjectContextHelperTests

- (void)setUp
{
	[AZCoreRecord setStackShouldUseInMemoryStore:YES];
}

- (void)tearDown
{
	[AZCoreRecord azcr_cleanUp];
}

- (void) testCanCreateContextForCurrentThead
{
	NSManagedObjectContext *firstContext = [NSManagedObjectContext contextForCurrentThread];
	NSManagedObjectContext *secondContext = [NSManagedObjectContext contextForCurrentThread];
	
	assertThat(firstContext, is(equalTo(secondContext)));
}

- (void) testCanCreateChildContext
{
	NSManagedObjectContext *defaultContext = [NSManagedObjectContext defaultContext];
	NSManagedObjectContext *childContext = [defaultContext newChildContext];
	
	assertThat(childContext.parentContext, is(equalTo(defaultContext)));
}


@end
