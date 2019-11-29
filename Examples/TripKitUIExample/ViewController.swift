//
//  ViewController.swift
//  TripKitUIExample
//
//  Created by Adrian Schönig on 29.05.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController
import TripKitUI
import TripKitInterApp

class MainViewController: UITableViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Customizing the look of TripKitUI, showing how to integrate the
    // inter-app actions from TripKitInterApp
     if #available(iOS 13.0, *) {
      TKUITripOverviewCard.config.segmentActionsfactory = { segment in
        var actions = [TKUITripOverviewCardAction]()
        
        if segment.isPublicTransport {
          actions.append(SegmentTimetableAction(segment: segment))
        }
        
        for action in TKInterAppCommunicator.shared.externalActions(for: segment) {
          actions.append(SegmentExternalAction(segment: segment, action: action))
        }
        
        if TKInterAppCommunicator.canOpenInMapsApp(segment) {
          actions.append(SegmentDirectionsAction(segment: segment))
        }
        return actions
      }
    }
    
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let id = tableView.cellForRow(at: indexPath)?.accessibilityIdentifier else {
      preconditionFailure("Missing accessibility identifier for row at \(indexPath)")
    }
    
    switch id {
    case "showSearch":
      showSearch()
      
    case "showRoutes":
      showRoutes()
      
    case "showHome":
      showHome()
      
    default:
      preconditionFailure("Don't know what to do with \(id)")
    }
    
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
}

// MARK: - Search

extension MainViewController {

  func showSearch() {
    // We include TKSkedGoGeocoder here which will provide public transport
    // locations. This requires also a bias map rect, as this only searches on
    // a per-city level.
    guard let randomCity = TKRegionManager.shared.regions.randomElement()?.cities.first else {
      print("Couldn't search as regions weren't fetched.")
      return
    }
    
    let resultsController = TKUIAutocompletionViewController(providers: [TKSkedGoGeocoder()])
    resultsController.biasMapRect = randomCity.centerBiasedMapRect

    resultsController.delegate = self

    // Fix for bad padding between search bar and first row
    // Kudos to https://stackoverflow.com/questions/40435806/extra-space-on-top-of-uisearchcontrollers-uitableview
    resultsController.tableView.contentInsetAdjustmentBehavior = .never

    let searchController = UISearchController(searchResultsController: resultsController)
    searchController.searchResultsUpdater = resultsController
    searchController.searchBar.placeholder = "Search in \(randomCity.title ?? "unnamed city")"
    self.present(searchController, animated: true)
  }

}

extension MainViewController: TKUIAutocompletionViewControllerDelegate {
  
  func autocompleter(_ controller: TKUIAutocompletionViewController, didSelect annotation: MKAnnotation) {
    if let stop = annotation as? TKUIStopAnnotation {
      dismiss(animated: true) {
        self.showDepartures(stop: stop)
      }
      
    } else {
      print("Selected \(annotation)")
    }
  }
  
  func autocompleter(_ controller: TKUIAutocompletionViewController, didSelectAccessoryFor annotation: MKAnnotation) {
    if let stop = annotation as? TKUIStopAnnotation {
      dismiss(animated: true) {
        self.showDepartures(stop: stop)
      }

    } else {
      print("Selected accessor for \(annotation)")
    }
  }
  
}


// MARK: - Departures

extension MainViewController {
  
  func showDepartures(stop: TKUIStopAnnotation) {
    let departures = TKUITimetableViewController(stop: stop)
    departures.delegate = self
    navigationController?.setNavigationBarHidden(true, animated: true)
    navigationController?.pushViewController(departures, animated: true)
  }
  
}

extension MainViewController: TKUITimetableViewControllerDelegate {
  
  func requestsDismissal(for controller: TGCardViewController) {
    navigationController?.setNavigationBarHidden(false, animated: true)
    navigationController?.popViewController(animated: true)
  }
  
}


// MARK: - Routes

extension MainViewController {

  func showRoutes() {
    
    // we generate a random routing request from some city to a random destination
    // diagonally nearby
    guard let randomCity = TKRegionManager.shared.regions.randomElement()?.cities.first else {
      print("Couldn't search as regions weren't fetched.")
      return
    }

    let delta = Double((-10...10).randomElement()!) / 50.0
    let nearby = MKPointAnnotation()
    nearby.coordinate = CLLocationCoordinate2D(latitude: randomCity.coordinate.latitude + delta, longitude: randomCity.coordinate.longitude + delta)
    nearby.title = "Destination"

    let request = TripRequest.insert(
      from: randomCity,
      to: nearby,
      for: nil, timeType: .leaveASAP, into: TripKit.shared.tripKitContext
    )
    
    let routes = TKUIRoutingResultsViewController(request: request)
    routes.delegate = self
    navigationController?.setNavigationBarHidden(true, animated: true)
    navigationController?.pushViewController(routes, animated: true)
  }

}

extension MainViewController: TKUIRoutingResultsViewControllerDelegate {
}

// MARK: - Home

extension MainViewController {
  
  func showHome() {
    let homeController = TKUIHomeViewController()
    homeController.searchResultsDelegate = self
    navigationController?.setNavigationBarHidden(true, animated: true)
    navigationController?.pushViewController(homeController, animated: true)
  }
  
}

extension MainViewController: TKUIHomeCardSearchResultsDelegate {
  
  func homeCard(_ card: TKUIHomeCard, selected searchResult: MKAnnotation) {
    InMemoryHistoryManager.shared.add(searchResult)
  }
  
}

// MARK: - Segment actions

@available(iOS 13.0, *)
fileprivate struct SegmentExternalAction: TKUITripOverviewCardAction {
  let segment: TKSegment
  let action: TKInterAppCommunicator.ExternalAction
  
  var title: String { action.title }
  
  var icon: UIImage {
    switch action.type {
    case .appDeepLink,
         .appDownload:  return UIImage(systemName: "link")!
    case .website:      return UIImage(systemName: "globe")!
    case .message:      return UIImage(systemName: "message")!
    case .phone:        return UIImage(systemName: "phone")!
    case .ticket:       return UIImage(systemName: "cart")!
    }
  }
  
  var handler: (TKUITripOverviewCard, UIView) -> Bool {
    return { [weak segment] card, sender in
      guard
        let segment = segment,
        let controller = card.controller
        else { return false }
      
      TKInterAppCommunicator.shared.perform(self.action, for: segment, presenter: controller, sender: sender)
      return false
    }
  }
}

@available(iOS 13.0, *)
fileprivate struct SegmentDirectionsAction: TKUITripOverviewCardAction {
  let segment: TKSegment

  let title = Loc.GetDirections
  let icon  = UIImage(systemName: "arrow.turn.up.right")!
  let style = TKUICardActionStyle.bold
  
  var handler: (TKUITripOverviewCard, UIView) -> Bool {
    return { [weak segment] card, sender in
      guard
        let segment = segment,
        let controller = card.controller
        else { return false }
      
      TKInterAppCommunicator.openSegmentInMapsApp(segment, forViewController: controller, initiatedBy: sender, currentLocationHandler: nil)
      return false
    }
  }
}

@available(iOS 13.0, *)
fileprivate struct SegmentTimetableAction: TKUITripOverviewCardAction {
  let segment: TKSegment

  let title = "Show timetable"
  let icon  = UIImage(systemName: "clock")!
  
  var handler: (TKUITripOverviewCard, UIView) -> Bool {
    return { [weak segment] card, sender in
      guard
        let segment = segment,
        let dls = TKDLSTable(for: segment),
        let controller = card.controller
        else { return false }
      
      // The TKUITimetableCard's title doesn't work well yet with a DLS table, so we use this instead
      let segmentTitle = TKUISegmentTitleView.newInstance()
      segmentTitle.configure(for: segment, mode: .getReady)
      
      let departures = TKUITimetableCard(titleView: (segmentTitle, segmentTitle.dismissButton), dlsTable: dls, startDate: segment.departureTime.addingTimeInterval(-10 * 60), selectedServiceID: segment.service?.code)
      controller.push(departures)
      return false
    }
  }
}
