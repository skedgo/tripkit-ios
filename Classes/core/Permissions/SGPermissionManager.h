//
//  SGPermissionManager.h
//  Welcome
//
//  Created by Adrian Schoenig on 4/09/12.
//  Copyright (c) 2012 Adrian Schoenig. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^SGPermissionCompletionBlock)(BOOL enabled);
typedef void(^SGPermissionsOpenSettingsHandler)(void);

typedef NS_ENUM(NSInteger, SGAuthorizationStatus) {
  SGAuthorizationStatusNotDetermined = 0,
  SGAuthorizationStatusRestricted,
  SGAuthorizationStatusDenied,
  SGAuthorizationStatusAuthorized
};

FOUNDATION_EXPORT NSString *const SGPermissionsChangedNotification;

@interface SGPermissionManager : NSObject

@property (nonatomic, strong) SGPermissionsOpenSettingsHandler openSettingsHandler;

// these are the main interface methods

/**
 * Is the app capable and authorized to use these kind of permissions?
 */
- (BOOL)isAuthorized;

// subclasses need to implement these
- (BOOL)featureIsAvailable;
- (void)askForPermission:(SGPermissionCompletionBlock)completion;
- (BOOL)authorizationRestrictionsApply;
- (SGAuthorizationStatus)authorizationStatus;
- (NSString *)authorizationAlertText;

@end
