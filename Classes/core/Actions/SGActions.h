//
//  SGActions.h
//  TripGo
//
//  Created by Adrian Schoenig on 10/12/2014.
//
// Helper class for defining actions as pairs of title => block, to configure
// action sheets.


#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^SGActionBlock)();
typedef void(^SGActionTextfieldBlock)(NSString *value);

@interface SGActions : NSObject

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

- (void)addAction:(NSString *)title handler:(nullable SGActionBlock)handler;

- (void)setTextFieldWithValue:(NSString *)value
                      handler:(SGActionTextfieldBlock)handler;

- (void)showForSender:(nullable id)sender
         inController:(UIViewController *)controller;

@end

NS_ASSUME_NONNULL_END
