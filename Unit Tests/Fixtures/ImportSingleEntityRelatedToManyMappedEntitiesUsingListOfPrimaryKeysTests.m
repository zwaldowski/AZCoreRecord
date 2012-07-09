//
//  ImportSingleEntityRelatedToManyMappedEntitiesUsingListOfPrimaryKeysTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 9/1/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordImportTestCase.h"
#import "MappedEntity.h"
#import "SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey.h"

@interface ImportSingleEntityRelatedToManyMappedEntitiesUsingListOfPrimaryKeysTests : AZCoreRecordImportTestCase

@end

@implementation ImportSingleEntityRelatedToManyMappedEntitiesUsingListOfPrimaryKeysTests

- (Class) testEntityClass
{
	return [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey class];
}

- (void) setupTestData
{
	NSManagedObjectContext *context = self.localManager.managedObjectContext;

	MappedEntity *related = nil;
	for (int i = 0; i < 10; i++) 
	{
		MappedEntity *testMappedEntity = [MappedEntity createInContext:context];
		testMappedEntity.testMappedEntityIDValue = i;
		testMappedEntity.sampleAttribute = [NSString stringWithFormat:@"test attribute %d", i];
		related = testMappedEntity;
	}
	
	SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *entity = [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey createInContext:context];
	entity.testPrimaryKeyValue = 84;
	[entity addMappedEntitiesObject:related];
	
	[context save];
}

- (void) testDataImport
{
	SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *testEntity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	[self.localManager.managedObjectContext save];
	
	assertThat(testEntity.mappedEntities, hasCountOf(4));
	for (MappedEntity *relatedEntity in testEntity.mappedEntities)
	{
		assertThat(relatedEntity.sampleAttribute, containsString(@"test attribute"));
	}
	
	assertThatInteger([SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey countOfEntities], is(equalToInteger(2)));
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(10)));
}

- (void) testDataUpdateWithLookupInfoInDataSet
{
	SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *testEntity = [[self testEntityClass] updateFromDictionary:self.testEntityData];
	[self.localManager.managedObjectContext save];

	assertThatInteger([SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey countOfEntities], is(equalToInteger(1)));
	assertThatInteger([MappedEntity countOfEntities], is(equalToInteger(10)));
			   
	assertThat(testEntity, is(notNilValue()));
	assertThat(testEntity.testPrimaryKey, is(equalToInteger(84)));
	assertThat(testEntity.mappedEntities, hasCountOf(5));
}

- (void) testDataUpdateWithoutLookupData
{
	SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *testEntity =
	[SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey findFirstWhere:@"testPrimaryKey" equals:[NSNumber numberWithInt:84]];
	
	assertThat(testEntity, is(notNilValue()));
	
	[testEntity updateValuesFromDictionary:self.testEntityData];
}

@end
