//
//  BPKMessageCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 16/03/2015.
//
//

#import <UIKit/UIKit.h>

#import "BPKCell.h"

@interface BPKMessageCell : BPKCell <BPKFormCell>

@property (weak, nonatomic) IBOutlet UILabel *label;

@end
