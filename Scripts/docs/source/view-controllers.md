# View Controllers of TripKitUI

[TripKitUI](TripKit/TripKitUI.html) provides customisable view controllers for the following high-level features:

- **Trip planning** for showing and comparing the different ways of getting from A-to-B, including details screens for each trip both as an overview of the whole trip or the steps of each trip on a mode-by-mode basis.
- **Public transport departures** for a specific stop or station with real-time information, including a details screen for each service that shows the route on the map and in a list.
- **Location search** including autocompletion for searching by addresses, public transport POIs, or your own data sources.
- **Customisable home screen** which ties all of these together, and let's you add additional custom components

Each of these share the following characteristics:

- Customisation points for colours and fonts
- VoiceOver accessible
- Translated into the following languages: Arabic, Chinese (Simplified + Traditional), Danish, Dutch, English, Finnish, French, German, Italian, Japanese, Korean, Norwegian (Bokmål), Portuguese, Spanish and Swedish
- Compatible with iPhone and iPad
- Compatible with iOS 13+
- Compatible with Apple's MapKit out of the box, but can also use other map UI layers, such as Google, HERE or OpenStreetMap
- Source code available

## Real-time departures and service details

<img src="../assets/departures.png" style="height:500px; width: auto;" />

The stand-alone view controller [`TKUITimetableViewController`](TripKit/TripKitUI/Classes/TKUITimetableViewController.html) let's you quickly and easily embed public transport departures. 

This view controller has the following features:

- Show departures for an individual stop or larger station
	- Real-time information where available, including real-time departure and arrival times, service disruptions and crowdedness of individual services.
	- Optionally with wheelchair accessibility information
	- Let users set the time of the first departure time
- Show details of each service
	- Route on the map
	- List of stops including arrival and departure time at each stop
	- Real-time vehicle location where available

It has the following additional customisation points:

- Style of cards via [`TKUICustomization`](TripKit/TripKitUI/Classes/TKUICustomization.html)
- Timetable screen via [`TKUITimetableCard.config`](TripKit/TripKitUI/Classes/TKUITimetableCard/Configuration.html):
  - Customisable list of action buttons

Note: As an alternative to using the stand-alone view controller, you can also take the individual card components ([`TKUITimetableCard`](TripKit/TripKitUI/Classes/TKUITimetableCard.html) and [`TKUIServiceCard`](TripKit/TripKitUI/Classes/TKUIServiceCard.html)) and use them directly in a `TGCardViewController` container.

## Trip planning and trip details

<img src="../assets/routing.png" style="height:500px; width: auto;" />

The stand-alone view controller [`TKUIRoutingResultsViewController`](TripKit/TripKitUI/Classes/TKUIRoutingResultsViewController.html) let's you quickly and easily show routing results between two locations for various modes including combinations of those modes, i.e., this is fully multi-modal and inter-modal.

This view controller has the following features:

- Show routing results to a specified location from the user's current location, or between specified locations
	- High-level comparison of trips, showing durations, cost, carbon emissions, and calories burnt
	- Real-time information, including departure times, traffic, service disruptions, pricing quotes, ETAs
	- Let users select what modes should be included
	- Let users set the time to depart or the time to arrive
- Show details for each trip as an overview


It has the following additional customisation points:

- Style of cards via [`TKUICustomization`](TripKit/TripKitUI/Classes/TKUICustomization.html)
- Results screen via [`TKUIRoutingResultsCard.config`](TripKit/TripKitUI/Classes/TKUIRoutingResultsCard/Configuration.html):
	- Option to provide a feedback action when user presses a "Contact support" button in case of an error or trying to route in an area that's not supported
- Trip overview via [`TKUITripOverviewCard.config`](TripKit/TripKitUI/Classes/TKUITripOverviewCard/Configuration.html):
	- Presentation of attribution
	- Custom callback for what to do when tapping a segment
	- Customisable list of per-trip action buttons
	- Customisable list of per-segment action buttons

Note: As an alternative to using the stand-alone view controller, you can also take the individual card components ([`TKUIRoutingResultsCard`](TripKit/TripKitUI/Classes/TKUIRoutingResultsCard.html) and [`TKUITripOverviewCard`](TripKit/TripKitUI/Classes/TKUITripOverviewCard.html)) and use them directly in a `TGCardViewController` container.

## Trip mode-by-mode overview

<img src="../assets/mode-by-mode.png" style="height:500px; width: auto;" />

The stand-alone view controller [`TKUITripModeByModeViewController`](TripKit/TripKitUI/Classes/TKUITripModeByModeViewController.html) let's you display details of a trip on a mode-by-mode (or segment-by-segment) basis.

This view controller has the following features:

- Show details for a trip on a mode-by-mode basis
- Highly customisable what cards to display for each mode, including custom cards or also the built-in cards like [`TKUITimetableCard`](TripKit/TripKitUI/Classes/TKUITimetableCard.html) or [`TKUIServiceCard`](TripKit/TripKitUI/Classes/TKUIServiceCard.html) from above

It has the following additional customisation points:

- Style of cards via [`TKUICustomization`](TripKit/TripKitUI/Classes/TKUICustomization.html)
- Trip mode-by-mode cards view [`TKUITripModeByModeCard.config`](TripKit/TripKitUI/Classes/TKUITripModeByModeCard/Configuration.html):
  - What cards to display for each segment

Note: As an alternative to using the stand-alone view controller, you can also take the individual card components ([`TKUITripModeByModeCard`](TripKit/TripKitUI/Classes/TKUITripModeByModeCard.html), as well as the per-segment cards) and use them directly in a `TGCardViewController` container. This for example allows to show these mode-by-mode details when a user selects a segment on a trip card (see [`TKUITripOverviewCard`](TripKit/TripKitUI/Classes/TKUITripOverviewCard.html)). 


## Location search

<img src="../assets/search.png" style="height:500px; width: auto;" />

The [`TKUIAutocompletionViewController`](TripKit/TripKitUI/Classes/TKUIAutocompletionViewController.html) can be used with the standard `UISearchController` to provide autocompletion results for addresses, POIs and custom data sources.

The following data sources are included in TripKit:

- [`TKTripGoGeocoder`](TripKit/TripKit/Classes/TKTripGoGeocoder.html) for public transport stops and stations
- [`TKAppleGeocoder`](TripKit/TripKit/Classes/TKAppleGeocoder.html) for addresses and POIs provided by Apple Maps
- [`TKPeliasGeocoder`](TripKit/TripKit/Classes/TKPeliasGeocoder.html) for use with any Pelias-powered geocoder
- [`TKCalendarManager`](TripKit/TripKit/Classes/TKCalendarManager.html) for searching the user's calendar for events with locations
- [`TKContactsManager`](TripKit/TripKit/Classes/TKContactsManager.html) for searching the  user's contacts for locations


## Home screen

The [`TKUIHomeViewController`](TripKit/TripKitUI/Classes/TKUIHomeViewController.html) can be used as a start-screen for the trip planning, timetable and search components -- while being highly customisable to add arbitrary other features.

The built-in functionality is a search bar at the top, which uses the same search functionality as the dedicated [`TKUIAutocompletionViewController`](TripKit/TripKitUI/Classes/TKUIAutocompletionViewController.html) but with the search integrated in the home screen UI, along with a directions button to bring up the [`TKUIRoutingQueryInputCard`](TripKit/TripKitUI/Classes/TKUIRoutingQueryInputCard.html).

The purpose of the home screen is then to add individual *components*, to give users quick access to different section. How to build these, is up to you, but they can be things like:

- The user's favourites
- Recently searched locations
- Nearby locations
- Access to the user's booked trips
- Access to the user's tickets

The `TripKitUIExample` shows to do some of these.

