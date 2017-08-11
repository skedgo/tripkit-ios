//
//  SGCountdownCell.h
//  TripKit
//
//  Created by Adrian Schoenig on 19/02/2014.
//
//

#import <UIKit/UIKit.h>

#ifdef TK_NO_MODULE
#import "TripKit.h"
#else
@import TripKit;
#endif


#import "SGLabel.h"

@class SGObjCDisposeBag;

@interface SGCountdownCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UIView *coloredStrip;
@property (nonatomic, weak) IBOutlet UIImageView *modeIcon;
@property (weak, nonatomic) IBOutlet UIImageView *tickView;
@property (weak, nonatomic) IBOutlet UIImageView *alertIcon;

// Main view: info labels
@property (weak, nonatomic) IBOutlet UIStackView *centerMainStack;
@property (nonatomic, weak) IBOutlet SGLabel *title;
@property (nonatomic, weak) IBOutlet SGLabel *subtitle;
@property (nonatomic, weak) IBOutlet SGLabel *subsubTitle;

// Main view: time & parking
@property (nonatomic, weak) IBOutlet SGLabel *timeNumberLabel;
@property (nonatomic, weak) IBOutlet SGLabel *timeLetterLabel;

// Main view: footnote
@property (weak, nonatomic) IBOutlet UIView *footnoteView;
@property (nonatomic, strong, readonly) NSArray *showFootnoteConstraints;
@property (nonatomic, strong, readonly) NSArray *hideFootnoteConstraints;

// Accessibility view.
@property (weak, nonatomic) IBOutlet UIView *accessibleView;
@property (weak, nonatomic) IBOutlet SGLabel *accessibleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *accessibleIcon;
@property (weak, nonatomic) IBOutlet UIView *accessibleSeparator;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accessibleIconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accessibleBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accessibleTopConstraint;

// Alert view.
@property (nonatomic, weak) IBOutlet UIView *alertView;
@property (nonatomic, weak) IBOutlet SGLabel *alertLabel;
@property (nonatomic, weak) IBOutlet UIImageView *alertSymbol;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *alertIconWidth;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *alertViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *alertViewTopConstraint;


@property (nonatomic, assign) BOOL showTickIcon;
@property (nonatomic, assign) BOOL showAlertIcon;
@property (nonatomic, assign) BOOL showAsCanceled;

// UI customizations
@property (nonatomic, strong) UIColor *preferredTintColor UI_APPEARANCE_SELECTOR;

// Rx compatibility
@property (nonatomic, strong) SGObjCDisposeBag *objcDisposeBag;

+ (UINib *)nib;
+ (NSString *)reuseId;

- (void)updateContentAlpha:(CGFloat)alpha;

// Internals
- (void)_resetContents;
- (void)_configureWithTitle:(NSAttributedString *)title
                   subtitle:(NSString *)subtitle
                subsubtitle:(NSString *)subsubtitle
                       icon:(UIImage *)icon
               iconImageURL:(NSURL *)iconImageURL
          timeToCountdownTo:(NSDate *)time
           parkingAvailable:(NSString *)parking
                   position:(SGKGrouping)position
                 stripColor:(UIColor *)stripColor;

@end
