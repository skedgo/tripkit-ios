//
//  BPKSectionItem+Address.m
//  TripKit
//
//  Created by Kuan Lun Huang on 16/03/2015.
//
//

#import "BPKSectionItem+Address.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif



@implementation BPKSectionItem (Address)

- (SGKNamedCoordinate *)annotation
{
  if (! [self isAddressItem]) {
    return nil;
  }
  
  id value = self.value;
  if ([value isKindOfClass:[NSDictionary class]]) {
    NSDictionary *addressValue = (NSDictionary *)value;
    CGFloat lat = [addressValue[@"lat"] floatValue];
    CGFloat lng = [addressValue[@"lng"] floatValue];
    NSString *address = addressValue[@"address"];
    NSString *name = addressValue[@"name"];
    SGKNamedCoordinate *annotation = [[SGKNamedCoordinate alloc] initWithLatitude:lat longitude:lng name:name address:address];
    return annotation;
  }
  
  return nil;
}

@end
