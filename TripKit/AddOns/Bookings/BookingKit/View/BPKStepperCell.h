//
//  SGBPStepperCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 2/02/2015.
//
//

#import <UIKit/UIKit.h>

#ifdef TK_NO_MODULE
#import "TKUIStyledLabel.h"
#else
@import TripKit;
@import TripKitUI;
#endif



#import "BPKCell.h"

@interface BPKStepperCell : BPKCell <BPKFormCell>

@property (weak, nonatomic) IBOutlet TKUIStyledLabel *mainLabel;
@property (weak, nonatomic) IBOutlet TKUIStyledLabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet TKUIStyledLabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

- (void)configureForMainTitle:(NSString *)mainTitle subtitle:(NSString *)subtitle value:(double)value;

@end
