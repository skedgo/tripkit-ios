//
//  TKPriceTimeTripClassifier.m
//  TripGo
//
//  Created by Adrian Schoenig on 11/06/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKPriceTimeTripClassifier.h"

#import <TripKit/TKTripKit.h>

@interface TKPriceTimeTripClassifier ()

@property (nonatomic, assign) CGFloat priceMin;
@property (nonatomic, assign) CGFloat priceMax;
@property (nonatomic, assign) NSTimeInterval offsetMin;
@property (nonatomic, assign) NSTimeInterval offsetMax;

@end

@implementation TKPriceTimeTripClassifier

- (void)prepareForClassifictionOfTripGroups:(NSSet *)tripGroups
{
  self.priceMin = CGFLOAT_MAX;
  self.priceMax = CGFLOAT_MIN;
  self.offsetMin = DBL_MAX;
  self.offsetMax = DBL_MIN;
  for (TripGroup *group in tripGroups) {
    Trip *representativeTrip = [group visibleTrip];
    if (representativeTrip.totalPrice) {
      float price = [representativeTrip.totalPrice floatValue];
      self.priceMin = MIN(price, self.priceMin);
      self.priceMax = MAX(price, self.priceMax);
    }
    NSTimeInterval offset = [representativeTrip calculateOffset];
    self.offsetMin = MIN(offset, self.offsetMin);
    self.offsetMax = MAX(offset, self.offsetMax);
  }
}

- (id<NSCoding, NSObject>)classificationOfTripGroup:(TripGroup *)tripGroup
{
  CGFloat cheapRange = (self.priceMax - self.priceMin) / 3;
  NSTimeInterval fastRange = (self.offsetMax - self.offsetMin) / 3;
  
  Trip *representativeTrip = [tripGroup visibleTrip];
  BOOL isCheap = NO;
  if (representativeTrip.totalPrice) {
    float price = [representativeTrip.totalPrice floatValue];
    isCheap = price < self.priceMin + cheapRange;
  }
  
  NSTimeInterval offset = [representativeTrip calculateOffset];
  BOOL isFast = offset < self.offsetMin + fastRange;
  
  if (isCheap && isFast) {
    return @(TKPriceTimeClassification_Cheap | TKPriceTimeClassification_Fast);
  } else if (isCheap) {
    return @(TKPriceTimeClassification_Cheap);
  } else if (isFast) {
    return @(TKPriceTimeClassification_Fast);
  } else {
    return @(0);
  }
}

@end
