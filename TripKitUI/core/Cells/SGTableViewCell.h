//
//  SGTableViewCell.h
//  WotGo
//
//  Created by Brian Huang on 13/07/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
  kSGTableViewCellContentViewAutoDimension  = 0
};

@protocol SGTableViewCellContentView <NSObject>

@property (nonatomic, assign) CGSize preferredContentSize;

@end

@protocol SGTableViewCell <NSObject>

+ (UINib *)nib;
+ (NSString *)reuseId;

- (void)configureWithObject:(id)object;

@end

@interface SGTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIView *topContainer;
@property (nonatomic, weak) IBOutlet UIView *bottomContainer;
@property (nonatomic, weak) IBOutlet UIView *middleLeftView;
@property (nonatomic, weak) IBOutlet UIView *middleCenterView;
@property (nonatomic, weak) IBOutlet UIView *middleRightView;

+ (UINib *)nib;

+ (NSString *)reuseId;

+ (CGFloat)cellHeightWithTop:(id<SGTableViewCellContentView>)top
                  middleLeft:(id<SGTableViewCellContentView>)middleLeft
                middleCenter:(id<SGTableViewCellContentView>)middleCenter
                 middleRight:(id<SGTableViewCellContentView>)middleRight
                      bottom:(id<SGTableViewCellContentView>)bottom;

- (void)configureCellWithTop:(id<SGTableViewCellContentView>)top
                  middleLeft:(id<SGTableViewCellContentView>)middleLeft
                middleCenter:(id<SGTableViewCellContentView>)middleCenter
                 middleRight:(id<SGTableViewCellContentView>)middleRight
                      bottom:(id<SGTableViewCellContentView>)bottom;

- (void)setContentInsets:(UIEdgeInsets)contentInsets;

@end
