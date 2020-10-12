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

// MARK: -

public class TKUIHomeCard: TKUITableCard {
  
  public static var config = Configuration.empty
  
  public var searchResultDelegate: TKUIHomeCardSearchResultsDelegate?
  
  private let cardWillAppearPublisher = PublishSubject<Bool>()
  
  private let searchTextPublisher = PublishSubject<(String, forced: Bool)>()
  
  private let focusedAnnotationPublisher = PublishSubject<MKAnnotation?>()
  
  private let cellAccessoryTappedPublisher = PublishSubject<TKUIHomeViewModel.Item>()
  
  private var viewModel: TKUIHomeViewModel!

  private let disposeBag = DisposeBag()
  
  private let searchBar = UISearchBar()
  
  private var tableView: UITableView!
  
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>!
  
  private let homeMapManager: TKUICompatibleHomeMapManager?
  
  public init(mapManager: TKUICompatibleHomeMapManager? = nil, initialPosition: TGCardPosition? = .peaking) {
    self.homeMapManager = mapManager

    // Home card requires a custom title view that includes
    // a search bar only.
    super.init(title: .custom(searchBar, dismissButton: nil), mapManager: mapManager, initialPosition: initialPosition)
    
    searchBar.delegate = self
    searchBar.barTintColor = .tkBackground
  }
  
  required convenience init?(coder: NSCoder) {
    self.init()
  }
  
  // MARK: - TGCard overrides
  
  public override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    requestLocationServicesIfNeeded()
    
    if let topItems = Self.config.topMapToolbarItems {
      self.topMapToolBarItems = topItems
    }
    
    tableView.register(TKUIHomeCardSectionHeader.self, forHeaderFooterViewReuseIdentifier: "TKUIHomeCardSectionHeader")
    
    tableView.dataSource = nil
    
    self.tableView = tableView
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>(
      configureCell: { [weak self] _, tv, ip, item in
        guard let self = self else {
          // Shouldn't but can happen on dealloc
          return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        guard let cell = (self.viewModel.componentViewModels.compactMap { $0.cell(for: item, at: ip, in: tv) }.first) else {
          assertionFailure(); return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        return cell
      }
    )
    self.dataSource = dataSource
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
        
    let builderInput = TKUIHomeCard.ComponentViewModelInput(
      homeCardWillAppear: cardWillAppearPublisher,
      searchText: searchTextPublisher,
      itemSelected: selectedItem(in: tableView, dataSource: dataSource),
      itemDeleted: tableView.rx.modelDeleted(TKUIHomeViewModel.Item.self).asSignal(),
      itemAccessoryTapped: cellAccessoryTappedPublisher.asSignal(onErrorSignalWith: .empty()),
      mapRect: homeMapManager?.mapRect ?? .empty()
    )
      
    // The Home view model is in essence a dumb aggregator that
    // relies on component view models to provide it with data.
    let components: [TKUIHomeComponentViewModel] = Self.config.componentViewModelClasses
      .map { $0.buildInstance(from: builderInput) }
    
    // Component view model gets a say on what they want to do
    // with the table view, e.g., what cells they want to use.
    components.forEach { $0.registerCell(with: tableView) }
    
    // We will be hiding some sections while search in progress. The
    // Home view model thus needs to know this event.
    let searchInProgress = searchTextPublisher
      .map { !$0.0.isEmpty }
      .asSignal(onErrorJustReturn: false)
    
    let cardInputEvent = TKUIHomeViewModel.CardInputEvent(
      searchInProgress: searchInProgress.startWith(false)
    )
    
    viewModel = TKUIHomeViewModel(componentViewModels: components, event: cardInputEvent)
    
    // List content
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // List interaction
    
    viewModel.next
      .emit(onNext:  { [weak self] in self?.handleNext($0) })
      .disposed(by: disposeBag)
    
    // Map interaction
    
    homeMapManager?.nextFromMap
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] in self?.handleNext($0) })
      .disposed(by: disposeBag)
  }
  
  public override func willAppear(animated: Bool) {
    // If the search text is empty when the card appears,
    // try loading autocompletion results.
    if let text = searchBar.text, text.isEmpty {
      searchTextPublisher.onNext(("", forced: true))
    }
    
    cardWillAppearPublisher.onNext(true)
    
    // Remove any focused annotation, i.e., restoring any
    // hideen nearby annotations.
    focusedAnnotationPublisher.onNext(nil)
    
    // Remove any selection on the map
    homeMapManager?.onHomeCardAppearance(true)
    
    super.willAppear(animated: animated)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
}

// MARK: -

extension TKUIHomeCard {
  
  private func requestLocationServicesIfNeeded() {
    guard
      Self.config.requestLocationServicesOnLoad,
      CLLocationManager.authorizationStatus() == .notDetermined
      else { return }
    
    TKLocationManager.shared.ask { (enabled) in
      guard enabled else { return }
      self.homeMapManager?.mapView?.userTrackingMode = .follow
    }
  }
  
}

// MARK: - Action on search result

extension TKUIHomeCard {
  
  private func prepareForNewCard(onCompletion handler: (() -> Void)? = nil) {
    searchBar.text = nil
    searchBar.resignFirstResponder()
    self.controller?.moveCard(to: initialPosition ?? .peaking, animated: false, onCompletion: handler)
  }
  
  private func handleNext(_ next: TKUIHomeCardNextAction) {
    switch next {
    case .present(let controller):
      self.controller?.present(controller, animated: true)
      
      if let selected = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: selected, animated: true)
      }
      
    case .push(let card):
      prepareForNewCard {
        if self.controller?.topCard == self {
          self.controller?.push(card)
        } else {
          self.controller?.swap(for: card)
        }
      }
      
    case .selectOnMap(let annotation):
      homeMapManager?.select(annotation)
    }
  }
  
  private func showRoutes(to destination: MKAnnotation) {
    prepareForNewCard { [weak self] in
      guard let self = self else { return }
      
      // We push the routing card. To replicate Apple Maps, we put
      // the routing card at the peaking position when it's pushed.
      let routingResultCard = TKUIRoutingResultsCard(destination: destination)
      self.controller?.push(routingResultCard)
      
      self.searchResultDelegate?.homeCard(self, selected: destination)
    }
  }
  
  private func showTimetable(for annotation: MKAnnotation) {
    guard let stop = annotation as? TKUIStopAnnotation else { return }
    
    prepareForNewCard { [weak self] in
      guard let self = self else { return }
      
      // We push the timetable card. To replicate Apple Maps, we put
      // the timetable card at the peaking position when it's pushed.
      let timetableCard = TKUITimetableCard(stops: [stop], reusing: (self.mapManager as? TKUIMapManager), initialPosition: .peaking)
      if self.controller?.topCard is TKUITimetableCard {
        // If we are already showing a timetable card,
        // instead of pushing another one, we swap it
        self.controller?.swap(for: timetableCard, animated: true)
      } else {
        self.controller?.push(timetableCard)
      }
      
      self.searchResultDelegate?.homeCard(self, selected: stop)
      
      // This removes nearby annotations and leaves only the stop
      // visible on the map.
      self.focusedAnnotationPublisher.onNext(stop)
    }
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
    controller?.moveCard(to: initialPosition ?? .peaking, animated: true)
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

// MARK: - Table view delegates

extension TKUIHomeCard: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TKUIHomeCardSectionHeader") as? TKUIHomeCardSectionHeader else {
      return nil
    }
    
    if let configuration = dataSource.sectionModels[section].headerConfiguration {
      header.label.text = configuration.title
      if let action = configuration.action {
        header.button.setTitle(action.title, for: .normal)
        header.button.rx.tap
          .subscribe(onNext: { [weak self] in self?.handleNext(action.handler()) })
          .disposed(by: disposeBag)
      }
        
    } else {
      header.label.text = nil
      header.button.setTitle(nil, for: .normal)
    }
    
    return header
  }
  
}
