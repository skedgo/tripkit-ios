# ``TripKitAPI``

Low-level API framework providing networking and data models for SkedGo's transportation services.

## Overview

TripKitAPI serves as the foundational networking layer for TripKit, providing direct access to SkedGo's transportation APIs. This framework contains the core data models, networking utilities, and API endpoint definitions that power the higher-level TripKit functionality.

The framework is designed to be lightweight and dependency-free, making it suitable for applications that need direct API access without the full TripKit feature set.

## Topics

### Core Models

API data models and structures for transportation data.

### Networking

Low-level networking components for API communication.

### Endpoints

API endpoint definitions and request builders.

### Utilities

Helper classes and extensions for API operations.

## Getting Started

TripKitAPI can be used independently for direct API access:

```swift
import TripKitAPI

// Configure API settings
// Use TripKitAPI classes directly for low-level API operations
```

For most use cases, you'll want to use the higher-level TripKit framework instead, which builds upon TripKitAPI and provides more convenient abstractions.

## Architecture

TripKitAPI is structured as a clean, dependency-free foundation that:

- Defines all data models used by SkedGo's APIs
- Provides networking primitives for API communication  
- Handles serialization and deserialization of API responses
- Offers endpoint definitions and request building utilities

This separation allows for flexible integration scenarios and makes testing easier by providing clear boundaries between API communication and business logic.