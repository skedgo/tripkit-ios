//
//  TKInterAppCommunicator.m
//  TripKit
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKInterAppCommunicator.h"

@import MessageUI;


#ifndef TK_NO_FRAMEWORKS
@import TripKit;
#import <TripKitAddons/TripKitAddons-Swift.h>
#else
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#endif

#import "SGKConfig+TKInterAppCommunicator.h"

@interface ComposerDelegate : NSObject <MFMessageComposeViewControllerDelegate>
+ (ComposerDelegate *)sharedInstance;
@end

@implementation TKInterAppCommunicator

#pragma mark - Turn-by-turn directions helpers

+ (BOOL)canOpenInMapsApp:(TKSegment *)segment
{
  if (nil == segment || NO == [segment isKindOfClass:[TKSegment class]])
    return NO;
  
  return [segment isSelfNavigating] && [segment duration:YES] > 2 * 60;
}

+ (void)openSegmentInMapsApp:(TKSegment *)segment
           forViewController:(UIViewController *)controller
                 initiatedBy:(id)sender
      currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
{
  BOOL hasGoogleMaps = [self deviceHasGoogleMaps];
  BOOL hasWaze = [self deviceHasWaze];
  if (!hasGoogleMaps && !hasWaze) {
    // just open apple's
    [self openSegmentInAppleMaps:segment currentLocationHandler:currentLocationHandler];
    
  } else {
    SGActions *actions = [[SGActions alloc] initWithTitle:NSLocalizedStringFromTableInBundle(@"Get directions", @"TripKit", [TKTripKit bundle], "Action button title for getting turn-by-turn directions")];
    
    __weak TKSegment *directionsSegment = segment;
    [actions addAction:NSLocalizedStringFromTableInBundle(@"Apple Maps", @"TripKit", [TKTripKit bundle], @"apple maps directions action")
               handler:
     ^{
       [TKInterAppCommunicator openSegmentInAppleMaps:directionsSegment currentLocationHandler:currentLocationHandler];
     }];
    
    if (hasGoogleMaps) {
      [actions addAction:NSLocalizedStringFromTableInBundle(@"Google Maps", @"TripKit", [TKTripKit bundle], @"google maps directions action")
                 handler:
       ^{
         [TKInterAppCommunicator openSegmentInGoogleMapsApp:directionsSegment currentLocationHandler:currentLocationHandler];
       }];
    }
    
    if (hasWaze) {
      [actions addAction:@"Waze"
                 handler:
       ^{
         [TKInterAppCommunicator openSegmentInWazeApp:directionsSegment];
       }];
    }
    
    actions.hasCancel = YES;
    
    [actions showForSender:sender
              inController:controller];
  }
}

+ (void)openSegmentInGoogleMaps:(TKSegment *)segment
{
  CLLocationCoordinate2D start = [[segment start] coordinate];
  CLLocationCoordinate2D end   = [[segment end] coordinate];
  NSString* url = [NSString stringWithFormat: @"http://maps.google.com/maps?saddr=%f,%f&daddr=%f,%f",
                   start.latitude, start.longitude,
                   end.latitude, end.longitude];
  [[UIApplication sharedApplication] openURL: [NSURL URLWithString: url]];
}

+ (void)openSegmentInAppleMaps:(TKSegment *)segment
        currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
{
  MKMapItem *start;
  if (currentLocationHandler == nil || currentLocationHandler(segment)) {
    start = [MKMapItem mapItemForCurrentLocation];
  } else {
    MKPlacemark *startPlace = [[MKPlacemark alloc] initWithCoordinate:[[segment start] coordinate] addressDictionary:nil];
    start = [[MKMapItem alloc] initWithPlacemark:startPlace];
  }
  MKPlacemark *endPlace = [[MKPlacemark alloc] initWithCoordinate:[[segment end] coordinate] addressDictionary:nil];
  MKMapItem *end = [[MKMapItem alloc] initWithPlacemark:endPlace];
  
  NSString *directionMode = [segment isWalking] ? MKLaunchOptionsDirectionsModeWalking : MKLaunchOptionsDirectionsModeDriving;
  NSDictionary *options = @{ MKLaunchOptionsDirectionsModeKey : directionMode, MKLaunchOptionsMapTypeKey : @(MKMapTypeStandard), MKLaunchOptionsShowsTrafficKey : @YES };
  
  [MKMapItem openMapsWithItems:@[start, end]
                 launchOptions:options];
}

+ (BOOL)deviceHasGoogleMaps
{
  NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
  return [[UIApplication sharedApplication] canOpenURL:testURL];
}

+ (void)openSegmentInGoogleMapsApp:(TKSegment *)segment
            currentLocationHandler:(nullable BOOL (^)(TKSegment * __nonnull))currentLocationHandler
{
  // https://developers.google.com/maps/documentation/ios/urlscheme
  
  NSMutableString *directionsRequest = [NSMutableString stringWithString:@"comgooglemaps-x-callback://?"];
  
  // source
  if (currentLocationHandler == nil || currentLocationHandler(segment)) {
    // nothing to add
  } else {
    CLLocationCoordinate2D origin = [[segment start] coordinate];
    [directionsRequest appendFormat:@"saddr=%.5f,%.5f&", origin.latitude, origin.longitude];
  }
  
  // destination
  CLLocationCoordinate2D destination = [[segment end] coordinate];
  [directionsRequest appendFormat:@"daddr=%.5f,%.5f&", destination.latitude, destination.longitude];
  
  if ([segment isWalking]) {
    [directionsRequest appendString:@"directionsmode=walking"];
  } else if ([segment isCycling]) {
    [directionsRequest appendString:@"directionsmode=bicycling"];
  } else if ([segment isDriving]) {
    [directionsRequest appendString:@"directionsmode=driving"];
  }
  
  // call-back
  NSString *callback = [[SGKConfig sharedInstance] googleMapsCallback];
  if (callback) {
    [directionsRequest appendFormat:@"x-success=%@", callback];
  }
  NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
  [[UIApplication sharedApplication] openURL:directionsURL];
}

+ (BOOL)deviceHasWaze
{
  NSURL *testURL = [NSURL URLWithString:@"waze://"];
  return [[UIApplication sharedApplication] canOpenURL:testURL];
}

+ (void)openSegmentInWazeApp:(TKSegment *)segment
{
  // https://www.waze.com/about/dev
  
  // Waze will always start at the current location
  CLLocationCoordinate2D destination = [[segment end] coordinate];
  NSMutableString *directionsRequest = [NSMutableString stringWithFormat:@"waze://?ll=%f,%f&navigate=yes", destination.latitude, destination.longitude];
  
  NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
  [[UIApplication sharedApplication] openURL:directionsURL];
}

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
  
  SGActions *actions = [[SGActions alloc] init];
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
    return NSLocalizedStringFromTableInBundle(@"goCatch a Taxi", @"TripKit", [TKTripKit bundle], @"goCatch action");
    
  } else if ([action isEqualToString:@"uber"]) {
    return NSLocalizedStringFromTableInBundle(@"Book with Uber", @"TripKit", [TKTripKit bundle], nil);
    
  } else if ([action isEqualToString:@"ingogo"]) {
    return [self deviceHasIngogo]
    ? NSLocalizedStringFromTableInBundle(@"ingogo a Taxi", @"TripKit", [TKTripKit bundle], nil)
    : NSLocalizedStringFromTableInBundle(@"Get ingogo", @"TripKit", [TKTripKit bundle], nil);
    
  } else if ([action hasPrefix:@"lyft"]) { // also lyft_line, etc.
    return [self deviceHasLyft]
    ? NSLocalizedStringFromTableInBundle(@"Open Lyft", @"TripKit", [TKTripKit bundle], nil)
    : NSLocalizedStringFromTableInBundle(@"Get Lyft", @"TripKit", [TKTripKit bundle], nil);
    
  } else if ([action isEqualToString:@"ola"]) {
    return [self deviceHasOla]
    ? NSLocalizedStringFromTableInBundle(@"Open Ola", @"TripKit", [TKTripKit bundle], nil)
    : NSLocalizedStringFromTableInBundle(@"Get Ola", @"TripKit", [TKTripKit bundle], nil);

  } else if ([action isEqualToString:@"flitways"]) {
    return NSLocalizedStringFromTableInBundle(@"Book with FlitWays", @"TripKit", [TKTripKit bundle], nil);
    
  } else if ([action hasPrefix:@"tel:"] && [self canCall]) {
    NSRange nameRange = [action rangeOfString:@"name="];
    if (nameRange.location != NSNotFound) {
      NSString *name = [action substringFromIndex:nameRange.location + nameRange.length];
      name = [name stringByRemovingPercentEncoding];
      return [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"Call %@", @"TripKit", [TKTripKit bundle], "Action title for calling provider of name. (old key: CallTaxiFormat)"), name];
    } else {
      return NSLocalizedStringFromTableInBundle(@"Call", @"TripKit", [TKTripKit bundle], nil);
    }
    
  } else if ([action hasPrefix:@"sms:"] && [self canSendSMS]) {
    return NSLocalizedStringFromTableInBundle(@"Send SMS", @"TripKit", [TKTripKit bundle], @"Send SMS action");
    
  } else if ([action hasPrefix:@"http:"] || [action hasPrefix:@"https:"]) {
    return NSLocalizedStringFromTableInBundle(@"Show website", @"TripKit", [TKTripKit bundle], @"Show website action");
    
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
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:action]];
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
      [[UIApplication sharedApplication] openURL:url];
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
       destinationSuburb = [SGLocationHelper suburbForPlacemark:placemark];
       if (destinationSuburb.length > 0)
         break;
     }
     
     NSString *referralCode = [[SGKConfig sharedInstance] gocatchReferralCode];
     if (! referralCode) {
       referralCode = @"";
     }
     
     NSString *urlString = [NSString stringWithFormat:@"gocatch://referral?code=%@&destination=%@&pickup=%@&lat=%f&lng=%f",
                            referralCode,
                            [destinationSuburb stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]],
                            @"", // pickup address
                            pickup.latitude,
                            pickup.longitude];
     
     if ([self deviceHasGoCatch]) {
       // open app directly
       [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
     } else {
       // copy URL to paste board
       UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:UIPasteboardNameFind
                                                            create:NO];
       [pasteboard setURL:[NSURL URLWithString:urlString]];
       
       // open app store
       if (openStoreHandler) {
         openStoreHandler(@(TKInterAppCommunicatorITunesAppIDGoCatch));
       } else {
         NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/au/app/gocatch/id%d?mt=8", TKInterAppCommunicatorITunesAppIDGoCatch];
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
  } else {
    if (openStoreHandler) {
      openStoreHandler(@(TKInterAppCommunicatorITunesAppIDIngogo));
    } else {
      [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ingogo.mobi"]];
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
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
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
      [[UIApplication sharedApplication] openURL:url];
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
    NSString *token = [[SGKConfig sharedInstance] olaXAPPToken];
    if (token.length > 0) {
      [urlString appendFormat:@"&utm_source=%@", token];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
  } else if (openStoreHandler) {
    openStoreHandler(@(TKInterAppCommunicatorITunesAppIDOla));
    
  } else {
    NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/in/app/olacabs/id%d?mt=8", TKInterAppCommunicatorITunesAppIDOla];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
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
    NSString *partner = [[SGKConfig sharedInstance] lyftPartnerCompanyName];
    if (partner.length > 0) {
      [urlString appendFormat:@"&partner=%@", partner];
    }
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
  } else if (openStoreHandler) {
    openStoreHandler(@(TKInterAppCommunicatorITunesAppIDLyft));
    
  } else {
    NSString *URLString = [NSString stringWithFormat:@"https://itunes.apple.com/us/app/lyft/id%d?mt=8", TKInterAppCommunicatorITunesAppIDLyft];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
  }
}

+ (void)launchFlitWaysForSegment:(TKSegment *)segment
                  openURLHandler:(nullable void (^)(NSURL *url, NSString * __nullable title))openURLHandler
{
  NSString *partnerKey = [[SGKConfig sharedInstance] flitWaysPartnerKey];
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
            [[UIApplication sharedApplication] openURL:url];
          }
        }];
     }];
  } else {
    NSURL *url = [NSURL URLWithString:@"https://flitways.com"];
    if (openURLHandler) {
      openURLHandler(url, title);
    } else {
      [[UIApplication sharedApplication] openURL:url];
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

