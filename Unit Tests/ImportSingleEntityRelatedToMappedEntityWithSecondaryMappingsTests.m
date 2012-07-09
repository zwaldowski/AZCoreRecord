//
//  ImportSingleEntityRelatedToMappedEntityWithSecondaryMappingsTests.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/18/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "AZCoreRecordImportTestCase.h"
#import "SingleEntityRelatedToMappedEntityWithSecondaryMappings.h"
#import "MappedEntity.h"

@interface ImportSingleEntityRelatedToMappedEntityWithSecondaryMappingsTests : AZCoreRecordImportTestCase

@end

@implementation ImportSingleEntityRelatedToMappedEntityWithSecondaryMappingsTests

- (Class) testEntityClass
{
	return [SingleEntityRelatedToMappedEntityWithSecondaryMappings class];
}

- (void) testImportMappedAttributeUsingSecondaryMappedKeyName
{
	SingleEntityRelatedToMappedEntityWithSecondaryMappings *entity = [[self testEntityClass] importFromDictionary:self.testEntityData];
	[self.localManager.managedObjectContext save];
	
	assertThat(entity, is(notNilValue()));
	assertThat([entity secondaryMappedAttribute], containsString(@"sample json file"));
}

@end
