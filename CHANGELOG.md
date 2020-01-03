# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

- `TKUIModePicker`: Show tooltips on hover on macOS
- Added `TKUIRoutingQueryInputCard` for setting origin and destination (and swapping them)

### Changed

`TKUITripOverviewCard`:

- Highlights when a segment is impossible due to real-time delays (with a button to get alternative routes to the destination)
- Only show times in list for PT segments, highlighting real-time status of times
- Platform information is now shown at the get on/get off parts of the trip
- Tweaked handling when the calculated trip starts or ends not directly at the requested location,
  by adding 'near' to the wording and displaying the query's origin and/or destination on the map.
- Adjusted logic when calculating "minutes" to ignore seconds in dates, to align with time stamps in the UI.
- Continuation segments: Use a smaller dot for the locations in the list when you stay on the transport.
- Continuation segments: Hide mode icon in continuation segments
- Trips starting/ending at a PT stop, prefer to take the name of that stop

  `TKUIRoutingResults`: 
  
- When passing a `TripRequest` that already has trips in it, then
  the card will just show those results, rather than querying for new results, and the UI to change
  the trip request will be disabled. To enable it set `request.expandForFavorite = true`.
- Updated the title view of the card to bring up the new query input card on tap.
- Fixes issue where continuations might not appear on the map
- In long distance trips, you can now select all relevant modes

`TKUIServiceCard`:

- Style fixes when displaying services that continue into other services

`TKUITimetableCard`:

- Fixes issue where 

### Removed

- Removed `TKCellHelper`
- Removed `TKCustomEvent`
- Removed `TKCustomEventRecurrenceRule`
- Removed `TKFakeRouter`
- Removed `TKGettingLiftVehicle`
- Removed `TKNextSegmentScorer`
- Removed `TKTripFactory`
- Removed `TKTrack`
- Removed `TKUIDepartureView`
- Removed `TKUITrackHelper`

### Fixed

- Fixes styling of some modes in dark mode (school buses, flights, and some car share)
- Addressed some crashes

## [Version 4.0-rc1] - 2019-10-15

### Added

TripKitUI has received a significant update with view controllers for trip planning, public transport timetables and location search. See `docs/view-controller.md` for details.

- Added `TKUIRoutingResultsViewController` along with `TKUIRoutingResultsCard` and `TKUITripOverviewCard`
- Added `TKUITimetableViewController` along with `TKUITimetableCard` and `TKUIServiceCard`
- Added `TKUITripModeByModeViewController` along with `TKUITripModeByModeCard`

Selected further additions:

- Added `TKSettings.ignoreCostToReturnCarHireVehicle` to ignore the cost of returning, say, a pod-based car share to its pick-up location
- Added Kingfisher convenience methods for setting `UIButton` images which sets the scale according to the file name
- Added more convenience methods to `TKLocationManager+Rx` and added some documentation
- Added `TKBuzzInfoProvider.fetchWheelchairSupportInformation` convenience method
- Added method to opt-out of restoring the last viewed map rect in `ASMapManager`
- Added real-time vehicle components to `API.Vehicle` and `Vehicle` which provides information of how the physical structure of vehicles
- Added `TKUITrainOccupancyView` to display the per-carriage occupancy of a train
- Added `TKUISectionedAlertViewController` for displaying all transit alerts in a region
- Added `TKPathFriendliness` enum, which now includes "dismount"
- Updated `TKUIPathFriendlinessView` to also include "dismount" section where appropriate
- Added `TKTurnByTurnMode` and `segment.turnByTurnMode`
- Adds `TKFileCache` for easier caching

### Changed

- Moved method to sign in with CloudKitID from TripKitBookings to TripKit
- `TKUIDepartureView` can now be used without `SGTrackItem`
- `TKAppleGeocoder` replaces `SGAppleGeocoder`, now with much improved autocompletion
- `TKPeliasGeocoder` replaces `TKMapZenGeocoder` and is now using SkedGo's Pelias backend
- When enabling or disabling the wheelchair mode, wheelchair information for public transport will also be toggled on and off accordingly
- `SGCalendarManager` now shows events in next 24h when autocompleting empty string
- `SGAutocompletionDataSource` now has a new interface and is using Rx, resulting in faster autocompletion
- `SGAddressBookManager` is now using locale for formatting addresses, not always using Australian style
- `API.Vehicle.Occupancy` is now `API.VehicleOccupancy`, and `vehicle.occupancy` is moved into the `components` of `API.Vehicle` and `Vehicle`
- `vehicle.wifi` is moved into the `components` of `API.Vehicle` and `Vehicle`
- `ASMapManager` is now deprecated. Switch to using [`TGCardViewController`](https://gitlab.com/SkedGo/iOS/tripgo-cards-ios) instead.
- Plus a lot more

### Removed

- Removed `TripKitAgenda` framework
- Removed `TripKitBookings` framework
- Removed `TGAgendaWidgetInfoView`
- Removed `X-TripGo-UUID` header being passed along with server calls
- `SGCountdownCell`: moved to the internal `SGUIKit`
- `SGMapButtonView`: moved to the internal `SGUIKit`
- `SGTripSummaryCell`: moved to the internal `SGUIKit`
- `UITableView+SafeReload`: moved to the internal `SGUIKit`
- `UIView+Hop`: moved to the internal `SGUIKit`
- `RouteMapManager`: moved to the internal `TripGoKit`
- `TripMapManager`: moved to the internal `TripGoKit`

### Fixed

- Fixed `TKLocationProvider.fetchLocations` which didn't parse responses
- Fixed test failures due to hitting non-production backend
- Various robustness fixes addressing occasional and hard-to-reproduce crashes

## [Version 3.1.1] - 2018-02-26

- Added new data returned by server when fetching region information (#58)
- Updated translations
- Removed deprecated functionality in `TripKitBookings` related to Facebook and Twitter logins
- Removed deprecated functionality in `TripKitBookings` related to payments
- Fixed `TKUIMapButtonView` blocking touch events
- Fixed bad image in `TKUISemaphoreView`

## [Version 3.1.0] - 2018-02-12

- Individual TripKit components now available through Carthage
- `TripKitAddOns/Share` now part of TripKit
- `TripKitAddOns/InterApp` renamed to TripKitInterApp


