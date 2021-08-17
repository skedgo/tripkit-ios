//
//  TKActions.h
//  TripKit
//
//  Created by Adrian Schoenig on 10/12/2014.
//
// Helper class for defining actions as pairs of title => block, to configure
// action sheets.

#import "TargetConditionals.h"
#if !TARGET_OS_OSX

#import "TKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^TKActionBlock)(void);
typedef void(^TKActionTextfieldBlock)(NSString *value);

@interface TKActions : NSObject

/*
 @default YES
 */
@property (nonatomic, assign) BOOL hasCancel;

/*
 @default UIAlertControllerStyleActionSheet
 */
@property (nonatomic, assign) UIAlertControllerStyle type;

/*
 The message shown on alert sheets.
 */
@property (nonatomic, copy) NSString *message;

- (instancetype)initWithTitle:(nullable NSString *)title;

- (void)addAction:(NSString *)title handler:(nullable TKActionBlock)handler;

- (void)setTextFieldWithValue:(NSString *)value
                      handler:(TKActionTextfieldBlock)handler;

- (void)showForSender:(nullable id)sender
         inController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END

#endif
