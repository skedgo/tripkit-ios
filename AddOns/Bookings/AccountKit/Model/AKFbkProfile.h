//
//  AKFbkProfile.h
//  TripGo
//
//  Created by Kuan Lun Huang on 15/09/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@import Accounts;

@class AMKFacebookHelper;

@interface AKFbkProfile : NSObject

- (nonnull AKFbkProfile *)initWithAccount:(nonnull ACAccount *)account;

- (nullable NSString *)username;
- (nullable NSString *)fullname;

@end
