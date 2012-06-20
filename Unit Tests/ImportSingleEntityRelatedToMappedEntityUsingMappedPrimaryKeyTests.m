//
//  ImportSingleEntityRelatedToMappedEntityUsingMappedPrimaryKey.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/11/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "MappedEntity.h"
#import "SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey.h"
#import "AZCoreRecordImportTestCase.h"

@interface ImportSingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyTests : AZCoreRecordImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityUsingMappedPrimaryKeyTests

- (void) setupTestData
{
	NSManagedObjectContext *context = [NSManagedObjectContext defaultContext];
	
	MappedEntity *testMappedEntity = [MappedEntity createInContext:context];
	testMappedEntity.testMappedEntityIDValue = 42;
	testMappedEntity.sampleAttribute = @"This attribute created as part of the test case setup";
	
	[context save];
}

- (Class) testEntityClass
{
	return [SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey class];
}

- (void) testImportMappedEntityRelatedViaToOneRelationship
{
	SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey *entity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	[[NSManagedObjectContext defaultContext] save];
	
	id testRelatedEntity = entity.mappedEntity;
	
	//verify mapping in relationship description userinfo
	NSEntityDescription *mappedEntity = [entity entity];
	NSRelationshipDescription *testRelationship = [[mappedEntity propertiesByName] valueForKey:@"mappedEntity"];
	assertThat([[testRelationship userInfo] valueForKey: AZCoreRecordImportMapKey], is(equalTo(@"someRandomAttributeName")));
	
	assertThatInteger([SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey countOfEntities], is(equalToInteger(1)));
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(2)));
	assertThat(testRelatedEntity, is(notNilValue()));
	assertThat([testRelatedEntity sampleAttribute], is(containsString(@"sample json file")));	
}

- (void) testUpdateMappedEntityRelatedViaToOneRelationship
{
	SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey *entity = [SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey create];
	[entity updateValuesFromDictionary:self.testEntityData];
	[[NSManagedObjectContext defaultContext] save];
	
	id testRelatedEntity = entity.mappedEntity;
	
	//verify mapping in relationship description userinfo
	NSEntityDescription *mappedEntity = [entity entity];
	NSRelationshipDescription *testRelationship = [[mappedEntity propertiesByName] valueForKey:@"mappedEntity"];
	assertThat([[testRelationship userInfo] valueForKey: AZCoreRecordImportMapKey], is(equalTo(@"someRandomAttributeName")));
	
	assertThatInteger([SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey countOfEntities], is(equalToInteger(1)));
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(1)));
	assertThat(testRelatedEntity, is(notNilValue()));
	assertThat([testRelatedEntity sampleAttribute], is(containsString(@"sample json file")));
}

- (void) testImportMappedEntityUsingPrimaryRelationshipKey
{
	SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey *entity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	[[NSManagedObjectContext defaultContext] save];
	
	id testRelatedEntity = entity.mappedEntity;
	
	//verify mapping in relationship description userinfo
	NSEntityDescription *mappedEntity = [entity entity];
	NSRelationshipDescription *testRelationship = [[mappedEntity propertiesByName] valueForKey:@"mappedEntity"];
	assertThat([[testRelationship userInfo] valueForKey: AZCoreRecordImportRelationshipPrimaryKey], is(equalTo(@"testMappedEntityID")));
	
	assertThatInteger([SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey countOfEntities], is(equalToInteger(1)));
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(2)));
	assertThat([testRelatedEntity testMappedEntityID], is(equalToInteger(42)));
	assertThat([testRelatedEntity sampleAttribute], containsString(@"sample json file"));	
}

- (void) testUpdateMappedEntityUsingPrimaryRelationshipKey
{
	SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey *entity = [SingleEntityRelatedToMappedEntityUsingMappedPrimaryKey create];
	[entity updateValuesFromDictionary:self.testEntityData];
	[[NSManagedObjectContext defaultContext] save];
	
	id testRelatedEntity = entity.mappedEntity;
	
	//verify mapping in relationship description userinfo
	NSEntityDescription *mappedEntity = [entity entity];
	NSRelationshipDescription *testRelationship = [[mappedEntity propertiesByName] valueForKey:@"mappedEntity"];
	assertThat([[testRelationship userInfo] valueForKey: AZCoreRecordImportRelationshipPrimaryKey], is(equalTo(@"testMappedEntityID")));
	
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(1)));
	assertThat([testRelatedEntity testMappedEntityID], is(equalToInteger(42)));
	assertThat([testRelatedEntity sampleAttribute], containsString(@"sample json file"));
}


@end
