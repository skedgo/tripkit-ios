//
//  TKConfig.h
//  TripKit
//
//  Created by Adrian Schoenig on 20/03/2015.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@interface TKConfig : NSObject

+ (TKConfig *)sharedInstance NS_REFINED_FOR_SWIFT;

- (nullable NSString *)appGroupName;

// Colors
- (nullable NSDictionary *)globalTintColor;
- (nullable NSDictionary *)globalAccentColor;
- (nullable NSDictionary *)globalBarTintColor;
- (nullable NSDictionary *)globalSecondaryBarTintColor;
- (nullable NSDictionary *)globalViewBackgroundColor;
- (BOOL)globalTranslucency;

// Fonts
- (nullable NSDictionary *)preferredFonts;

// Complete raw config information
@property (nonatomic, readonly) NSDictionary *configuration;

@end
NS_ASSUME_NONNULL_END
