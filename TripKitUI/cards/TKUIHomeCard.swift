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

import TGCardViewController

// MARK: -

open class TKUIHomeCard: TKUITableCard {
  
  public static var config = Configuration.empty
  
  public var searchResultDelegate: TKUIHomeCardSearchResultsDelegate?
  
  private let cardAppearancePublisher = PublishSubject<Bool>()
  private let searchTextPublisher = PublishSubject<(String, forced: Bool)>()
  private let focusedAnnotationPublisher = PublishSubject<MKAnnotation?>()
  private let cellAccessoryTappedPublisher = PublishSubject<TKUIHomeViewModel.Item>()
  private let refreshPublisher = PublishSubject<Void>()
  private let actionTriggered = PublishSubject<TKUIHomeCard.ComponentAction>()
  let customizationTriggered = PublishSubject<[TKUIHomeCard.CustomizedItem]>()
  
  private var viewModel: TKUIHomeViewModel!

  public let disposeBag = DisposeBag()
  
  private let headerView: TKUIHomeHeaderView
  
  private var tableView: UITableView!
  
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>!
  
  private let homeMapManager: TKUICompatibleHomeMapManager?
  
  public init(mapManager: TKUICompatibleHomeMapManager? = nil, initialPosition: TGCardPosition? = .peaking) {
    self.homeMapManager = mapManager
    self.headerView = TKUIHomeHeaderView()

    super.init(title: .custom(headerView, dismissButton: nil), mapManager: mapManager, initialPosition: initialPosition)
    
    headerView.searchBar.placeholder = Loc.SearchForDestination
    headerView.searchBar.delegate = self
  }
  
  required convenience public init?(coder: NSCoder) {
    self.init()
  }
  
  // MARK: - TGCard overrides
  
  open override func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    tableView.keyboardDismissMode = .onDrag
        
    if let topItems = Self.config.topMapToolbarItems {
      self.topMapToolBarItems = topItems
    }
    
    tableView.register(TKUIHomeCardSectionHeader.self, forHeaderFooterViewReuseIdentifier: "TKUIHomeCardSectionHeader")
    tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    
    tableView.dataSource = nil
    
    self.tableView = tableView
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIHomeViewModel.Section>(
      configureCell: { [weak self] _, tv, ip, item -> UITableViewCell in
        var fallback: UITableViewCell { UITableViewCell(style: .default, reuseIdentifier: nil) }
        
        guard let self = self else {
          // Shouldn't but can happen on dealloc
          return fallback
        }
        
        switch item {
        case .search(let searchItem):
          guard
            let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell
            else { assertionFailure("Unable to load an instance of TKUIAutocompletionResultCell"); return fallback }

          cell.configure(with: searchItem)
          return cell
          
        case .component(let componentItem):
          guard let cell = self.viewModel.componentViewModels.compactMap({ $0.cell(for: componentItem, at: ip, in: tv) }).first else {
            assertionFailure("No component returned a cell for \(componentItem) at \(ip)."); return fallback
          }
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

    let searchInput = TKUIHomeViewModel.SearchInput(
      searchInProgress: searchInProgress.startWith(false).asDriver(onErrorJustReturn: false),
      searchText: searchTextPublisher,
      itemSelected: selectedItem(in: tableView, dataSource: dataSource),
      itemAccessoryTapped: cellAccessoryTappedPublisher.asSignal(onErrorSignalWith: .empty()),
      refresh: refreshPublisher.asSignal(onErrorSignalWith: .never()),
      biasMapRect: homeMapManager?.mapRect.startWith(.null) ?? .just(.null)
    )

    viewModel = TKUIHomeViewModel(
      componentViewModels: components,
      actionInput: actionTriggered.asSignal(onErrorSignalWith: .empty()),
      customizationInput: customizationTriggered.asSignal(onErrorSignalWith: .empty()),
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
      .emit(onNext: { [weak self] in self?.showQueryInput() })
      .disposed(by: disposeBag)

    // Map interaction
    
    homeMapManager?.nextFromMap
      .observe(on: MainScheduler.instance)
      .subscribe(onNext: { [weak self] in self?.actionTriggered.onNext($0) })
      .disposed(by: disposeBag)
  }
  
  open override func willAppear(animated: Bool) {
    // If the search text is empty when the card appears,
    // try loading autocompletion results.
    if let text = headerView.searchBar.text, text.isEmpty {
      searchTextPublisher.onNext(("", forced: true))
    }
    
    cardAppearancePublisher.onNext(true)
    
    // Remove any focused annotation, i.e., restoring any
    // hideen nearby annotations.
    focusedAnnotationPublisher.onNext(nil)
    
    // Remove any selection on the map
    homeMapManager?.onHomeCardAppearance(true)
    
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
}

// MARK: - Action on search result

extension TKUIHomeCard {
  
  private func prepareForNewCard(onCompletion handler: (() -> Void)? = nil) {
    headerView.searchBar.text = nil
    headerView.searchBar.resignFirstResponder()
    self.controller?.moveCard(to: initialPosition ?? .peaking, animated: false, onCompletion: handler)
  }
  
  private func handleNext(_ next: TKUIHomeViewModel.NextAction) {
    guard let cardController = controller else { return }
    
    func dismissSelection() {
      if let selected = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: selected, animated: true)
      }
    }
    
    switch next {
    case .present(let controller, let inNavigator):
      cardController.present(controller, inNavigator: inNavigator)
      dismissSelection()
      
    case .push(let card):
      prepareForNewCard {
        if cardController.topCard == self {
          cardController.push(card)
        } else {
          cardController.swap(for: card)
        }
      }
      
    case .showCustomizer(let items):
      guard #available(iOS 13.0, *) else { return assertionFailure() }
      showCustomizer(items: items)
      dismissSelection()

    case let .handleSelection(annotation, component):
      if let city = annotation as? TKRegion.City {
        clearSearchBar()
        
        controller?.moveCard(to: .collapsed, animated: true)
        
        homeMapManager?.zoom(to: city, animated: true)
        return
      }
      
      switch Self.config.selectionMode {
      case .selectOnMap:
        homeMapManager?.select(annotation)
      case let .callback(handler):
        if handler(annotation, component) {
          focusedAnnotationPublisher.onNext(annotation)
        }
      case .default:
        prepareForNewCard {
          let card: TGCard
          if let stop = annotation as? TKUIStopAnnotation {
            card = TKUITimetableCard(stops: [stop])
          } else {
            card = TKUIRoutingResultsCard(destination: annotation)
          }
          cardController.push(card)
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
  public func showQueryInput() {
    let mapRect = (homeMapManager as? TKUIMapManager)?.mapView?.visibleMapRect ?? .world
    let queryInputCard = TKUIRoutingQueryInputCard(biasMapRect: mapRect)
    queryInputCard.queryDelegate = self
    handleNext(.push(queryInputCard))
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
  
}

extension TKUIHomeCard: TKUIRoutingQueryInputCardDelegate {
  public func routingQueryInput(card: TKUIRoutingQueryInputCard, selectedOrigin origin: MKAnnotation, destination: MKAnnotation) {
    let request = TripRequest.insert(from: origin, to: destination, for: nil, timeType: .leaveASAP, into: TripKit.shared.tripKitContext)
    let routingResultsCard = TKUIRoutingResultsCard(request: request)
    
    // We don't want the query input card anymore as it's accessible from the results card
    controller?.swap(for: routingResultsCard, animated: true)
  }
}

// MARK: - Search bar

extension TKUIHomeCard: UISearchBarDelegate {
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextPublisher.onNext((searchText, forced: false))
  }
  
  public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
    headerView.directionsButton?.isHidden = true
    controller?.moveCard(to: .extended, animated: true)
    controller?.draggingCardEnabled = false
  }
  
  public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = false
  }
  
  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    clearSearchBar()
    headerView.directionsButton?.isHidden = false
    controller?.moveCard(to: initialPosition ?? .peaking, animated: true)
    controller?.draggingCardEnabled = true
  }
  
  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    headerView.directionsButton?.isHidden = false
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
    
    if let configuration = dataSource.sectionModels[section].headerConfiguration {
      header.label.text = configuration.title
      if let action = configuration.action {
        header.button.setTitle(action.title, for: .normal)
        header.button.rx.tap
          .subscribe(onNext: { [weak self] in self?.actionTriggered.onNext(action.handler()) })
          .disposed(by: header.disposeBag)
      }
        
    } else {
      header.label.text = nil
      header.button.setTitle(nil, for: .normal)
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
  
  @available(iOS 13.0, *)
  public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard let item = self.dataSource[indexPath].componentItem else { return nil }
    let configurations = self.viewModel.componentViewModels.compactMap { $0.contextMenuConfiguration(for: item, at: indexPath, in: tableView) }
    assert(configurations.count <= 1, "Two component view models handle the same item")
    return configurations.first
  }
  
}
