//
//  AMKItemCell.h
//  TripGo
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#ifndef TripGo_AKItemCell_h
#define TripGo_AKItemCell_h

#import "AMKItem.h"

@protocol AKItemCell <NSObject>

@property (nonatomic, strong) AMKItem *item;

- (void)configureForItem:(AMKItem *)item;

@end

#endif
