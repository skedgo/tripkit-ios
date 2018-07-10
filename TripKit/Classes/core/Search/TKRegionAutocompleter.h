//
//  TKRegionAutocompleter.h
//  TripKit
//
//  Created by Adrian Schoenig on 25/02/2015.
//
//

#import <Foundation/Foundation.h>

#import "SGAutocompletionDataProvider.h"
#import "TKBaseGeocoder.h"

@interface TKRegionAutocompleter : TKBaseGeocoder <SGAutocompletionDataProvider>

@end
