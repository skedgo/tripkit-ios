//
//  SGBPBookingViewController.h
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import <UIKit/UIKit.h>

#import "BPKBaseTableViewController.h"
#import "BPKManager.h"

@class BPKForm;

@protocol BPKBookingViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

@interface BPKBookingViewController : BPKBaseTableViewController

@property (nonatomic, strong, readonly) BPKForm *form;
@property (nonatomic, strong, readonly, nullable) NSDictionary *postData;

@property (nonatomic, strong) BPKManager *manager;
@property (nonatomic, copy) NSString *progressText;

@property (nonatomic, weak) id<BPKBookingViewControllerDelegate> delegate;

- (instancetype)initWithForm:(BPKForm *)form;
- (instancetype)initWithBookingURL:(NSURL *)bookingURL;
- (instancetype)initWithBookingURL:(NSURL *)bookingURL postData:(nullable NSDictionary *)dictionary;

@end

@protocol BPKBookingViewControllerDelegate <NSObject>

/**
 *  This method is called to update a trip at the last step of a booking. The need to update a trip arises because options
 *  selected by users (e.g., pick up location and time) may affect the entire trip, e.g., the connection to the booked
 *  segment may change.
 *
 *  @param controller The controller that is making the trip update request.
 *  @param url        The URL to which the request is sent. This is usually provided by the booking backend.
 */
- (void)bookingViewController:(BPKBookingViewController *)controller requestsDismissalWithUpdate:(NSURL *)url;

/**
 *  This method is called when a booking is completed, e.g., when user clicks "Done" button in the confirmation form. Possible
 *  action can be 1.) dismissing the confirmation form (if presented modally) and 2.) add the trip to local storage for later
 *  access.
 *
 *  Note that, this method is passed a reference to a booking manager, which oversees the booking process. It knows information
 *  such as whether reminder should be set for the trip and if yes, how much earlier should the reminder be.
 *
 *  @param controller The controller that notifies the completion of a booking.
 *  @param complete   Whether the booking is completed.
 *  @param manager    The manager that oversees the booking process.
 */
- (void)bookingViewController:(BPKBookingViewController *)controller didComplete:(BOOL)complete withManager:(BPKManager *)manager;

/**
 *  This method is called when a booking is cancelled and user taps the "Done" button in the confirmation form. The delegate is
 *  responsible for dismissing the confirmation form.
 *
 *  @param controller The controller that notifies the booking has been cancelled.
 */
- (void)bookingViewControllerDidCancelBooking:(BPKBookingViewController *)controller;

@optional

- (BOOL)showReminderInbookingViewController:(BPKBookingViewController *)controller;

/**
 *  This method returns a block to execute when the Contact Support option in an
 *  alert is pressed in cases of booking error. If no block is returned, the
 *  Contact Support option will not be presented to the user in the alert. *
 *
 *  @param controller The controller that presents the alert.
 *
 *  @return A block to execute when Contact Support is pressed.
 */
- (nullable void (^)(void))contactSupportHandlerForBookingViewController:(BPKBookingViewController *)controller;

@end

NS_ASSUME_NONNULL_END
