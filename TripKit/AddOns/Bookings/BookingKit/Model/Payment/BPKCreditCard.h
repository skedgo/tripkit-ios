//
//  SGBPCreditCard.h
//  TripKit
//
//  Created by Brian Huang on 5/02/2015.
//
//

#import <Foundation/Foundation.h>

@class BPKUser;

@interface BPKCreditCard : NSObject

@property (nonatomic, assign) BOOL isAdHoc;
@property (nonatomic, assign) BOOL isSelected;

@property (nonatomic, copy) NSString *cardNo;
@property (nonatomic, copy) NSString *expiryDate;
@property (nonatomic, copy) NSString *cvc;

- (instancetype)initWithUser:(BPKUser *)user;
- (instancetype)initWithCardNo:(NSString *)cardNo expiryDate:(NSString *)expiryDate cvc:(NSString *)cvc;

+ (BOOL)isValidCardNo:(NSString *)cardNo;
+ (NSString *)formattedCardNo:(NSString *)cardNo;

+ (BOOL)isValidExpiryDate:(NSString *)expiryDate;
+ (NSString *)formattedExpiryDate:(NSString *)expiryDate;
- (NSUInteger)expiryMonth;
- (NSUInteger)expiryYear;

+ (BOOL)isValidCVC:(NSString *)cvc;

- (void)printCard;

@end
