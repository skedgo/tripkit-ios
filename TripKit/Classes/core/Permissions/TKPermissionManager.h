//
//  TKPermissionManager.h
//  Welcome
//
//  Created by Adrian Schoenig on 4/09/12.
//  Copyright (c) 2012 Adrian Schoenig. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^SGPermissionCompletionBlock)(BOOL enabled);
typedef void(^SGPermissionsOpenSettingsHandler)(void);

typedef NS_ENUM(NSInteger, SGAuthorizationStatus) {
  SGAuthorizationStatusNotDetermined = 0,
  SGAuthorizationStatusRestricted,
  SGAuthorizationStatusDenied,
  SGAuthorizationStatusAuthorized
};

FOUNDATION_EXPORT NSString *const SGPermissionsChangedNotification;

@interface TKPermissionManager : NSObject

@property (nonatomic, strong, nullable) SGPermissionsOpenSettingsHandler openSettingsHandler;

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

NS_ASSUME_NONNULL_END
