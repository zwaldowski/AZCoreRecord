//
//  ImportSingleEntityRelatedToMappedEntityUsingDefaults.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/11/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "MappedEntity.h"
#import "SingleEntityRelatedToMappedEntityUsingDefaults.h"
#import "AZCoreRecordImportTestCase.h"

@interface ImportSingleEntityRelatedToMappedEntityUsingDefaultsTests : AZCoreRecordImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityUsingDefaultsTests

-(Class) testEntityClass
{
	return [SingleEntityRelatedToMappedEntityUsingDefaults class];
}

- (void) setupTestData
{
	NSManagedObjectContext *context = self.localManager.managedObjectContext;
	
	MappedEntity *testMappedEntity = [MappedEntity createInContext:context];
	testMappedEntity.mappedEntityIDValue = 42;
	testMappedEntity.sampleAttribute = @"This attribute created as part of the test case setup";
	
	SingleEntityRelatedToMappedEntityUsingDefaults *entity = [SingleEntityRelatedToMappedEntityUsingDefaults createInContext:context];
	entity.singleEntityRelatedToMappedEntityUsingDefaultsIDValue = 24;
	
	[context save];
}

- (void) testImportMappedEntityViaToOneRelationship
{
	SingleEntityRelatedToMappedEntityUsingDefaults *entity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	
	[self.localManager.managedObjectContext save];

	id testRelatedEntity = entity.mappedEntity;
	
	assertThat(testRelatedEntity, is(notNilValue()));
	assertThat([testRelatedEntity sampleAttribute], containsString(@"sample json file"));
	
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(2)));
}

- (void) testUpdateMappedEntity
{
	SingleEntityRelatedToMappedEntityUsingDefaults *testEntity = 
	[SingleEntityRelatedToMappedEntityUsingDefaults findFirstWhere:@"singleEntityRelatedToMappedEntityUsingDefaultsID" equals:[NSNumber numberWithInt:24]];
	
	[testEntity updateValuesFromDictionary:self.testEntityData];
	
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(1)));
	
	assertThat(testEntity, is(notNilValue()));
	
}

@end
