//
//  AZCoreRecordUbiquitySentinel.h
//  AZCoreRecord
//
//  Created by Zachary Waldowski on 6/22/12.
//  Copyright 2012 The Mental Faculty BV. Licensed under BSD.
//  Copyright 2012 Alexsander Akers & Zachary Waldowski. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const AZUbiquityIdentityDidChangeNotification;

@interface AZCoreRecordUbiquitySentinel : NSObject <NSFilePresenter>

+ (AZCoreRecordUbiquitySentinel *)sharedSentinel;

@property (nonatomic, readonly) NSString *ubiquityIdentityToken;
@property (nonatomic, readonly, getter = isUbiquityAvailable) BOOL ubiquityAvailable;

@end
