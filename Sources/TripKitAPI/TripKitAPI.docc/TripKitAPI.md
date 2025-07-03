# ``TripKitAPI``

Low-level API framework providing networking and data models for SkedGo's transportation services.

## Overview

TripKitAPI serves as the foundational networking layer for TripKit, providing direct access to SkedGo's transportation APIs. This framework contains the core data models, networking utilities, and API endpoint definitions that power the higher-level TripKit functionality.

The framework is designed to be lightweight and dependency-free, making it suitable for applications that need direct API access without the full TripKit feature set. It can also be used from Linux.

## Getting Started

To get started with TripKitAPI, you'll need to provide your API key first:

```swift
import TripKitAPI

// Configure TripKit with your API credentials
TKServer.shared.apiKey = "{my API key}"
```

## Trip Planning

TripKit's trip planning capabilities provide wrappers around SkedGo's routing APIs, parsing and caching the results, and encapsulating the logic for dealing with regions and available modes.

For A-to-B multi-modal routing, use ``TKRouter``:

```swift
```

