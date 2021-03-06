//
//  ImportSingleEntityWithRelatedEntitiesTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/23/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "SingleRelatedEntity.h"
#import "AbstractRelatedEntity.h"
#import "ConcreteRelatedEntity.h"
#import "MappedEntity.h"
#import "AZCoreRecordImportTestCase.h"

@interface ImportSingleRelatedEntityTests : AZCoreRecordImportTestCase

@property (nonatomic, retain) SingleRelatedEntity *singleTestEntity;

@end

@implementation ImportSingleRelatedEntityTests

@synthesize singleTestEntity = _singleTestEntity;

- (void) setupTestData
{
	NSManagedObjectContext *context = self.localManager.managedObjectContext;
	
	MappedEntity *testMappedEntity = [MappedEntity createInContext:context];
	testMappedEntity.testMappedEntityIDValue = 42;
	testMappedEntity.sampleAttribute = @"This attribute created as part of the test case setup";
	
	[context save];
}

- (void) setUp
{
	[super setUp];
	
	self.singleTestEntity = [SingleRelatedEntity importFromDictionary:self.testEntityData];
	[self.localManager.managedObjectContext save];
}

- (void) testImportAnEntityRelatedToAbstractEntityViaToOneRelationshop
{
	assertThat(self.singleTestEntity, is(notNilValue()));

	id testRelatedEntity = self.singleTestEntity.testAbstractToOneRelationship;
	
	assertThat(testRelatedEntity, is(notNilValue()));
	assertThat([testRelatedEntity sampleBaseAttribute], containsString(@"BASE"));
	assertThatBool([testRelatedEntity respondsToSelector:@selector(sampleConcreteAttribute)], is(equalToBool(NO)));
}

- (void) testImportAnEntityRelatedToAbstractEntityViaToManyRelationship
{
	assertThat(self.singleTestEntity, is(notNilValue()));
	assertThatInteger([self.singleTestEntity.testAbstractToManyRelationship count], is(equalToInteger(2)));
	
	id testRelatedEntity = [self.singleTestEntity.testAbstractToManyRelationship anyObject];
	
	assertThat(testRelatedEntity, is(notNilValue()));
	assertThat([testRelatedEntity sampleBaseAttribute], containsString(@"BASE"));
	assertThatBool([testRelatedEntity respondsToSelector:@selector(sampleConcreteAttribute)], is(equalToBool(NO)));
}


#pragma mark - Subentity tests


- (void) testImportAnEntityRelatedToAConcreteSubEntityViaToOneRelationship
{
	id testRelatedEntity = self.singleTestEntity.testConcreteToOneRelationship;
	assertThat(testRelatedEntity, is(notNilValue()));
	
	assertThat([testRelatedEntity sampleBaseAttribute], containsString(@"BASE"));
	assertThat([testRelatedEntity sampleConcreteAttribute], containsString(@"DESCENDANT"));
}

- (void) testImportAnEntityRelatedToASubEntityViaToManyRelationship
{
	assertThatInteger([self.singleTestEntity.testConcreteToManyRelationship count], is(equalToInteger(3)));
	
	id testRelatedEntity = [self.singleTestEntity.testConcreteToManyRelationship anyObject];
	assertThat(testRelatedEntity, is(notNilValue()));
	
	assertThat([testRelatedEntity sampleBaseAttribute], containsString(@"BASE"));
	assertThat([testRelatedEntity sampleConcreteAttribute], containsString(@"DESCENDANT"));
}


//Test ordered to many




@end
