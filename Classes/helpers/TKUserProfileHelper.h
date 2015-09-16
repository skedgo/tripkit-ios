//
//  TKUserProfileHelper.h
//  TripGo
//
//  Created by Adrian Schoenig on 2/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TKUserProfileHelper : NSObject

///-----------------------------------------------------------------------------
/// @name Transport modes
///-----------------------------------------------------------------------------

+ (void)updateTransportModesWithEnabledOrder:(nullable NSArray *)enabled
                                   minimized:(nullable NSSet *)minimized
                                      hidden:(nullable NSSet *)hidden;

+ (BOOL)modeIdentifierIsMinimized:(NSString *)modeIdentifier;

+ (void)setModeIdentifier:(NSString *)modeIdentifier
              toMinimized:(BOOL)minimized;

+ (NSArray<NSString *> *)orderedEnabledModeIdentifiersForAvailableModeIdentifiers:(NSArray<NSString *> *)available;

+ (NSSet<NSString *> *)minimizedModeIdentifiers;

+ (NSSet<NSString *> *)hiddenModeIdentifiers;

@end

NS_ASSUME_NONNULL_END
