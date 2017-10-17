//
//  TKUISheetViewController.h
//  TripKit
//
//  Created by Adrian Schoenig on 24/09/13.
//
//

@import UIKit;

@class TKUISheet;

NS_ASSUME_NONNULL_BEGIN

@interface TKUISheetViewController : UIViewController

- (instancetype)initWithSheet:(TKUISheet *)Sheet;

- (nullable TKUISheet *)sheet;

@end

NS_ASSUME_NONNULL_END
