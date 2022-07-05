# F.A.Q.

This is the F.A.Q. specific to the TripKit iOS SDK. For more general information on the TripGo API, please also check the TripGo API developer site - that general information will be especially relevant to you, if you're using the [TripKit framework](TripKit/index.html) directly rather than the [TripKitUI framework](TripKitUI/index.html) with its user interface components.

## User data storage

### Does the SDK support storing favourite locations or routes?

No, the SDK does not include storage for the user's favourites. That's assumed to be taken care of by the hosting app that uses the SDK. The SDK does let you inject custom buttons (with custom label and icon) on both the timetable and trip overview screens though. Your developers can use this to add an "add to favourites" button."

There's sample code for this in the `Examples/TripKitUIExample` project:

- `FavoriteStopAction` shows how to add an action button to the timetable screens
- `InMemoryFavoriteManager` shows how to pass the favourites to the home card

### Does the SDK support storage of the user's preferences?

Yes, there is support for storing the user's preferences, including:

- Selected transport modes
- Walking and cycling speed
- Relative priorities of the time, money, carbon, exercise and hassle metrics

These preferences are stored in `UserDefaults`.

## Trip persistence

### How do you persist a trip, so the same trip can be shared or displayed later?

For short-term sharing, you can use `trip.temporaryURL`, but that is only valid for minutes rather than hours or days.

For long-term sharing, you need to use the trip's `shareURL`. If it doesn't yet have one, hit the `saveURL` which will return a `shareURL` that is the valid for a long time (until the trip is in the past).

### I want to save a trip as a favourite, so that I can get the latest version of this trip at a later time, i.e., replacing public transport services with those leaving now rather than when I saved the trip.

In this case, don't use `trip.shareURL` or `trip.saveURL`. That URLs point to that exact trip *at its specific time* that you've planned it for. The use case of this is for sharing a trip or saving it to your calendar to refer back to it later.

As a favourite, it would make more sense to store either the components of a [`TripRequest`](TripKit/Classes/TripRequest.html), i.e., from location + start location + modes (if you then want to display the results screen later), or have a look at [`TKTripPattern`](TripKit/Enums/TKTripPattern.html) and [`TKWaypointRouter`](TripKit/Enums/TKWaypointRouter.html) if you later want to get back a trip with the same combination of modes to the one that you want to save.
