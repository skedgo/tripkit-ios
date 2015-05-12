//
//  SGStopCoordinate.h
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import "SGNamedCoordinate.h"

#import "TKStopAnnotation.h"
#import "ModeInfo.h"

@interface SGStopCoordinate : SGNamedCoordinate <TKStopAnnotation>

@property (nonatomic, copy)   NSString *stopCode;
@property (nonatomic, copy)   NSString *stopShortName;
@property (nonatomic, strong) NSNumber *stopSortScore;
@property (nonatomic, strong) ModeInfo *stopModeInfo;

@end
