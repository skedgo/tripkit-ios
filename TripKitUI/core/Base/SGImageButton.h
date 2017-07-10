//
//  SGImageButton.h
//  TripGo
//
//  Created by Adrian Schoenig on 22/08/12.
//
//

#import <UIKit/UIKit.h>

@interface SGImageButton : UIButton

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name;

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
																	width:(CGFloat)width;

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
									 highlightedImageName:(NSString *)highlightedName;

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
									 highlightedImageName:(NSString *)highlightedName
																	width:(CGFloat)width;

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
                                  title:(NSString *)title
                              textColor:(UIColor *)textColor;

+ (SGImageButton *)buttonWithImageNamed:(NSString *)name
									 highlightedImageName:(NSString *)highlightedName
                                  title:(NSString *)title
                              textColor:(UIColor *)textColor;

@end
