//
//  AMKErrorHelper.h
//  TripGo
//
//  Created by Kuan Lun Huang on 17/03/2015.
//
//

@import UIKit;
@import Accounts;

@interface AMKAccountErrorHelper : NSObject

- (instancetype)initWithAccountType:(ACAccountType *)type;

- (NSError *)credentialError;
- (NSError *)accessDeniedError;
- (NSError *)accountNotFoundError;

@end
