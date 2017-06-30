//
//  SGCountdownCell+STKVehicular.h
//  TripGo
//
//  Created by Adrian Schoenig on 19/03/2014.
//
//

#import "SGCountdownCell.h"

@protocol STKVehicular;

@interface SGCountdownCell (SGVehicular)

- (void)configureWithVehicle:(id<STKVehicular>)vehicle includeSubtitle:(BOOL)includeSubtitle;

@end
