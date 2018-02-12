//
//  SGPaymentSwitchCell.h
//  TripKit
//
//  Created by Kuan Lun Huang on 27/01/2015.
//
//

#import <UIKit/UIKit.h>

#ifdef TK_NO_MODULE
#import "SGLabel.h"
#else
@import TripKit;
@import TripKitUI;
#endif

#import "BPKCell.h"


@interface BPKSwitchCell : BPKCell <BPKFormCell>

@property (weak, nonatomic) IBOutlet SGLabel *prompt;
@property (weak, nonatomic) IBOutlet UISwitch *switchControl;

- (void)configureForPrompt:(NSString *)prompt switchValue:(BOOL)onOrOff;

@end
