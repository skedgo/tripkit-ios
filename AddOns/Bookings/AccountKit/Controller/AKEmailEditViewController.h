//
//  SGUserAccountNewEmailViewController.h
//  WotGo
//
//  Created by Kuan Lun Huang on 15/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AKBaseTableViewController.h"

@protocol AKEmailEditViewControllerDelegate;

@interface AKEmailEditViewController : AKBaseTableViewController

@property (nonatomic, copy) NSString *editedEmail;

@property (nonatomic, weak) id<AKEmailEditViewControllerDelegate> delegate;

@end

@protocol AKEmailEditViewControllerDelegate <NSObject>

- (void)emailEditViewControllerDidAddEmail:(NSString *)email;

@optional

- (void)emailEditViewControllerDidRemoveEmail:(NSString *)email;
- (void)emailEditViewControllerDidMarkAsPrimary:(NSString *)email;

@end
