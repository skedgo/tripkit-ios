//
//  BPKTextCell.m
//  TripKit
//
//  Created by Kuan Lun Huang on 13/05/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "BPKTextCell.h"

#ifdef TK_NO_MODULE
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
@import TripKitUI;
#endif


#import "BPKSection.h"

@interface BPKTextCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewHeight;


@end

@implementation BPKTextCell

@synthesize didChangeValueHandler;

- (void)awakeFromNib
{
  [super awakeFromNib];
  self.textView.scrollEnabled = NO;
  self.textView.font = [TKStyleManager systemFontWithTextStyle:UIFontTextStyleCaption1];
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  
  [self.contentView setNeedsLayout];
  [self.contentView layoutIfNeeded];
  
  CGSize size = [self.textView sizeThatFits:CGSizeMake(CGRectGetWidth(self.textView.frame), FLT_MAX)];
  self.textViewHeight.constant = size.height;
}

#pragma mark - Public methods

- (void)configureWithText:(NSString *)text
{
  NSString *edited = text;
  
  if (text.length > 0) {
    edited = [self removeExcessNewLineFromText:text];
  }
  
  self.textView.text = edited;
}

- (void)configureWithAttributedText:(NSAttributedString *)attributedText
{
  self.textView.attributedText = attributedText;
}

#pragma mark - BPKFormCell

- (void)configureForItem:(BPKSectionItem *)item
{
  self.textView.text = nil;
  
  id value = item.value;
  if ([value isKindOfClass:[NSString class]]) {
    [self configureWithText:value];
  }
}

#pragma mark - Private: Markdown manipulations

- (NSString *)removeExcessNewLineFromText:(NSString *)text
{
  text = [text stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, 2)];
  text = [text stringByReplacingOccurrencesOfString:@"\n\t" withString:@""];
  return text;
}

@end
