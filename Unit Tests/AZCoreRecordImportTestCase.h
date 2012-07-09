//
//  AZCoreRecordImportTestCase.h
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 8/16/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	#import <GHUnit/GHUnit.h>
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
	#import <GHUnitIOS/GHUnit.h>
#endif

#import "AZCoreRecord.h"

@interface AZCoreRecordImportTestCase : GHTestCase

@property (nonatomic, retain) AZCoreRecordManager *localManager;
@property (nonatomic, retain) id testEntityData;
@property (nonatomic, retain) id testEntity;

- (Class) testEntityClass;

@end
