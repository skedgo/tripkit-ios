//
//  TKInterAppCommunicator.m
//  TripKit
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKInterAppCommunicator.h"

@import MessageUI;

#ifndef TK_NO_MODULE
@import TripKit;
#import <TripKitInterApp/TripKitInterApp-Swift.h>
#else
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#endif

#import "TKConfig+TKInterAppCommunicator.h"

@interface ComposerDelegate : NSObject <MFMessageComposeViewControllerDelegate>
+ (ComposerDelegate *)sharedInstance;
@end

@implementation TKInterAppCommunicator

#pragma mark - Taxi helpers

+ (BOOL)canHandleExternalActions:(TKSegment *)segment
{
  for (NSString *action in segment.bookingExternalActions) {
    if ([self titleForExternalAction:action]) {
      return true;
    }
  }
  return false;
}

+ (void)handleExternalActions:(TKSegment * __nonnull)segment
            forViewController:(UIViewController * __nonnull)controller
                  initiatedBy:(nullable id)sender
       currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
               openURLHandler:(nullable void (^)(NSURL * __nonnull, NSString * __nullable))openURLHandler
             openStoreHandler:(nullable void (^)(NSNumber * __nonnull))openStoreHandler
            completionHandler:(nullable void (^)(NSString * _Nonnull))completionHandler
{
  NSArray *externalActions = segment.bookingExternalActions;
  NSArray *sorted = [self sortedExternalActionsForUnsorted:externalActions];
  if (sorted.count == 1) {
    NSString *action = [sorted firstObject];
    NSString *title = [self titleForExternalAction:action];
    [TKInterAppCommunicator performExternalAction:action
                                           titled:title
                                       forSegment:segment
                                forViewController:controller
                           currentLocationHandler:currentLocationHandler
                                   openURLHandler:openURLHandler
                                 openStoreHandler:openStoreHandler];
    if (completionHandler) {
      completionHandler(action);
    }
    return;
  }
  
  __weak TKSegment *actionSegment = segment;
  
  TKActions *actions = [[TKActions alloc] init];
  for (NSString *action in [self sortedExternalActionsForUnsorted:externalActions]) {
    NSString *title = [self titleForExternalAction:action];
    if (title.length > 0) {
      [actions addAction:title
                 handler:
       ^{
         [TKInterAppCommunicator performExternalAction:action
                                                titled:title
                                            forSegment:actionSegment
                                     forViewController:controller
                                currentLocationHandler:currentLocationHandler
                                        openURLHandler:openURLHandler
                                      openStoreHandler:openStoreHandler];
         if (completionHandler) {
           completionHandler(action);
         }
       }];
    }
  }
  
  actions.hasCancel = YES;
  [actions showForSender:sender
            inController:controller];
}

+ (NSString *)titleForExternalAction:(NSString *)action
{
  if ([action isEqualToString:@"gocatch"]) {
    return Loc.GoCatchAction;
    
  } else if ([action isEqualToString:@"uber"]) {
    return [Loc BookWithService:@"Uber"];
    
  } else if ([action isEqualToString:@"ingogo"]) {
    return [self deviceHasIngogo] ? Loc.IngogoAction : [Loc GetAppNamed:@"ingogo"];
    
  } else if ([action hasPrefix:@"lyft"]) { // also lyft_line, etc.
    return [self deviceHasLyft] ? [Loc OpenAppNamed:@"Lyft"] : [Loc GetAppNamed:@"Lyft"];
    
  } else if ([action isEqualToString:@"ola"]) {
    return [self deviceHasOla]
    ? [Loc OpenAppNamed:@"Ola"] : [Loc GetAppNamed:@"Ola"];

  } else if ([action isEqualToString:@"flitways"]) {
    return [Loc BookWithService:@"FlitWays"];

  } else if ([action hasPrefix:@"tel:"] && [self canCall]) {
    NSRange nameRange = [action rangeOfString:@"name="];
    if (nameRange.location != NSNotFound) {
      NSString *name = [action substringFromIndex:nameRange.location + nameRange.length];
      name = [name stringByRemovingPercentEncoding];
      return [Loc CallService:name];
    } else {
      return Loc.Call;
    }
    
  } else if ([action hasPrefix:@"sms:"] && [self canSendSMS]) {
    return Loc.SendSMS;
    
  } else if ([action hasPrefix:@"http:"] || [action hasPrefix:@"https:"]) {
    return Loc.ShowWebsite;
    
  } else {
    return nil;
  }
}

+ (void)performExternalAction:(NSString *)action
                       titled:(NSString *)title
                   forSegment:(nullable TKSegment *)segment
            forViewController:(UIViewController * __nonnull)controller
       currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
               openURLHandler:(nullable void (^)(NSURL *url, NSString * __nullable title))openURLHandler
             openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
  if ([action isEqualToString:@"gocatch"] && segment) {
    [self launchGoCatchForSegment:segment
                 openStoreHandler:openStoreHandler];
    
  } else if ([action isEqualToString:@"uber"] && segment) {
    [self launchUberForSegment:segment
        currentLocationHandler:currentLocationHandler
                openURLHandler:openURLHandler];

  } else if ([action isEqualToString:@"ola"] && segment) {
    [self launchOlaForSegment:segment
             openStoreHandler:openStoreHandler];
    
  } else if ([action isEqualToString:@"ingogo"] && segment) {
    [self launchIngogoForSegment:segment
                openStoreHandler:openStoreHandler];
    
  } else if ([action hasPrefix:@"lyft"] && segment) { // also lyft_line, etc.
    [self launchLyftForSegment:segment
                      rideType:action
              openStoreHandler:openStoreHandler];
    
  } else if ([action isEqualToString:@"flitways"] && segment) {
    [self launchFlitWaysForSegment:segment
                    openURLHandler:openURLHandler];
    
  } else if ([action hasPrefix:@"tel:"]) {
    if ([self canCall]) {
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[action stringByReplacingOccurrencesOfString:@" " withString:@"-"]] options:@{} completionHandler:nil];
    }
    
  } else if ([action hasPrefix:@"sms:"]) {
    if ([self canSendSMS]) {
      [self composeSMS:action forViewController:controller];
    }
    
  } else if ([action hasPrefix:@"http:"] || [action hasPrefix:@"https:"]) {
    NSURL *url = [NSURL URLWithString:action];
    if (openURLHandler) {
      openURLHandler(url, title);
    } else {
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
    
  } else {
    ZAssert(false, @"Unhandled action!");
  }
}

+ (NSArray *)sortedExternalActionsForUnsorted:(NSArray *)actions
{
  NSMutableArray *sortedActions = [NSMutableArray arrayWithCapacity:actions.count];
  BOOL startIndex = 0;
  BOOL canCall = [self canCall];
  BOOL addedLyft = NO;
  for (NSString *action in actions) {
    if (!canCall && [action hasPrefix:@"tel:"]) {
      continue;
    }
    
    if ([action isKindOfClass:[NSNull class]]) {
      continue;
    }

    if ([action hasPrefix:@"lyft"]) {
      if (addedLyft) {
        continue;
      }
      addedLyft = YES;
    }
    
    if (   ([action isEqualToString:@"gocatch"]  && [self deviceHasGoCatch])
        || ([action isEqualToString:@"ingogo"]   && [self deviceHasIngogo])
        || ([action isEqualToString:@"uber"]     && [self deviceHasUber])
        || ([action isEqualToString:@"flitways"] && [self deviceHasFlitWays])
        || ([action isEqualToString:@"ola"]      && [self deviceHasOla])
        || ([action hasPrefix:@"lyft"]           && [self deviceHasLyft]) // also lyft_line, etc.
        ) {
      [sortedActions insertObject:action atIndex:startIndex++];
    } else {
      [sortedActions addObject:action];
    }
  }
  return sortedActions;
}

+ (BOOL)deviceHasIngogo
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"ingogo:"]];
}

+ (BOOL)deviceHasGoCatch
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"gocatch:"]];
}

+ (BOOL)deviceHasOla
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"olacabs:"]];
}

+ (BOOL)deviceHasUber
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"uber:"]];
}

+ (BOOL)deviceHasLyft
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"lyft:"]];
}

+ (BOOL)deviceHasFlitWays
{
  return NO;
}

+ (void)launchGoCatchForSegment:(TKSegment *)segment
               openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
  CLLocationCoordinate2D pickup  = [[segment start] coordinate];
  CLLocationCoordinate2D dropoff = [[segment end] coordinate];
  
  // try fetching the destination suburb
  CLLocation *destination = [[CLLocation alloc] initWithLatitude:dropoff.latitude
                                                       longitude:dropoff.longitude];
  
  CLGeocoder *geocoder = [[CLGeocoder alloc] init];
  [geocoder reverseGeocodeLocation:destination
                 completionHandler:
   ^(NSArray *placemarks, NSError *error) {
#pragma unused(error)
     NSString *destinationSuburb = @"";
     for (CLPlacemark *placemark in placemarks) {
       destinationSuburb = [TKLocationHelper suburbForPlacemark:placemark];
       if (destinationSuburb.length > 0)
         break;
     }
     
     NSString *referralCode = [[TKConfig sharedInstance] gocatchReferralCode];
     if (! referralCode) {
       referralCode = @"";
     }
     
     if ([self deviceHasGoCatch]) {
       // open app directly
       NSString *urlString = [NSString stringWithFormat:@"gocatch://referral?code=%@&destination=%@&pickup=%@&lat=%f&lng=%f",
                              referralCode,
                              [destinationSuburb stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                              @"", // pickup address
                              pickup.latitude,
                              pickup.longitude];
       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
     } else {
       // open app store
       if (openStoreHandler) {
         openStoreHandler(@(TKInterAppCommunicatorITunesAppIDGoCatch));
       } else {
         NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/au/app/gocatch/id%d?mt=8", TKInterAppCommunicatorITunesAppIDGoCatch];
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString] options:@{} completionHandler:nil];
       }
     }
     
   }];
}

+ (void)launchIngogoForSegment:(TKSegment *)segment
             openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
#pragma unused(segment) // ingogo doesn't support that yet
  
  if ([self deviceHasIngogo]) {
    // just launch it
    NSString *urlString = @"ingogo://";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    
  } else {
    if (openStoreHandler) {
      openStoreHandler(@(TKInterAppCommunicatorITunesAppIDIngogo));
    } else {
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ingogo.mobi"] options:@{} completionHandler:nil];
    }
  }
}

+ (void)launchUberForSegment:(TKSegment *)segment
      currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
              openURLHandler:(nullable void (^)(NSURL *url, NSString * __nullable title))openURLHandler
{
  if ([self deviceHasUber]) {
    // https://developer.uber.com/v1/deep-linking/#ios
    
    NSMutableString *urlString = [NSMutableString stringWithString:@"uber://?action=setPickup"];
    
    // from
    if (currentLocationHandler == nil || currentLocationHandler(segment)) {
      [urlString appendString:@"&pickup=my_location"];
    } else {
      id<MKAnnotation> startAnnotation = [segment start];
      CLLocationCoordinate2D start = [startAnnotation coordinate];
      [urlString appendFormat:@"&pickup[latitude]=%.5f&pickup[longitude]=%.5f", start.latitude, start.longitude];
      if ([startAnnotation respondsToSelector:@selector(title)]) {
        NSString *title = [startAnnotation title];
        if (title.length > 0) {
          NSString *encoded = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
          [urlString appendFormat:@"&pickup[nickname]=%@", encoded];
        }
      }
    }
    
    // to
    id<MKAnnotation> endAnnotation = [segment end];
    CLLocationCoordinate2D end   = [endAnnotation coordinate];
    [urlString appendFormat:@"&dropoff[latitude]=%.5f&dropoff[longitude]=%.5f", end.latitude, end.longitude];
    if ([endAnnotation respondsToSelector:@selector(title)]) {
      NSString *title = [endAnnotation title];
      if (title.length > 0) {
        NSString *encoded = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&dropoff[nickname]=%@", encoded];
      }
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    
  } else {
    // https://developer.uber.com/v1/deep-linking/#mobile-web
    
    NSMutableString *urlString = [NSMutableString stringWithString:@"https://m.uber.com/sign-up"];
    
    // from
    id<MKAnnotation> startAnnotation = [segment start];
    CLLocationCoordinate2D start = [startAnnotation coordinate];
    [urlString appendFormat:@"?pickup_latitude=%.5f&pickup_longitude=%.5f", start.latitude, start.longitude];
    if ([startAnnotation respondsToSelector:@selector(title)]) {
      NSString *title = [startAnnotation title];
      if (title.length > 0) {
        NSString *encoded = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&pickup_nickname=%@", encoded];
      }
    }
    
    // to
    id<MKAnnotation> endAnnotation = [segment end];
    CLLocationCoordinate2D end   = [endAnnotation coordinate];
    [urlString appendFormat:@"&dropoff_latitude=%.5f&dropoff_longitude=%.5f", end.latitude, end.longitude];
    if ([endAnnotation respondsToSelector:@selector(title)]) {
      NSString *title = [endAnnotation title];
      if (title.length > 0) {
        NSString *encoded = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&dropoff_nickname=%@", encoded];
      }
    }
    
    NSString *title = @"Uber"; // Not localized on purpose. It's a company name.
    NSURL *url = [NSURL URLWithString:urlString];
    if (openURLHandler) {
      openURLHandler(url, title);
    } else {
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
  }
}

+ (void)launchOlaForSegment:(TKSegment *)segment
           openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
  if ([self deviceHasOla]) {
    // http://developers.olacabs.com/docs/deep-linking
    
    NSMutableString *urlString = [NSMutableString stringWithString:@"olacabs://app/launch?landing_page=bk"];
    
    // from
    id<MKAnnotation> startAnnotation = [segment start];
    CLLocationCoordinate2D start = [startAnnotation coordinate];
    [urlString appendFormat:@"&lat=%.5f&lng=%.5f", start.latitude, start.longitude];
    
    // partner tracking
    NSString *token = [[TKConfig sharedInstance] olaXAPPToken];
    if (token.length > 0) {
      [urlString appendFormat:@"&utm_source=%@", token];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    
  } else if (openStoreHandler) {
    openStoreHandler(@(TKInterAppCommunicatorITunesAppIDOla));
    
  } else {
    NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/in/app/olacabs/id%d?mt=8", TKInterAppCommunicatorITunesAppIDOla];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString] options:@{} completionHandler:nil];
  }
}

+ (void)launchLyftForSegment:(TKSegment *)segment
                    rideType:(NSString *)rideType
            openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
  // ride types: lyft, lyft_line, lyft_plus
  
  if ([self deviceHasLyft]) {
    // launch into correct ride type
    NSMutableString *urlString = [NSMutableString stringWithString:@"lyft://ridetype?id="];
    [urlString appendString:rideType];

    // from
    id<MKAnnotation> startAnnotation = [segment start];
    CLLocationCoordinate2D start = [startAnnotation coordinate];
    [urlString appendFormat:@"&pickup[latitude]=%.5f&pickup[longitude]=%.5f", start.latitude, start.longitude];
    
    // to
    id<MKAnnotation> endAnnotation = [segment end];
    CLLocationCoordinate2D end   = [endAnnotation coordinate];
    [urlString appendFormat:@"&destination[latitude]=%.5f&destination[longitude]=%.5f", end.latitude, end.longitude];
    if ([endAnnotation respondsToSelector:@selector(title)]) {
      NSString *title = [endAnnotation title];
      if (title.length > 0) {
        NSString *encoded = [title stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        [urlString appendFormat:@"&dropoff_nickname=%@", encoded];
      }
    }

    // partner tracking
    NSString *partner = [[TKConfig sharedInstance] lyftPartnerCompanyName];
    if (partner.length > 0) {
      [urlString appendFormat:@"&partner=%@", partner];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString] options:@{} completionHandler:nil];
    
  } else if (openStoreHandler) {
    openStoreHandler(@(TKInterAppCommunicatorITunesAppIDLyft));
    
  } else {
    NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/us/app/lyft/id%d?mt=8", TKInterAppCommunicatorITunesAppIDLyft];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString] options:@{} completionHandler:nil];
  }
}

+ (void)launchFlitWaysForSegment:(TKSegment *)segment
                  openURLHandler:(nullable void (^)(NSURL *url, NSString * __nullable title))openURLHandler
{
  NSString *partnerKey = [[TKConfig sharedInstance] flitWaysPartnerKey];
  NSString *title = @"FlitWays"; // Not localized on purpose. It's a company name.
  
  if ([self deviceHasFlitWays]) {
    // To add when FlitWays allows deep-link
    
  } else if (partnerKey) {
    // See https://flitways.com/deeplink
    // https://flitways.com/api/link?key=PARTNER_KEY&pickup=PICKUP_ADDRESS&destination=DESTINATION_ADDRESS&trip_date=PICKUP_DATETIME
    // Partner Key – Required
    // Pick Up Address – Optional
    // Destination – Optional
    // Pickup DateTime – Optional
    
    CLLocationCoordinate2D pickup  = [[segment start] coordinate];
    CLLocationCoordinate2D dropOff  = [[segment end] coordinate];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeAddressForCoordinate:pickup
                                      completion:
     ^(NSString * _Nullable pickupAddress) {
       [geocoder reverseGeocodeAddressForCoordinate:dropOff
                                         completion:
        ^(NSString * _Nullable dropOffAddress) {
          NSMutableString *urlString = [NSMutableString stringWithString:@"https://flitways.com/api/link"];
          
          [urlString appendFormat:@"?key=%@", partnerKey];
          
          if (pickupAddress) {
            NSString *encoded = [pickupAddress stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [urlString appendFormat:@"&pickup=%@", encoded];
          }

          if (dropOffAddress) {
            NSString *encoded = [dropOffAddress stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
            [urlString appendFormat:@"&destination=%@", encoded];
          }

          NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
          formatter.dateFormat = @"dd/MM/yyyy hh:mm a";
          formatter.timeZone = [segment timeZone];
          NSString *dateString = [formatter stringFromDate:segment.departureTime];
          NSString *encoded = [dateString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
          [urlString appendFormat:@"&trip_date=%@", encoded];

          NSURL *url = [NSURL URLWithString:urlString];
          if (openURLHandler) {
            openURLHandler(url, title);
          } else {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
          }
        }];
     }];
  } else {
    NSURL *url = [NSURL URLWithString:@"https://flitways.com"];
    if (openURLHandler) {
      openURLHandler(url, title);
    } else {
      [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
    }
  }
}


#pragma mark - Helpers

+ (BOOL)canCall
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:"]];
}

+ (BOOL)canSendSMS
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sms:"]];
}

+ (void)composeSMS:(NSString *)SMS
 forViewController:(UIViewController *)controller
{
  NSString *raw = [SMS stringByReplacingOccurrencesOfString:@"sms:" withString:@""];
  NSArray *brokenUp = [raw componentsSeparatedByString:@"?"];
  NSString *recipient = [brokenUp firstObject];
  NSString *message = brokenUp.count > 1 ? [brokenUp lastObject] : nil;
  
  MFMessageComposeViewController *messageComposer = [[MFMessageComposeViewController alloc] init];
  messageComposer.messageComposeDelegate = [ComposerDelegate sharedInstance];
  messageComposer.recipients = @[recipient];
  messageComposer.body = message;
  
  [controller presentViewController:messageComposer animated:YES completion:nil];
}

@end


@implementation ComposerDelegate

+ (ComposerDelegate *)sharedInstance
{
  DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
    return [[self alloc] init];
  });
}

- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
#pragma unused(result)
  [controller.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

@end

