//
//  SGImageButton.m
//  TripGo
//
//  Created by Adrian Schoenig on 22/08/12.
//
//

#import "SGImageButton.h"

@implementation SGImageButton

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
{
	return [self buttonWithImageNamed:name highlightedImageName:nil];
}

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
																	width:(CGFloat)width
{
	return [self buttonWithImageNamed:name highlightedImageName:nil width:width];
}


+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
									 highlightedImageName:(NSString *)highlightedName
{
  return [self buttonWithImageNamed:name
							 highlightedImageName:highlightedName
															width:0];
}

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
									 highlightedImageName:(NSString *)highlightedName
																	width:(CGFloat)width
{
#warning TODO: FIX THIS! Should also specify the bundle
  
  UIImage *image = [UIImage imageNamed:name];
  SGImageButton *button = [self buttonWithType:UIButtonTypeCustom];
	if (width > 0) {
		button.frame = CGRectMake((width - image.size.width) / 2, 0, width, image.size.height);
	} else {
		button.frame = CGRectMake(0, 0, image.size.width, image.size.height);
	}
	[button setImage:image forState:UIControlStateNormal];
	
	if (highlightedName != nil) {
		UIImage *highlightedImage = [UIImage imageNamed:highlightedName];
		[button setImage:highlightedImage forState:UIControlStateHighlighted];
	}
	
  return button;
}


+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
                                  title:(NSString *)title
                              textColor:(UIColor *)textColor
{
	return [self buttonWithImageNamed:name
							 highlightedImageName:nil
															title:title
													textColor:textColor];
}


+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
									 highlightedImageName:(NSString *)highlightedName
                                  title:(NSString *)title
                              textColor:(UIColor *)textColor
{
  SGImageButton *button = [self buttonWithImageNamed:name
																highlightedImageName:highlightedName];

  UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(3, 3, button.frame.size.width - 25, button.frame
                                                            .size.height - 6)];
  label.text = title;
  label.adjustsFontSizeToFitWidth = YES;
  label.backgroundColor = [UIColor clearColor];
  label.textColor = textColor;
  [button addSubview:label];
  
  return button;
}

- (void)setEnabled:(BOOL)enabled
{
  [super setEnabled:enabled];
  
  self.alpha = enabled ? 1.0f : 0.3f;
}

- (void)setHighlighted:(BOOL)highlighted
{
  [super setHighlighted:highlighted];
  
  self.alpha = highlighted ? 0.85f : 1.0f;
}

@end
