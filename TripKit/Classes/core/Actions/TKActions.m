//
//  TKActions.m
//  TripKit
//
//  Created by Adrian Schoenig on 10/12/2014.
//
//

#import "TKActions.h"

#import <TripKit/TripKit-Swift.h>

#import "TKStyleManager.h"

#if TARGET_OS_IPHONE

@interface SGAction : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) TKActionBlock handler;

+ (instancetype)actionWithTitle:(NSString *)title
                        handler:(TKActionBlock)hanler;

@end

@implementation SGAction

+ (instancetype)actionWithTitle:(NSString *)title
                        handler:(TKActionBlock)handler
{
  SGAction *action = [[self alloc] init];
  action.title = title;
  action.handler = handler;
  return action;
}

@end

@interface TKActions ()

@property (nonatomic, copy) NSString *title;

@property (nonatomic, strong) NSMutableArray *actions;

@property (nonatomic, strong) NSString *textfieldValue;;
@property (nonatomic, strong) TKActionTextfieldBlock textfieldBlock;

@end

@implementation TKActions

- (instancetype)initWithTitle:(NSString *)title
{
  self = [super init];
  if (self) {
    self.title = title;
    self.type = UIAlertControllerStyleActionSheet;
    self.actions = [NSMutableArray array];
    self.hasCancel = YES;
  }
  return self;
}

- (instancetype)init
{
  return [self initWithTitle:nil];
}

- (void)addAction:(NSString *)title handler:(TKActionBlock)handler
{
  [self.actions addObject:[SGAction actionWithTitle:title handler:handler]];
}

- (void)setTextFieldWithValue:(NSString *)value handler:(TKActionTextfieldBlock)handler
{
  self.type = UIAlertControllerStyleAlert;
  self.textfieldBlock = handler;
  self.textfieldValue = value;
}

- (void)showForSender:(id)sender
         inController:(UIViewController *)controller
{
  UIAlertController *alerter = [UIAlertController alertControllerWithTitle:self.title
                                                                   message:self.message
                                                            preferredStyle:self.type];
  for (SGAction *action in self.actions) {
    [alerter addAction:[UIAlertAction actionWithTitle:action.title
                                                style:UIAlertActionStyleDefault
                                              handler:
                        ^(UIAlertAction *alertAction) {
#pragma unused(alertAction)
                          if (action.handler) {
                            action.handler();
                          }
                        }]];
  }
  
  if (self.textfieldBlock) {
    [alerter addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
      textField.text = self.textfieldValue;
      return;
    }];
    
    __weak UIAlertController* weakAlerter = alerter;
    [alerter addAction:[UIAlertAction actionWithTitle:Loc.Done
                                                style:UIAlertActionStyleDefault handler:
                        ^(UIAlertAction * _Nonnull action) {
                          __strong UIAlertController *strongAlerter = weakAlerter;
                          if (strongAlerter) {
                            UITextField *textField = [strongAlerter.textFields firstObject];
                            self.textfieldBlock(textField.text);
                          }
                        }]];
  }
  
  if (self.hasCancel) {
    [alerter addAction:[UIAlertAction actionWithTitle:Loc.Cancel style:UIAlertActionStyleCancel handler:nil]];
  }
  
  if ([sender isKindOfClass:[UIBarButtonItem class]]) {
    alerter.popoverPresentationController.barButtonItem = sender;
  } else if ([sender isKindOfClass:[UIView class]]) {
    alerter.popoverPresentationController.sourceView = controller.view;
    alerter.popoverPresentationController.sourceRect = [controller.view convertRect:[(UIView *)sender frame] fromView:[(UIView *)sender superview]];
  } else if (!sender) {
    alerter.popoverPresentationController.sourceView = [controller view];
  }
  [controller presentViewController:alerter animated:YES completion:nil];
}

@end

#endif
