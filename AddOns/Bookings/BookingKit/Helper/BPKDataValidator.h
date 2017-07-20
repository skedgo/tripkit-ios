//
//  BPKDataValidator.h
//  TripGo
//
//  Created by Kuan Lun Huang on 31/07/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BPKSection.h"

@interface BPKDataValidator : NSObject

+ (BOOL)validateItem:(BPKSectionItem *)item;

@end
