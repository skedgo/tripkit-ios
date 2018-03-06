# Change Log
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

### Added

- Added `TKSettings.ignoreCostToReturnCarHireVehicle` to ignore the cost of returning, say, a pod-based car share to its pick-up location
- Added Kingfisher convenience methods for setting `UIButton` images which sets the scale according to the file name
- Added more convenience methods to `SGLocationManager+Rx` and added some documentation
- Added `TKBuzzInfoProvider.fetchWheelchairSupportInformation` convenience method

### Changed

- Moved method to sign in with CloudKitID from TripKitBookings to TripKit
- `TKDepartureView` can now be used without `SGTrackItem`
- `TKPeliasGeocoder` replaces `TKMapZenGeocoder` and is now using SkedGo's Pelias backend
- When enabling or disabling the wheelchair mode, wheelchair information for public transport will also be toggled on and off accordingly

### Removed

- Removed `TGAgendaWidgetInfoView`

### Fixed

- Fixed `TKLocationProvider.fetchLocations` which didn't parse responses
- Fixed test failures due to hitting non-production backend

## [Version 3.1.1] - 2018-02-26

- Added new data returned by server when fetching region information (#58)
- Updated translations
- Removed deprecated functionality in `TripKitBookings` related to Facebook and Twitter logins
- Removed deprecated functionality in `TripKitBookings` related to payments
- Fixed `TKMapButtonView` blocking touch events
- Fixed bad image in `SGSemaphoreView`

## [Version 3.1.0] - 2018-02-12

- Individual TripKit components now available through Carthage
- `TripKitAddOns/Share` now part of TripKit
- `TripKitAddOns/InterApp` renamed to TripKitInterApp


