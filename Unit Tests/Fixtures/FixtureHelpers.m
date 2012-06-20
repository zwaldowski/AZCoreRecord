//
//  FixtureHelpers.m
//  AZCoreRecord Unit Tests
//
//  Created by Saul Mora on 7/15/11.
//  Copyright 2010-2011 Magical Panda Software, LLC. All rights reserved.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import "FixtureHelpers.h"

@implementation FixtureHelpers

+ (id) dataFromJSONFixtureNamed:(NSString *)fixtureName
{
	NSString *resource = [[NSBundle mainBundle] pathForResource:fixtureName ofType:@"json"];
	NSData *jsonData = [NSData dataWithContentsOfFile:resource];
	
	NSError *error = nil;
	id obj = [NSJSONSerialization JSONObjectWithData: jsonData options: 0 error: &error];
	
	[AZCoreRecord handleError:error];
	
	return obj;
}

@end

@implementation GHTestCase (FixtureHelpers)

- (id) dataFromJSONFixture
{
	NSString *className = NSStringFromClass([self class]);
	className = [className stringByReplacingOccurrencesOfString:@"Import" withString:@""];
	className = [className stringByReplacingOccurrencesOfString:@"Tests" withString:@""];
	return [FixtureHelpers dataFromJSONFixtureNamed:className];
}

@end
