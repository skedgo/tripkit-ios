//
//  AMKItemCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#ifndef TripKit_AKItemCell_h
#define TripKit_AKItemCell_h

#import "AMKItem.h"

@protocol AKItemCell <NSObject>

@property (nonatomic, strong) AMKItem *item;

- (void)configureForItem:(AMKItem *)item;

@end

#endif
