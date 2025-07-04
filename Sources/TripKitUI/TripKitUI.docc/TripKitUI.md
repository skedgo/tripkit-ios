# ``TripKitUI``

User interface framework providing pre-built view controllers and UI components for transportation applications.

## Overview

TripKitUI builds upon TripKit to provide a comprehensive suite of user interface components for transportation and mobility applications. It includes ready-to-use view controllers, cards, and UI utilities that implement common transportation app patterns and user flows.

The framework provides everything you need to build sophisticated trip planning interfaces, from routing and search to timetables and real-time updates, all with a consistent and polished user experience.

## Topics

### Trip Planning Interface

Components for displaying routing results and trip information.

- ``TKUIRoutingResultsViewController``
- ``TKUIRoutingResultsViewControllerDelegate``
- ``TKUIRoutingResultsCard``
- ``TKUIRoutingResultsCardDelegate``
- ``TKUIRoutingQueryInputCard``
- ``TKUIRoutingQueryInputCardDelegate``
- ``TKUITripOverviewViewController``
- ``TKUITripOverviewCard``
- ``TKUITripModeByModeViewController``
- ``TKUITripModeByModeViewControllerDelegate``
- ``TKUITripModeByModeCard``
- ``TKUITripModeByModePageBuilder``

### Timetable Interface

Components for displaying public transport schedules and departure information.

- ``TKUITimetableViewController``
- ``TKUITimetableViewControllerDelegate``
- ``TKUITimetableCard``
- ``TKUITimetableCardDelegate``
- ``TKUIServiceCard``

### Search Interface

Components for location search and autocompletion.

- ``TKUIAutocompletionViewController``
- ``TKUIAutocompletionViewControllerDelegate``

### Home Screen Interface

Components for building customizable home screen experiences.

- ``TKUIHomeViewController``
- ``TKUIHomeCard``
- ``TKUIHomeCardSearchResultsDelegate``
- ``TKUIHomeComponentViewModel``
- ``TKUIHomeComponentContent``
- ``TKUIHomeComponentInput``
- ``TKUIHomeComponentItem``
- ``TKUIHomeHeaderConfiguration``
- ``TKUIHomeCardCustomizerItem``

### Core UI Components

Essential UI utilities and customization options.

- ``TKUICardAction``
- ``TKUICustomization``
- ``TKUIMapManager``

## Getting Started

TripKitUI provides high-level view controllers that can be easily integrated into your application:

```swift
import TripKitUI
import TripKit

// Create a routing results view controller
let routingVC = TKUIRoutingResultsViewController()
routingVC.delegate = self

// Present the view controller
navigationController?.pushViewController(routingVC, animated: true)
```

### Customization

TripKitUI supports extensive customization through the ``TKUICustomization`` class:

```swift
// Customize the appearance
TKUICustomization.shared.primaryColor = .systemBlue
TKUICustomization.shared.navigationBarStyle = .default
```

## Architecture

TripKitUI follows a card-based architecture where complex interfaces are built using reusable card components. Each card encapsulates specific functionality and can be combined to create rich user experiences.

### Card-Based Design

The framework uses a consistent card-based approach:

- **Cards**: Self-contained UI components (e.g., ``TKUIRoutingResultsCard``)
- **View Controllers**: Container classes that manage cards and user interaction
- **Delegates**: Protocol-based communication between components

### Integration with TripKit

TripKitUI seamlessly integrates with TripKit's data layer, automatically handling:

- Real-time data updates
- Caching and offline support  
- Regional configuration
- Multi-modal trip planning

This integration means you can focus on user experience while the framework handles the complexity of transportation data management.