# BookingKit

## Usage

To start a booking, you need a SkedGo booking URL. Typically you'll get this by getting a trip from [`TripKit`](https://github.com/skedgo/tripkit-ios) which then has a segment, which has a [`bookingInternalURL`](https://github.com/skedgo/tripkit-ios/blob/master/Classes/model/TKSegment.h#L193).

You can then present the booking view controller:

```objective-c
	BPKBookingViewController *bookingController = [[BPKBookingViewController alloc] initWithBookingURL:internalURL];
	bookingController.delegate = self;
    UINavigationController *navigator = [[UINavigationController alloc] initWithRootViewController:bookingController];
    navigator.modalPresentationStyle = UIModalPresentationFormSheet;
    [controller presentViewController:navigator animated:YES completion:nil];
```

It is important to implement the necessary methods of the delegate protocol. Importantly these let you know when a booking is cancelled or finished, and they let you know the URL used to fetch an updated trip when the user changed parts of the trip during the booking process.
