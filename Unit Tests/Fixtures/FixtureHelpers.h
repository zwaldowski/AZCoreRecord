//
//  FixtureHelpers.h
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

@interface FixtureHelpers : NSObject

+ (id) dataFromJSONFixtureNamed:(NSString *)fixtureName;

@end


@interface GHTestCase (FixtureHelpers)

- (id) dataFromJSONFixture;

@end