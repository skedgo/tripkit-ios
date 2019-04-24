//
//  TKLocationHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import "TKLocationHelper.h"

#define SGSimilarLocationDegreeDifference 0.000025

#import "TripKit/TripKit-Swift.h"


@implementation TKLocationHelper

+ (NSString *)addressForPlacemark:(CLPlacemark *)placemark
{
  ZAssert(nil != placemark, @"Placemark can't be nil.");
  
  NSString *postalAddress = [self postalAddressForPlacemark:placemark];
  if (postalAddress != nil) {
    return postalAddress;
  }
  
  // Deprecated fall-back using Australian standard
  
  NSMutableString* string = [[NSMutableString alloc] init];
  
  // we have a street name
  if (placemark.thoroughfare) {
    if (placemark.subThoroughfare && [placemark.thoroughfare rangeOfString:placemark.subThoroughfare].location == NSNotFound) {
      // the house number isn't included in the street
      [string appendString:placemark.subThoroughfare];
      [string appendString:@" "];
    }
    
    // now add the street name
    [string appendString:placemark.thoroughfare];
  }
  
  // sub locality if there's one (Bondi Junction) and locality otherwise (Waverley)
	// add suburb
	NSString *suburb = [self suburbForPlacemark:placemark];
	if (suburb.length > 0) {
		if (string.length > 0)
			[string appendString:@", "];
		[string appendString:suburb];
	}
  
  // Default back to name otherwise
  if (string.length == 0 && nil != placemark.name)
    [string appendString:placemark.name];
  
  if (string.length == 0)
    return nil;
  
  return string;
}

+ (NSString *)suburbForPlacemark:(CLPlacemark *)placemark
{
  ZAssert(nil != placemark, @"Placemark can't be nil.");
  
  // sub locality if there's one (Bondi Junction) and locality otherwise (Waverley)
	if (placemark.locality) {
		return placemark.locality;
  } else if (placemark.subLocality) {
		return placemark.subLocality;
  } else {
		return nil;
	}
}


+ (NSString *)nameFromPlacemark:(CLPlacemark *)placemark
{
  if (nil != placemark.name) {
    return placemark.name;
  }
  
  if (nil != placemark.areasOfInterest) {
    return [placemark.areasOfInterest objectAtIndex:0];
  }
  
  if (nil != placemark.addressDictionary) {
    NSString *firstLineOfAddress = [[[placemark addressDictionary] objectForKey:@"FormattedAddressLines"] objectAtIndex:0];
    return firstLineOfAddress;
  }
  
  return nil;
}

+ (NSString *)regionNameForPlacemark:(CLPlacemark *)placemark
{
  NSMutableString *string = [NSMutableString string];
  if (placemark.locality) {
    if (string.length > 0)
      [string appendString:@", "];
    [string appendString:placemark.locality];
  }

  
  if (placemark.administrativeArea) {
    if (string.length > 0)
      [string appendString:@", "];
    [string appendString:placemark.administrativeArea];
  }

  if (placemark.ISOcountryCode) {
    if (string.length > 0)
      [string appendString:@", "];
    [string appendString:placemark.ISOcountryCode];
  } else if (placemark.country) {
    if (string.length > 0)
      [string appendString:@", "];
    [string appendString:placemark.country];
  }
  
  if (string.length > 0) {
    return string;
  } else {
    return nil;
  }
  
}

+ (NSString *)expandAbbreviationInAddressString:(NSString *)address
{
	// List of address words
	NSDictionary *replacementDict = @{@"(\\W)st(\\W|$)" : @"$1Street ",
                                    @"(\\W)pde(\\W|$)" : @"$1Parade ",
                                    @"(\\W)ally(\\W|$)" : @"$1Alley ",
                                    @"(\\W)arc(\\W|$)" : @"$1Arcade ",
                                    @"(\\W)ave(\\W|$)" : @"$1Avenue ",
                                    @"(\\W)bvd(\\W|$)" : @"$1Boulevard ",
                                    @"(\\W)cl(\\W|$)" : @"$1Close ",
                                    @"(\\W)cres(\\W|$)" : @"$1Crescent ",
                                    @"(\\W)dr(\\W|$)" : @"$1Drive ",
                                    @"(\\W)esp(\\W|$)" : @"$1Esplanade ",
                                    @"(\\W)hwy(\\W|$)" : @"$1Highway ",
                                    @"(\\W)pl(\\W|$)" : @"$1Place ",
                                    @"(\\W)rd(\\W|$)" : @"$1Road ",
                                    @"(\\W)sq(\\W|$)" : @"$1Square ",
                                    @"(\\W)tce(\\W|$)" : @"$1Terrace ",};
	
	// The range of input string we want to search for a match.
	NSRange range;
	range.length = address.length;
	range.location = 0;
	
	// Replace any abbreviations with their full-length equivalents.
	for (NSString *needle in replacementDict.allKeys) {
		address = [address stringByReplacingOccurrencesOfString:needle
																								 withString:[replacementDict valueForKey:needle]
																										options:NSCaseInsensitiveSearch | NSRegularExpressionSearch
																											range:range];
	}
	
	return address;
}

+ (BOOL)coordinate:(CLLocationCoordinate2D)first isNear:(CLLocationCoordinate2D)second
{
  double latDiff = first.latitude - second.latitude;
  double lngDiff = first.longitude - second.longitude;
  double maxDiff = SGSimilarLocationDegreeDifference * 2;
  return fabs(latDiff) < maxDiff && fabs(lngDiff) < maxDiff;
}

@end
