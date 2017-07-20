//
//  SGBPStepperCell.h
//  TripGo
//
//  Created by Kuan Lun Huang on 2/02/2015.
//
//

#import <UIKit/UIKit.h>

#ifdef TK_NO_FRAMEWORKS
#import "SGLabel.h"
#else
@import TripKit;
@import TripKitUI;
#endif



#import "BPKCell.h"

@interface BPKStepperCell : BPKCell <BPKFormCell>

@property (weak, nonatomic) IBOutlet SGLabel *mainLabel;
@property (weak, nonatomic) IBOutlet SGLabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet SGLabel *valueLabel;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;

- (void)configureForMainTitle:(NSString *)mainTitle subtitle:(NSString *)subtitle value:(double)value;

@end
