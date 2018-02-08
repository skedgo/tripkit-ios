//
//  STKMiniInstruction.h
//  TripKit
//
//  Created by Adrian Schoenig on 8/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STKMiniInstruction : NSObject <NSCoding>

// these get stored
@property (nonatomic, copy, nonnull) NSString *instruction;
@property (nonatomic, copy, nullable) NSString *mainValue;
@property (nonatomic, copy, nullable) NSString *detail;

+ (nullable STKMiniInstruction *)miniInstructionForDictionary:(nullable NSDictionary *)dictionary;

@end
