//
//  NSManagedObjectHelperTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "NSManagedObjectHelperTests.h"
#import "SingleRelatedEntity.h"
#import "AZCoreRecord.h"
#import "AZCoreRecordManager+Private.h"

@implementation NSManagedObjectHelperTests

- (void) setUp
{
	[AZCoreRecordManager azcr_cleanUp];
	[AZCoreRecordManager setStackModelName:@"TestModel.momd"];
	[AZCoreRecordManager setStackShouldUseInMemoryStore:YES];
}

- (void) tearDown
{
	[AZCoreRecordManager azcr_cleanUp];
}

-(BOOL)shouldRunOnMainThread
{
	return YES;
}
//Test Request Creation

- (void) testCreateFetchRequestForEntity
{
	NSFetchRequest *testRequest = [SingleRelatedEntity requestAll];
	
	assertThat([[testRequest entity] name], is(equalTo(NSStringFromClass([SingleRelatedEntity class]))));
}

- (void) testCanRequestFirstEntityWithPredicate
{
	NSPredicate *testPredicate = [NSPredicate predicateWithFormat:@"mappedStringAttribute = 'Test Predicate'"];
	NSFetchRequest *testRequest = [SingleRelatedEntity requestFirstWithPredicate:testPredicate];

	assertThatInteger([testRequest fetchLimit], is(equalToInteger(1)));
	assertThat([testRequest predicate], is(equalTo([NSPredicate predicateWithFormat:@"mappedStringAttribute = 'Test Predicate'"])));
}

// Test return result set, all, first

- (void) testCreateRequestForFirstEntity
{
	NSFetchRequest *testRequest = [SingleRelatedEntity requestFirstWhere:@"mappedStringAttribute" equals:nil];
	
	assertThat([[testRequest entity] name], is(equalTo(NSStringFromClass([SingleRelatedEntity class]))));
	assertThatInteger([testRequest fetchLimit], is(equalToInteger(1)));
	assertThatInteger([testRequest fetchOffset], is(equalToInteger(0)));
	assertThat([testRequest predicate], is(equalTo([NSPredicate predicateWithFormat:@"mappedStringAttribute = nil"])));
}

- (void) testCanGetEntityDescriptionFromEntityClass
{
	NSEntityDescription *testDescription = [SingleRelatedEntity entityDescription];
	assertThat(testDescription, is(notNilValue()));
}

// Test Entity creation

- (void) testCanCreateEntityInstance
{
	id testEntity = [SingleRelatedEntity create];
	
	assertThat(testEntity, is(notNilValue()));
}

// Test Entity Deletion

- (void) testCanDeleteEntityInstance
{
	id testEntity = [SingleRelatedEntity create];
	[[NSManagedObjectContext defaultContext] save];
	
	assertThatBool([testEntity isDeleted], is(equalToBool(NO)));
	
	[testEntity delete];
	
	assertThat(testEntity, is(notNilValue()));
	assertThatBool([testEntity isDeleted], is(equalToBool(YES)));
}

// Test Number of Entities

- (void) createSampleData:(NSInteger)numberOfTestEntitiesToCreate
{
	for (int i = 0; i < numberOfTestEntitiesToCreate; i++)
	{
		SingleRelatedEntity *testEntity = [SingleRelatedEntity create];
		testEntity.mappedStringAttribute = [NSString stringWithFormat:@"%i", i / 5];
	}
	
	[[NSManagedObjectContext defaultContext] save];
}

- (void) testCanSearchForNumberOfAllEntities
{
	NSInteger numberOfTestEntitiesToCreate = 20;
	[self createSampleData:numberOfTestEntitiesToCreate];
	
	assertThatInteger([SingleRelatedEntity countOfEntities], is(equalToInteger(numberOfTestEntitiesToCreate)));
}

- (void) testCanSearchForNumberOfEntitiesWithPredicate
{
	NSInteger numberOfTestEntitiesToCreate = 20;
	[self createSampleData:numberOfTestEntitiesToCreate];

	NSPredicate *searchFilter = [NSPredicate predicateWithFormat:@"mappedStringAttribute = '1'"];
	assertThatInteger([SingleRelatedEntity countOfEntitiesWithPredicate:searchFilter], is(equalToInteger(5)));

}

@end
