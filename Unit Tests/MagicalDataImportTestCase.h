//
//  MagicalDataImportTestCase.h
//  MagicalRecord
//
//  Created by Saul Mora on 8/16/11.
//  Copyright (c) 2011 Magical Panda Software LLC. All rights reserved.
//

#ifdef __MAC_OS_X_VERSION_MIN_REQUIRED
	#import <GHUnit/GHUnit.h>
#elif defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
	#import <GHUnitIOS/GHUnit.h>
#endif

@interface MagicalDataImportTestCase : GHTestCase

@property (nonatomic, retain) id testEntityData;
@property (nonatomic, retain) id testEntity;

- (Class) testEntityClass;

@end
