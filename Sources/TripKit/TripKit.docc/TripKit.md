# ``TripKit``

Core framework for trip planning, routing, and transportation data in iOS applications.

## Overview

TripKit provides the foundational capabilities for building transportation and mobility applications. It offers the business logic for comprehensive trip planning functionality, real-time data fetching, and related services offered by SkedGo's TripGo APIs.

The framework handles multi-modal routing, waypoint-based navigation, real-time updates, and integrates seamlessly with SkedGo's transportation network data.

## Getting Started

To get started with TripKit, you'll need to configure your application with the appropriate server settings and region information:

```swift
import TripKit

// Configure TripKit with your API credentials
TripKit.apiKey = "{my API key}"

// After setting the API key, prepare for a new session, which prepares
// internal caches.
TripKit.prepareForNewSession()
```

## Trip Planning

TripKit's trip planning capabilities provide wrappers around SkedGo's routing APIs, parsing and caching the results, and encapsulating the logic for dealing with regions and available modes.

For A-to-B multi-modal routing, use ``TKRouter``:

```swift
let request = TripRequest.insert(
    from: startLocation,
    to: endLocation,
    for: nil, 
    timeType: .leaveASAP, 
    into: TripKit.shared.tripKitContext
)

let router = TKRouter()
router.fetchTrips(for: request) { result in
    switch result {
    case .success:
        // Handle routing results, which are in `trips.request`
    case .failure(let error):
        // Handle error
    }
}
```

For routing with waypoints, use ``TKWaypointRouter``, and for real-time updates, use ``TKRealTimeFetcher``.


## Topics

### Setup & Configuration

- ``TKConfig``
- ``TKRegion``
- ``TKRegionManager``
- ``TKServer``
- ``TKSettings``

### Trip Planning

- ``TKRouter``
- ``TKRealTimeFetcher``
- ``TKWaypointRouter``
- ``TKTripClassifier``
- ``TKMetricClassifier``

### Search & Geocoding

- ``TKAppleGeocoder``
- ``TKCalendarManager``
- ``TKContactsManager``
- ``TKPeliasGeocoder``
- ``TKRegionAutocompleter``
- ``TKRouteAutocompleter``
- ``TKTripGoGeocoder``
- ``TKAggregateGeocoder``

### Data Providers

- ``TKBuzzInfoProvider``
- ``TKDeparturesProvider``

