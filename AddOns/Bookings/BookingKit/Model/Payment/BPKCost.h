//
//  BPKCostValidator.h
//  TripGo
//
//  Created by Kuan Lun Huang on 6/02/2015.
//
//

#import <Foundation/Foundation.h>

@interface BPKCost : NSObject

@property (nonatomic, copy) NSString *bookingId;

@property (nonatomic, strong, readonly) NSArray *paymentTypes;
@property (nonatomic, assign, readonly) double cost;

- (instancetype)initWithJSON:(NSDictionary *)json;

- (BOOL)acceptCreditCard;
- (BOOL)acceptPaypal;

@end
