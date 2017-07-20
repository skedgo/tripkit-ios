//
//  BPKTextFieldHelper.h
//  TripGo
//
//  Created by Kuan Lun Huang on 18/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BPKBookingViewController.h"

@interface BPKTextFieldHelper : NSObject

@property (nonatomic, assign) BOOL willMoveToNext;
@property (nonatomic, assign) BOOL disableMoveToNextOnReturn;

- (instancetype)initWithForm:(BPKBookingViewController *)form;

- (BOOL)requiresTextFieldCellAtIndexPath:(NSIndexPath *)indexPath;

- (void(^)(UITextField *))isEditingBlockForIndexPath:(NSIndexPath *)indexPath;
- (void(^)(UITextField *))didEndEditingBlockForIndexPath:(NSIndexPath *)indexPath;
- (BOOL(^)(UITextField *))shouldReturnBlockForIndexPath:(NSIndexPath *)indexPath;

@end
