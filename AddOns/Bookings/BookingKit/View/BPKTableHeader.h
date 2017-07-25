//
//  BPKTableHeader.h
//  TripKit
//
//  Created by Kuan Lun Huang on 10/02/2015.
//
//

@import UIKit;

#ifdef TK_NO_MODULE
#import "SGLabel.h"
#else
@import TripKitUI;
#endif

@interface BPKTableHeader : UIView

@property (nonatomic, weak) IBOutlet SGLabel *title;
@property (nonatomic, weak) IBOutlet SGLabel *subtitle;

- (instancetype)initWithTitle:(NSString *)title subtitle:(NSString *)subtitle tableView:(UITableView *)tableView;

@end
