//
//  AMKSignUpHeader.m
//  TripGo
//
//  Created by Kuan Lun Huang on 26/02/2015.
//
//

#import "AKSignUpHeader.h"

@interface AKSignUpHeader ()

@property (nonatomic, weak) IBOutlet UIButton *facebook;
@property (nonatomic, weak) IBOutlet UIButton *twitter;

@end

@implementation AKSignUpHeader

#pragma mark - User interactions

- (IBAction)signupWithFacebook:(id)sender
{
#pragma unused (sender)
  [_delegate requestSignupUsingProvider:AKSignupProvider_Facebook];
}

- (IBAction)signupWithTwitter:(id)sender
{
#pragma unused (sender)
  [_delegate requestSignupUsingProvider:AKSignupProvider_Twitter];
}

@end
