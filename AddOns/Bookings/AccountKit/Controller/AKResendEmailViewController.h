//
//  SGEmailReminderViewController.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol AKResendEmailViewControllerDelegate;

@interface AKResendEmailViewController : UITableViewController

@property (nonatomic, copy) NSString *email;

@property (nonatomic, weak) id<AKResendEmailViewControllerDelegate> delegate;

@end

@protocol AKResendEmailViewControllerDelegate <NSObject>

- (void)resendEmailViewControllerDidRemoveEmail;

@end
