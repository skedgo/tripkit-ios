//
//  TimeViewController.m
//  TripGo
//
//  Created by Adrian Schoenig on 24/09/13.
//
//

#import "TKUISheetViewController.h"

#import "TKUISheet.h"

@interface TKUISheetViewController ()

@end

@implementation TKUISheetViewController

- (instancetype)initWithSheet:(TKUISheet *)sheet
{
  self = [super init];
  if (self) {
    self.view = sheet;
  }
  return self;
}

- (TKUISheet *)sheet
{
  if ([self.view isKindOfClass:[TKUISheet class]])
    return (TKUISheet *) self.view;
  else
    return nil;
}

#pragma mark - UIViewController

- (void)viewDidDisappear:(BOOL)animated
{
  [super viewDidDisappear:animated];
  
  [self.sheet doneButtonPressed:nil];
}

- (CGSize)preferredContentSize
{
	return self.sheet.frame.size;
}


@end
