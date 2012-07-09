//
//  Import SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/16/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey.h"
#import "AZCoreRecordImportTestCase.h"

@interface ImportSingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyTests : AZCoreRecordImportTestCase

@end

@implementation ImportSingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKeyTests

- (Class) testEntityClass
{
	return [SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey class];
}

- (void) testImportData
{
	SingleEntityRelatedToManyMappedEntitiesUsingMappedPrimaryKey *entity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	[self.localManager.managedObjectContext save];
	
	assertThat(entity, is(notNilValue()));
	assertThat(entity.mappedEntities, hasCountOf(4));
}

@end
