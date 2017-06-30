//
//  SGCountdownCell.h
//  TripGo
//
//  Created by Adrian Schoenig on 19/02/2014.
//
//

#import <UIKit/UIKit.h>

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif


#import "SGLabel.h"

@class SGObjCDisposeBag;

@interface SGCountdownCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIImageView *modeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *modeAccessoryIcon;
@property (nonatomic, weak) IBOutlet UIView *coloredStrip;
@property (nonatomic, weak) IBOutlet SGLabel *title;
@property (nonatomic, weak) IBOutlet SGLabel *subtitle;
@property (nonatomic, weak) IBOutlet SGLabel *subSubTitle;
@property (nonatomic, weak) IBOutlet SGLabel *timeNumberLabel;
@property (nonatomic, weak) IBOutlet SGLabel *timeLetterLabel;
@property (weak, nonatomic) IBOutlet SGLabel *parkingLabel;
@property (weak, nonatomic) IBOutlet UIImageView *tickView;
@property (weak, nonatomic) IBOutlet UIImageView *alertIcon;
@property (nonatomic, weak) IBOutlet UIView *seperator;

// Main view: footnote
@property (weak, nonatomic) IBOutlet UIView *footnoteView;
@property (weak, nonatomic) IBOutlet UIStackView *centerMainStack;
@property (nonatomic, strong, readonly) NSArray *showFootnoteConstraints;
@property (nonatomic, strong, readonly) NSArray *hideFootnoteConstraints;

// Alert view.
@property (nonatomic, weak) IBOutlet SGLabel *alertLabel;
@property (nonatomic, weak) IBOutlet UIImageView *alertSymbol;
@property (nonatomic, weak) IBOutlet UIView *alertView;

@property (nonatomic, assign) BOOL showTickIcon;
@property (nonatomic, assign) BOOL showAlertIcon;
@property (nonatomic, assign) BOOL showAsCanceled;
@property (nonatomic, assign) BOOL showWheelchair;

// UI customizations
@property (nonatomic, strong) UIColor *preferredTintColor UI_APPEARANCE_SELECTOR;

// Rx compatibility
@property (nonatomic, strong) SGObjCDisposeBag *objcDisposeBag;

+ (UINib *)nib;
+ (NSString *)reuseId;

- (void)updateContentAlpha:(CGFloat)alpha;

/**
 Configures the cell with the defined content.
 
 @param title       The title to be displayed in the first line. Doesn't need to wrap.
 @param subtitle    The subitle to be displayed below. Can be long and should wrap.
 @param icon        Image to be displayed on the left.
 @param time        Optional time to countdown to/from. If this is in the past, the cell should appear faded.
 @param position    Position of this cell relative to the cells around it.
 @param stripColor  Optional color to display a coloured strip under the icon.
 */
- (void)configureWithTitle:(NSAttributedString *)title
                  subtitle:(NSString *)subtitle
               subsubtitle:(NSString *)subsubtitle
                      icon:(UIImage *)icon
              iconImageURL:(NSURL *)iconImageURL
         timeToCountdownTo:(NSDate *)time
          parkingAvailable:(NSString *)parking
                  position:(SGKGrouping)position
                stripColor:(UIColor *)stripColor
                     alert:(NSString *)alert
             alertIconType:(/*STKInfoIconType*/NSInteger)alertIconType;

@end
