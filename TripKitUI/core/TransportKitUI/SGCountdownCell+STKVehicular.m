//
//  SGCountdownCell+SGPrivateVehicle.m
//  TripGo
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import "SGCountdownCell+STKVehicular.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif

@implementation SGCountdownCell (SGVehicular)

- (void)configureWithVehicle:(id<STKVehicular>)vehicle includeSubtitle:(BOOL)includeSubtitle
{
  UIImage *icon = [STKVehicularHelper iconForVehicle:vehicle];
  
  return [self configureWithTitle:[[self class] titleForVehicle:vehicle]
                         subtitle:includeSubtitle ? [[self class] subtitleForVehicle:vehicle] : nil
                      subsubtitle:nil
                             icon:icon
                     iconImageURL:nil
                timeToCountdownTo:nil
                 parkingAvailable:nil
                         position:SGKGrouping_EdgeToEdge
                       stripColor:nil
                            alert:nil
                    alertIconType:STKInfoIconTypeNone];
}

#pragma mark - Helpers

+ (NSAttributedString *)titleForVehicle:(id<STKVehicular>)vehicle
{
  return [[NSAttributedString alloc] initWithString:[STKVehicularHelper titleForVehicle:vehicle]];
}

+ (NSString *)subtitleForVehicle:(id<STKVehicular>)vehicle
{
  if ([vehicle respondsToSelector:@selector(garage)]) {
    return [[vehicle garage] title];
  } else {
    return nil;
  }
}

@end
