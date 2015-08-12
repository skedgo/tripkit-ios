//
//  TKInterAppCommunicator.m
//  TripGo
//
//  Created by Adrian Schoenig on 11/08/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKInterAppCommunicator.h"

#import "SGRootKit.h"

#import "SGKConfig+TKInterAppCommunicator.h"

#import "SGActions.h"

@implementation TKInterAppCommunicator

#pragma mark - Turn-by-turn directions helpers

+ (BOOL)canOpenInMapsApp:(TKSegment *)segment
{
  if (nil == segment || NO == [segment isKindOfClass:[TKSegment class]])
    return NO;
  
  return [segment isSelfNavigating];
}

+ (void)openSegmentInMapsApp:(TKSegment *)segment
           forViewController:(UIViewController *)controller
                 initiatedBy:(id)sender
{
  BOOL hasGoogleMaps = [self deviceHasGoogleMaps];
  BOOL hasWaze = [self deviceHasWaze];
  if (!hasGoogleMaps && !hasWaze) {
    // just open apple's
    [self openSegmentInAppleMaps:segment];
    
  } else {
    SGActions *actions = [[SGActions alloc] initWithTitle:NSLocalizedString(@"Get directions", "Action button title for getting turn-by-turn directions")];
    
    __weak TKSegment *directionsSegment = segment;
    [actions addAction:NSLocalizedString(@"Apple Maps", @"apple maps directions action")
               handler:
     ^{
       [TKInterAppCommunicator openSegmentInAppleMaps:directionsSegment];
     }];
    
    if (hasGoogleMaps) {
      [actions addAction:NSLocalizedString(@"Google Maps", @"google maps directions action")
                 handler:
       ^{
         [TKInterAppCommunicator openSegmentInGoogleMapsApp:directionsSegment];
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
{
  MKMapItem *start;
  if ([self segmentIsCurrentLocation:segment]) {
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
{
  // https://developers.google.com/maps/documentation/ios/urlscheme
  
  NSMutableString *directionsRequest = [NSMutableString stringWithString:@"comgooglemaps-x-callback://?"];
  
  // source
  if ([self segmentIsCurrentLocation:segment]) {
    // nothing to add
  } else {
    CLLocationCoordinate2D origin = [[segment start] coordinate];
    [directionsRequest appendFormat:@"saddr=%.5f,%.5f&", origin.latitude, origin.longitude];
  }
  
  
  // destination
  CLLocationCoordinate2D destination = [[segment end] coordinate];
  [directionsRequest appendFormat:@"daddr=%.5f,%.5f&", destination.latitude, destination.longitude];
  
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

+ (BOOL)segmentIsCurrentLocation:(TKSegment *)segment
{
  return [[SGLocationManager sharedInstance] annotationIsCurrentLocation:segment.start orCloseEnough:YES];
}

#pragma mark - Taxi helpers

+ (BOOL)canHandleExternalActions:(TKSegment *)segment
{
  return segment.bookingExternalActions.count > 0;
}

+ (void)handleExternalActions:(TKSegment * __nonnull)segment
            forViewController:(UIViewController * __nonnull)controller
                  initiatedBy:(nullable id)sender
               openURLHandler:(nullable void (^)(NSURL * __nonnull, NSString * __nullable))openURLHandler
             openStoreHandler:(nullable void (^)(NSNumber * __nonnull))openStoreHandler
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
                                   openURLHandler:openURLHandler
                                 openStoreHandler:openStoreHandler];
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
                                        openURLHandler:openURLHandler
                                      openStoreHandler:openStoreHandler];
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
    return NSLocalizedString(@"goCatch a Taxi", @"goCatch action");
    
  } else if ([action isEqualToString:@"uber"]) {
    return [self deviceHasUber]
    ? NSLocalizedString(@"Open Uber", nil)
    : NSLocalizedString(@"Get Uber", nil);
    
  } else if ([action isEqualToString:@"ingogo"]) {
    NSString *prompt = [[SGKConfig sharedInstance] ingogoCouponPrompt];
    if ([self deviceHasIngogo] || !prompt) {
      return NSLocalizedString(@"ingogo a Taxi", nil);
    } else {
      return prompt;
    }
    
  } else if ([action isEqualToString:@"lyft"]) {
    return [self deviceHasLyft]
    ? NSLocalizedString(@"Open Lyft", nil)
    : NSLocalizedString(@"Get Lyft", nil);
    
  } else if ([action isEqualToString:@"sidecar"]) {
    return [self deviceHasSidecar]
    ? NSLocalizedString(@"Open Sidecar", nil)
    : NSLocalizedString(@"Get Sidecar", nil);
    
  } else if ([action hasPrefix:@"tel:"]) {
    NSRange nameRange = [action rangeOfString:@"name="];
    if (nameRange.location != NSNotFound) {
      NSString *name = [action substringFromIndex:nameRange.location + nameRange.length];
      name = [name stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      return [NSString stringWithFormat:NSLocalizedString(@"CallTaxiFormat", "Action title for calling provider of %name"), name];
    } else {
      return NSLocalizedString(@"Call", nil);
    }
    
  } else if ([action hasPrefix:@"http:"]) {
    return NSLocalizedString(@"Show website", @"Show website action");
    
  } else {
    return nil;
  }
}

+ (void)performExternalAction:(NSString *)action
                       titled:(NSString *)title
                   forSegment:(TKSegment *)segment
            forViewController:(UIViewController * __nonnull)controller
               openURLHandler:(nullable void (^)(NSURL *url, NSString * __nullable title))openURLHandler
             openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
  if ([action isEqualToString:@"gocatch"]) {
    [self launchGoCatchForSegment:segment
                 openStoreHandler:openStoreHandler];
    
  } else if ([action isEqualToString:@"uber"]) {
    [self launchUberForSegment:segment
                openURLHandler:openURLHandler];
    
  } else if ([action isEqualToString:@"ingogo"]) {
    [self launchIngogoForSegment:segment
               forViewController:controller
                openStoreHandler:openStoreHandler];
    
  } else if ([action isEqualToString:@"lyft"]) {
    [self launchLyftForSegment:segment
              openStoreHandler:openStoreHandler];
    
  } else if ([action isEqualToString:@"sidecar"]) {
    [self launchSidecarForSegment:segment
                 openStoreHandler:openStoreHandler];
    
  } else if ([self canCall] && [action hasPrefix:@"tel:"]) {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:action]];
    
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
  for (NSString *action in actions) {
    if (!canCall && [action hasPrefix:@"tel:"]) {
      continue;
    }
    
    if ([action isKindOfClass:[NSNull class]]) {
      continue;
    }
    
    if (   ([action isEqualToString:@"gocatch"] && [self deviceHasGoCatch])
        || ([action isEqualToString:@"ingogo"]  && [self deviceHasIngogo])
        || ([action isEqualToString:@"uber"]    && [self deviceHasUber])
        || ([action isEqualToString:@"lyft"]    && [self deviceHasLyft])
        || ([action isEqualToString:@"sidecar"] && [self deviceHasSidecar])
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

+ (BOOL)deviceHasUber
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"uber:"]];
}

+ (BOOL)deviceHasLyft
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"lyft:"]];
}

+ (BOOL)deviceHasSidecar
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"sidecar:"]];
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
                            [destinationSuburb stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
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
         openStoreHandler(@(444439909));
       } else {
         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/au/app/gocatch/id444439909?mt=8&uo=4"]];
       }
     }
     
   }];
}

+ (void)launchIngogoForSegment:(TKSegment *)segment
             forViewController:(UIViewController * __nonnull)controller
             openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
#pragma unused(segment) // ingogo doesn't support that yet
  
  if ([self deviceHasIngogo]) {
    // just launch it
    NSString *urlString = @"ingogo://";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
  } else {
    NSString *couponCode = [[SGKConfig sharedInstance] ingogoCouponCode];
    if (couponCode) {
      SGActions *alert = [[SGActions alloc] initWithTitle:NSLocalizedString(@"Get ingogo", nil)];
      alert.type = UIAlertControllerStyleAlert;
      alert.hasCancel = YES;
      alert.message = [NSString stringWithFormat:NSLocalizedString(@"CouponCodeIngogoFormat", "Description for how to redeem the coupon code for ingogo. %couponCode is provided."), couponCode];
      
      [alert addAction:NSLocalizedString(@"Get ingogo", nil) handler:^{
        // copy code to paste board
        UIPasteboard *pasteboard = [UIPasteboard pasteboardWithName:UIPasteboardNameGeneral
                                                             create:NO];
        [pasteboard setString:couponCode];
        
        if (openStoreHandler) {
          openStoreHandler(@(463995190));
        } else {
          [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ingogo.mobi"]];
        }
      }];
      
      [alert showForSender:nil inController:controller];


    } else {
      if (openStoreHandler) {
        openStoreHandler(@(463995190));
      } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.ingogo.mobi"]];
      }
    }
  }
}

+ (void)launchUberForSegment:(TKSegment *)segment
              openURLHandler:(nullable void (^)(NSURL *url, NSString * __nullable title))openURLHandler
{
  if ([self deviceHasUber]) {
    // https://developer.uber.com/v1/deep-linking/#ios
    
    NSMutableString *urlString = [NSMutableString stringWithString:@"uber://?action=setPickup"];
    
    // from
    if ([self segmentIsCurrentLocation:segment]) {
      [urlString appendString:@"&pickup=my_location"];
    } else {
      id<MKAnnotation> startAnnotation = [segment start];
      CLLocationCoordinate2D start = [startAnnotation coordinate];
      [urlString appendFormat:@"&pickup[latitude]=%.5f&pickup[longitude]=%.5f", start.latitude, start.longitude];
      if ([startAnnotation respondsToSelector:@selector(title)]) {
        NSString *title = [startAnnotation title];
        if (title.length > 0) {
          NSString *encoded = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
        NSString *encoded = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
        NSString *encoded = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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
        NSString *encoded = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
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

+ (void)launchLyftForSegment:(TKSegment *)segment
            openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
#pragma unused(segment) // lyft doesn't support that yet
  
  if ([self deviceHasLyft]) {
    // just launch it
    NSString *urlString = @"lyft://";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
  } else if (openStoreHandler) {
    openStoreHandler(@(529379082));
  } else {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/lyft/id529379082?mt=8"]];
  }
}

+ (void)launchSidecarForSegment:(TKSegment *)segment
               openStoreHandler:(nullable void (^)(NSNumber *appID))openStoreHandler
{
  if ([self deviceHasSidecar]) {
    // See their PDF
    
    NSMutableString *urlString = [NSMutableString stringWithString:@"sidecar://"];
    
    // from
    if ([self segmentIsCurrentLocation:segment]) {
      [urlString appendString:@"?source=currentlocation"];
    } else {
      id<MKAnnotation> startAnnotation = [segment start];
      CLLocationCoordinate2D start = [startAnnotation coordinate];
      [urlString appendFormat:@"?source=%.5f,%.5f", start.latitude, start.longitude];
      if ([startAnnotation respondsToSelector:@selector(title)]) {
        NSString *title = [startAnnotation title];
        if (title.length > 0) {
          NSString *encoded = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
          [urlString appendFormat:@"&pickuptext=%@", encoded];
        }
      }
    }
    
    // to
    id<MKAnnotation> endAnnotation = [segment end];
    CLLocationCoordinate2D end   = [endAnnotation coordinate];
    [urlString appendFormat:@"&destination=%.5f,%.5f", end.latitude, end.longitude];
    if ([endAnnotation respondsToSelector:@selector(title)]) {
      NSString *title = [endAnnotation title];
      if (title.length > 0) {
        NSString *encoded = [title stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [urlString appendFormat:@"&dropofftext=%@", encoded];
      }
    }
    
    NSString *referralCode = [[SGKConfig sharedInstance] sidecarReferralCode];
    if (! referralCode) {
      referralCode = @"";
    }
    [urlString appendFormat:@"&referrer=%@", referralCode];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
    
  } else if (openStoreHandler) {
    openStoreHandler(@(524617679));
  } else {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://itunes.apple.com/us/app/sidecar-ride/id524617679?mt=8"]];
  }
}


#pragma mark - Helpers



+ (BOOL)canCall
{
  return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:"]];
}

@end
