//
//  SGUserAccountSection.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AMKItem;

@interface AMKSection : NSObject

@property (nonatomic, strong, readonly) NSArray *items;
@property (nonatomic, copy) NSString *headerText;
@property (nonatomic, copy) NSString *footerText;

- (void)addItem:(AMKItem *)item;

@end
