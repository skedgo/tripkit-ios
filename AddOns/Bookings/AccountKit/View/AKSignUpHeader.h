//
//  AMKSignUpHeader.h
//  TripGo
//
//  Created by Kuan Lun Huang on 26/02/2015.
//
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, AKSignupProviders) {
  AKSignupProvider_Facebook,
  AKSignupProvider_Twitter
};

@protocol AKSignUpHeaderDelegate;

@interface AKSignUpHeader : UIView

@property (nonatomic, weak) id<AKSignUpHeaderDelegate> delegate;

@end

@protocol AKSignUpHeaderDelegate <NSObject>

- (void)requestSignupUsingProvider:(AKSignupProviders)provider;

@end
