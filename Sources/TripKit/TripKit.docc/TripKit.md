# ``TripKit``

Core framework for trip planning, routing, and transportation data in iOS applications.

## Overview

TripKit provides the foundational capabilities for building transportation and mobility applications. It offers comprehensive trip planning functionality, real-time data fetching, and robust configuration management for SkedGo's routing APIs.

The framework handles multi-modal routing, waypoint-based navigation, real-time updates, and integrates seamlessly with SkedGo's transportation network data.

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

## Getting Started

To get started with TripKit, you'll need to configure your application with the appropriate server settings and region information:

```swift
import TripKit

// Configure TripKit with your API credentials
TKConfig.shared.configure(with: serverURL, apiKey: apiKey)

// Set up region management
let regionManager = TKRegionManager.shared
regionManager.requireRegions()
```

## Trip Planning

TripKit's trip planning capabilities provide wrappers around SkedGo's routing APIs, parsing and caching the results, and encapsulating the logic for dealing with regions and available modes.

For A-to-B multi-modal routing, use ``TKRouter``:

```swift
let router = TKRouter()
router.route(from: startLocation, to: endLocation) { result in
    // Handle routing results
}
```

For routing with waypoints, use ``TKWaypointRouter``, and for real-time updates, use ``TKRealTimeFetcher``.