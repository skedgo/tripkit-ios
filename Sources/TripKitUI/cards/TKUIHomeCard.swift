//
//  TKUIHomeCard.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 28/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit
import UIKit
import SwiftUI

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

// MARK: -

open class TKUIHomeCard: TKUITableCard {
  
  public static var config = Configuration.empty
  
  public var searchResultDelegate: TKUIHomeCardSearchResultsDelegate?
  
  private let cardAppearancePublisher = PublishSubject<Bool>()
  private let searchTextPublisher = PublishSubject<(String, forced: Bool)>()
  private let focusedAnnotationPublisher = PublishSubject<MKAnnotation?>()
  private let cellAccessoryTapped = PublishSubject<TKUIHomeViewModel.Item>()
  private let refreshPublisher = PublishSubject<Void>()
  private let actionTriggered = PublishSubject<TKUIHomeCard.ComponentAction>()
  
  private var viewModel: TKUIHomeViewModel!

  public let disposeBag = DisposeBag()
  
  private let headerView: TKUIHomeHeaderView
  
  private var tableView: UITableView!
  
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>!
  
  private let homeMapManager: TKUICompatibleHomeMapManager
  
  public init(mapManager: TKUICompatibleHomeMapManager? = nil, initialPosition: TGCardPosition? = .peaking) {
    let theMapManager = mapManager ?? TKUISimpleHomeMapManager()
    self.homeMapManager = theMapManager
    
    let hasGrabHandle: Bool
    #if targetEnvironment(macCatalyst)
    hasGrabHandle = false
    #else
    hasGrabHandle = true
    #endif
    
    self.headerView = TKUIHomeHeaderView(hasGrabHandle: hasGrabHandle)

    super.init(title: .custom(headerView, dismissButton: nil), mapManager: theMapManager, initialPosition: initialPosition)
    
    headerView.searchBar.placeholder = Loc.SearchForDestination
    headerView.searchBar.delegate = self
    
    topMapToolBarItems = Self.config.topMapToolbarItems
  }
  
  /// Puts the focus to the search bar in the header view, ready for users to begin typing destination.
  public func enterSearchMode() {
    headerView.searchBar.becomeFirstResponder()
  }
  
  // MARK: - TGCard overrides
  
  open override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    tableView.keyboardDismissMode = .onDrag

    tableView.register(TKUIHomeCardSectionHeader.self, forHeaderFooterViewReuseIdentifier: "TKUIHomeCardSectionHeader")
    
    if #available(iOS 16, *) {
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
    } else {
      tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    }
    
    tableView.dataSource = nil
    tableView.tableFooterView = UIView() // no trailing separators
    
    self.tableView = tableView
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>(
      configureCell: { [weak self] _, tv, ip, item -> UITableViewCell in
        var fallback: UITableViewCell { UITableViewCell(style: .default, reuseIdentifier: nil) }
        
        guard let self else {
          // Shouldn't but can happen on dealloc
          return fallback
        }
        
        switch item {
        case .search(let searchItem):
          if #available(iOS 16, *) {
            let cell = tv.dequeueReusableCell(withIdentifier: "plain", for: ip)
            cell.contentConfiguration = UIHostingConfiguration {
              TKUIAutocompletionResultView(item: searchItem) { [weak self] in
                self?.cellAccessoryTapped.onNext(.search($0))
              }
            }
            return cell
            
          } else {
            guard
              let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell
            else { assertionFailure("Unable to load an instance of TKUIAutocompletionResultCell"); return fallback }
            
            cell.configure(
              with: searchItem,
              onAccessoryTapped: { [weak self] in self?.cellAccessoryTapped.onNext(.search($0)) }
            )
            cell.accessibilityTraits = .button
            return cell
          }
          
        case .component(let componentItem):
          guard let cell = self.viewModel.componentViewModels.compactMap({ $0.cell(for: componentItem, at: ip, in: tv) }).first else {
            assertionFailure("No component returned a cell for \(componentItem) at \(ip)."); return fallback
          }
          cell.accessibilityTraits = componentItem.isAction ? .button : .none
          return cell
        }
        
      }, canEditRowAtIndexPath: { (ds, ip) in
        let item = ds[ip]
        switch item {
        case .search: return false
        case .component(let componentItem): return componentItem.canEdit
        }
      }
    )
    self.dataSource = dataSource
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
        
    let builderInput = TKUIHomeComponentInput(
      homeCardWillAppear: cardAppearancePublisher,
      itemSelected: selectedItem(in: tableView, dataSource: dataSource).compactMap(\.componentItem),
      mapRect: homeMapManager.mapRect
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
      .map { !$0.0.isEmpty || $0.forced }
      .asSignal(onErrorJustReturn: false)

    let searchInput = TKUIHomeViewModel.SearchInput(
      searchInProgress: searchInProgress.startWith(false).asDriver(onErrorJustReturn: false),
      searchText: searchTextPublisher,
      itemSelected: selectedItem(in: tableView, dataSource: dataSource),
      itemAccessoryTapped: cellAccessoryTapped.asAssertingSignal(),
      refresh: refreshPublisher.asAssertingSignal(),
      biasMapRect: homeMapManager.mapRect.startWith(.null)
    )

    viewModel = TKUIHomeViewModel(
      componentViewModels: components,
      actionInput: actionTriggered.asAssertingSignal(),
      searchInput: searchInput
    )
    
    // List content
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // List interaction
    
    viewModel.next
      .emit(onNext: { [weak self] in self?.handleNext($0) })
      .disposed(by: disposeBag)
    
    viewModel.error
      .emit(onNext: { [weak self] in self?.controller?.show($0) })
      .disposed(by: disposeBag)
    
    headerView.directionsButton?.rx.tap.asSignal()
      .emit(onNext: { [weak self] in
        self?.showQueryInput(startingInDestinationMode: Self.config.directionButtonStartsQueryInputInDestinationMode)
      })
      .disposed(by: disposeBag)

    // Map interaction
    
    homeMapManager.nextFromMap
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in self?.actionTriggered.onNext($0) })
      .disposed(by: disposeBag)
  }
  
  open override func willAppear(animated: Bool) {
    // If the search text is empty when the card appears,
    // try loading autocompletion results.
    if let text = headerView.searchBar.text, 
        text.isEmpty {
      let forced = headerView.searchBar.isFirstResponder
      searchTextPublisher.onNext(("", forced: forced))
    }
    
    cardAppearancePublisher.onNext(true)
    
    // Remove any focused annotation, i.e., restoring any
    // hideen nearby annotations.
    focusedAnnotationPublisher.onNext(nil)
    
    // Remove any selection on the map
    homeMapManager.onHomeCardAppearance(true)
    
    super.willAppear(animated: animated)
  }
  
  open override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
  
  open override func didDisappear(animated: Bool) {
    super.didDisappear(animated: animated)
    
    cardAppearancePublisher.onNext(false)
  }
  
  open override var preferredView: UIView? {
    switch Self.config.voiceOverStartMode {
    case .searchBar:
      return headerView.searchBar
    case .routeButton:
      return headerView.directionsButton
    }
  }
}

// MARK: - Action on search result

extension TKUIHomeCard {
  
  private func exitSearchMode() {
    headerView.searchBar.text = nil
    headerView.searchBar.resignFirstResponder()
    headerView.hideDirectionButton(false)
  }
  
  private func handleNext(_ next: TKUIHomeViewModel.NextAction) {
    guard let cardController = controller else { return }
    
    func dismissSelection() {
      if let selected = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: selected, animated: true)
      }
    }
    
    switch next {
    case .trigger(let handler):
      handler(cardController)
      
    case .present(let controller, let inNavigator):
      cardController.present(controller, inNavigator: inNavigator)
      dismissSelection()
      
    case .push(let card, let selection):
      exitSearchMode()
      if let selection = selection {
        searchResultDelegate?.homeCard(self, selected: selection)
      }
      if cardController.topCard == self {
        cardController.push(card)
      } else {
        cardController.swap(for: card)
      }
      
    case .showCustomizer(let items):
      showCustomizer(items: items)
      dismissSelection()
      
    case let .handleSelection(.annotation(city as TKRegion.City), _):
      clearSearchBar()
      
      controller?.draggingCardEnabled = true
      controller?.moveCard(to: .collapsed, animated: true) {
        // Not animating this as it's typically a big jump
        self.homeMapManager.zoom(to: city, animated: false)
      }
      
    case .enterSearchMode:
      enterSearchMode()
      
    case let .handleSelection(selection, component):
      switch Self.config.selectionMode {
      case .selectOnMap:
        switch selection {
        case let .annotation(annotation):
          homeMapManager.select(annotation)
        case .result:
          assertionFailure("You are using a `TKAutocompleting` provider that does not return annotations for some of its results. In this case, make sure to use the callback selection mode.")
        }
        
      case let .callback(handler):
        if handler(selection, component) {
          if case let .annotation(annotation) = selection {
            focusedAnnotationPublisher.onNext(annotation)
          }
        }
        
      case .default:
        exitSearchMode()
        switch selection {
        case let .annotation(stop as TKUIStopAnnotation):
          cardController.push(TKUITimetableCard(stops: [stop]))
        case let .annotation(annotation):
          cardController.push(TKUIRoutingResultsCard(destination: annotation))
        case .result:
          assertionFailure("You are using a `TKAutocompleting` provider that does not return annotations for some of its results. In this case, make sure to use the callback selection mode.")
        }
      }
      
    case let .handleAction(handler):
      handler(cardController)
        .subscribe(onSuccess: { [weak self] refresh in
          if refresh {
            self?.refreshPublisher.onNext(())
          }
        })
        .disposed(by: disposeBag)
    }
  }
  
  /// Pushes the routing query input card and handles its response.
  public func showQueryInput(startingInDestinationMode: Bool = true) {
    let mapRect = (homeMapManager as? TKUIMapManager)?.mapView?.visibleMapRect ?? .world
    let queryInputCard = TKUIRoutingQueryInputCard(biasMapRect: mapRect)
    queryInputCard.startMode = startingInDestinationMode ? .destination : .origin
    queryInputCard.queryDelegate = self
    handleNext(.push(queryInputCard, selection: nil))
  }
  
}

extension TKUIHomeCard: TKUIRoutingQueryInputCardDelegate {
  public func routingQueryInput(card: TKUIRoutingQueryInputCard, selectedOrigin origin: MKAnnotation, destination: MKAnnotation) {
    let routingResultsCard = TKUIRoutingResultsCard(destination: destination, origin: origin)
    
    // We don't want the query input card anymore as it's accessible from the results card
    controller?.swap(for: routingResultsCard, animated: true)
  }
}

// MARK: - Search bar

extension TKUIHomeCard: UISearchBarDelegate {
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    let forced = searchText.isEmpty && searchBar.isFirstResponder
    searchTextPublisher.onNext((searchText, forced: forced))
  }
  
  public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
    headerView.hideDirectionButton(true)
    controller?.moveCard(to: .extended, animated: true)
    controller?.draggingCardEnabled = false
    searchTextPublisher.onNext(("", forced: true))
  }
  
  public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = false
  }
  
  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    clearSearchBar()
    headerView.hideDirectionButton(false)
    controller?.moveCard(to: initialPosition ?? .peaking, animated: true)
    controller?.draggingCardEnabled = true
  }
  
  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    headerView.hideDirectionButton(false)
    controller?.moveCard(to: .peaking, animated: true)
    controller?.draggingCardEnabled = true
  }
  
  private func clearSearchBar() {
    // Clear the text on search bar
    headerView.searchBar.text = ""
    
    // Clear the results
    searchTextPublisher.onNext(("", forced: false))
    
    // Dismiss the keyboard
    headerView.searchBar.resignFirstResponder()
  }
  
}

// MARK: - Table view delegates

extension TKUIHomeCard: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    guard let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "TKUIHomeCardSectionHeader") as? TKUIHomeCardSectionHeader else {
      return nil
    }
    
    header.configure(with: dataSource.sectionModels[section].headerConfiguration, homeCard: self) { [weak self] in
      self?.actionTriggered.onNext($0)
    }
    return header
  }
  
  public func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let item = self.dataSource[indexPath].componentItem else { return nil }
    let configurations = self.viewModel.componentViewModels.compactMap { $0.trailingSwipeActionsConfiguration(for: item, at: indexPath, in: tableView) }
    assert(configurations.count <= 1, "Two component view models handle the same item?")
    return configurations.first
  }
  
  public func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
    guard let item = self.dataSource[indexPath].componentItem else { return nil }
    let configurations = self.viewModel.componentViewModels.compactMap { $0.leadingSwipeActionsConfiguration(for: item, at: indexPath, in: tableView) }
    assert(configurations.count <= 1, "Two component view models handle the same item")
    return configurations.first
  }
  
  public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard let item = self.dataSource[indexPath].componentItem else { return nil }
    let configurations = self.viewModel.componentViewModels.compactMap { $0.contextMenuConfiguration(for: item, at: indexPath, in: tableView) }
    assert(configurations.count <= 1, "Two component view models handle the same item")
    return configurations.first
  }
  
}
