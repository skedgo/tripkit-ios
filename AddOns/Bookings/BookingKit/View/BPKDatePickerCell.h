//
//  SGPayPickerCell.h
//  TripGo
//
//  Created by Kuan Lun Huang on 29/01/2015.
//
//

#import <UIKit/UIKit.h>

#import "BPKCell.h"

@interface BPKDatePickerCell : BPKCell <BPKFormCell>

- (void)configureForDate:(NSDate *)date;

@end
