//
//  AMKSimpleSignUpViewController.h
//  TripKit
//
//  Created by Kuan Lun Huang on 26/02/2015.
//
//

#import <UIKit/UIKit.h>

#import "AKBaseTableViewController.h"

@protocol AKSignUpViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface AKSignUpViewController : AKBaseTableViewController

@property (nonatomic, weak, nullable) id<AKSignUpViewControllerDelegate> delegate;

@end

@protocol AKSignUpViewControllerDelegate <NSObject>

- (void)signUpViewController:(AKSignUpViewController *)ctr didSignUpUser:(AMKUser *)user;

@end

NS_ASSUME_NONNULL_END
