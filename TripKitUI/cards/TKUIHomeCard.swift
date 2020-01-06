//
//  TKUIHomeCard.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 28/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

import TGCardViewController

public protocol TKUIHomeCardSearchResultsDelegate: class {
  
  func homeCard(_ card: TKUIHomeCard, selected searchResult: MKAnnotation)
  
}


// MARK: -

public class TKUIHomeCard: TGTableCard {
  
  public static var config = Configuration.empty
  
  public var searchResultDelegate: TKUIHomeCardSearchResultsDelegate?
  
  private let searchTextPublisher = PublishSubject<(String, forced: Bool)>()
  
  private let focusedAnnotationPublisher = PublishSubject<MKAnnotation?>()
  
  private let searchResultAccessoryTapped = PublishSubject<TKUIAutocompletionViewModel.Item>()
  
  private var viewModel: TKUIHomeViewModel!
  
  private let nearbyMapManager: TKUINearbyMapManager

  private let disposeBag = DisposeBag()
  
  private let searchBar = UISearchBar()
  
  init() {
    let mapManager = TKUINearbyMapManager()
    self.nearbyMapManager = mapManager
    
    // Home card requires a custom title view that includes
    // a search bar only.
    super.init(title: .custom(searchBar, dismissButton: nil), mapManager: mapManager, initialPosition: .peaking)
    
    searchBar.delegate = self
  }
  
  required convenience init?(coder: NSCoder) {
    self.init()
  }
  
  private func resetCard() {
    // Clear search results and uses any default values, e.g.,
    // past searches or favorites, if available.
    searchTextPublisher.onNext(("", forced: true))
    
    // Remove focused map annotation and display nearbys.
    focusedAnnotationPublisher.onNext(nil)
    
    // Remove any selection on the map
    if let selected = nearbyMapManager.mapView?.selectedAnnotations.first {
      nearbyMapManager.mapView?.deselectAnnotation(selected, animated: true)
    }
  }
  
  // MARK: - TGCard overrides
  
  public override func willAppear(animated: Bool) {
    resetCard()
    super.willAppear(animated: animated)
  }
  
  public override func didBuild(tableView: UITableView, headerView: TGHeaderView?) {
    super.didBuild(tableView: tableView, headerView: headerView)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>(
      configureCell: { [weak self] _, tv, ip, item in
        guard let self = self else {
          // Shouldn't but can happen on dealloc
          return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        guard let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell else {
          preconditionFailure("Couldn't dequeue TKUIAutocompletionResultCell")
        }
        
        cell.configure(with: item, onAccessoryTapped: self.searchResultAccessoryTapped)
        
        return cell
      },
      titleForHeaderInSection: { ds, index in
        return ds.sectionModels[index].title
      }
    )
    
    tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    
    let listInput = TKUIHomeViewModel.ListInput(
      searchText: searchTextPublisher.asObservable(),
      selected: tableView.rx.itemSelected.map { dataSource[$0] }.asSignal(onErrorSignalWith: .empty()),
      accessorySelected: searchResultAccessoryTapped.asSignal(onErrorSignalWith: .empty())
    )

    let mapInput = TKUIHomeViewModel.MapInput(
      mapRect: nearbyMapManager.mapRect,
      selected: nearbyMapManager.mapSelection,
      focused: focusedAnnotationPublisher.asSignal(onErrorSignalWith: .empty())
    )
    
    viewModel = TKUIHomeViewModel(
      listInput: listInput,
      mapInput: mapInput
    )
    
    // List content
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // Map content

    nearbyMapManager.viewModel = viewModel.nearbyViewModel
    
    // Interaction
    
    viewModel.selection
      .emit(onNext: { [weak self] in self?.showRoutes(to: $0) })
      .disposed(by: disposeBag)
    
    viewModel.accessorySelection
      .emit(onNext: { [weak self] in self?.showTimetable(for: $0) })
      .disposed(by: disposeBag)
    
    viewModel.nextFromMap
      .emit(onNext:  { [weak self] in self?.handleNextFromMap($0) })
      .disposed(by: disposeBag)
  }
  
}

// MARK: - Action on search result

extension TKUIHomeCard {
  
  private func prepareForNewCard() {
    // To replicate Apple Maps, once a user dismiss the routing card,
    // the search bar is cleared and the card in which it's embedeed,
    // i.e., Home card, is moved back to the peaking position. To do
    // this, we call `clearSearchBar` method, however, this **must**
    // be called before the routing card is pushed.
    self.clearSearchBar()
    
    // Also replicating Apple Maps, when the routing card is dismissed,
    // the home card is moved back to the peak position. This **must**
    // be done before the routing card is pushed, as the TGCardVC notes
    // the position of a card before a new one is pushed.
    self.controller?.moveCard(to: .peaking, animated: true)
  }
  
  private func showRoutes(to destination: MKAnnotation) {
    prepareForNewCard()
    
    // We push the routing card. To replicate Apple Maps, we put
    // the routing card at the peaking position when it's pushed.
    let routingResultCard = TKUIRoutingResultsCard(destination: destination, initialPosition: .peaking)
    controller?.push(routingResultCard)
    searchResultDelegate?.homeCard(self, selected: destination)
  }
  
  private func showTimetable(for annotation: MKAnnotation) {
    guard let stop = annotation as? TKUIStopAnnotation else { return }
    
    prepareForNewCard()
    
    // We push the timetable card. To replicate Apple Maps, we put
    // the timetable card at the peaking position when it's pushed.
    let timetableCard = TKUITimetableCard(stops: [stop], reusing: (mapManager as? TKUIMapManager), initialPosition: .peaking)
    
    if controller?.topCard is TKUITimetableCard {
      // If we are already showing a timetable card,
      // instead of pushing another one, we swap it
      controller?.swap(for: timetableCard, animated: true)
    } else {
      controller?.push(timetableCard)
    }
    
    searchResultDelegate?.homeCard(self, selected: stop)
    
    focusedAnnotationPublisher.onNext(stop)
  }
  
  private func handleTap(on location: TKModeCoordinate) {
    guard let handler = TKUIHomeCard.config.presentLocationHandler else { return }
    if handler(self, location) {
      focusedAnnotationPublisher.onNext(location)
    }
  }
  
  private func handleNextFromMap(_ next: TKUINearbyViewModel.Next) {
    switch next {
    case .stop(let stop): showTimetable(for: stop)
    case .location(let location): handleTap(on: location)
    }
  }
  
}

// MARK: - Search bar

extension TKUIHomeCard: UISearchBarDelegate {
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextPublisher.onNext((searchText, forced: false))
  }
  
  public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
    self.controller?.moveCard(to: .extended, animated: true)
  }
  
  public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = false
  }
  
  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    clearSearchBar()
    controller?.moveCard(to: .peaking, animated: true)
  }
  
  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    self.controller?.moveCard(to: .peaking, animated: true)
  }
  
  private func clearSearchBar() {
    // Clear the text on search bar
    searchBar.text = ""
    
    // Clear the results
    searchTextPublisher.onNext(("", forced: false))
    
    // Dismiss the keyboard
    searchBar.resignFirstResponder()
  }
  
}

