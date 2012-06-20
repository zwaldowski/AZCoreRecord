//
//  ImportSingleEntityRelatedToMappedEntityWithNestedMappedAttributesTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/16/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//


#import "AZCoreRecordImportTestCase.h"
#import "MappedEntity.h"
#import "SingleEntityRelatedToMappedEntityWithNestedMappedAttributes.h"

@interface ImportSingleEntityRelatedToMappedEntityWithNestedMappedAttributesTests : AZCoreRecordImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityWithNestedMappedAttributesTests

- (Class) testEntityClass
{
	return [SingleEntityRelatedToMappedEntityWithNestedMappedAttributes class];
}

- (void) testDataImport
{
	SingleEntityRelatedToMappedEntityWithNestedMappedAttributes *entity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	[[NSManagedObjectContext defaultContext] save];
	
	assertThat(entity.mappedEntity, is(notNilValue()));
	assertThat(entity.mappedEntity.mappedEntityID, is(equalToInteger(42)));
	assertThat(entity.mappedEntity.nestedAttribute, containsString(@"nested value"));
}

@end
