//
//  BPKTextPrefiller.h
//  TripKit
//
//  Created by Kuan Lun Huang on 31/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BPKSectionItem;

@interface BPKTextPrefiller : NSObject

+ (NSString *)prefillTextForItem:(BPKSectionItem *)item;

@end
