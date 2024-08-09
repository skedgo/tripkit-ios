//
//  TKUIRoutingResultsCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit

import TGCardViewController
import RxSwift
import RxCocoa

import TripKit

@available(*, unavailable, renamed: "TKUIRoutingResultsCard")
public typealias TKUIResultsCard = TKUIRoutingResultsCard

@available(*, unavailable, renamed: "TKUIRoutingResultsCardDelegate")
public typealias TKUIResultsCardDelegate = TKUIRoutingResultsCardDelegate


public protocol TKUIRoutingResultsCardDelegate: AnyObject {
  func resultsCard(_ card: TKUIRoutingResultsCard, requestsModePickerWithModes modes: [String], for region: TKRegion, sender: Any?)
}

/// An interactive card for displaying routing results, including updating from/to location, time and selected modes.
///
/// Can be used standalone or via ``TKUIRoutingResultsViewController``.
public class TKUIRoutingResultsCard: TKUITableCard {
  
  typealias RoutingModePicker = TKUIModePicker<TKRegion.RoutingMode>
  
  public static var config = Configuration.empty

  public weak var resultsDelegate: TKUIRoutingResultsCardDelegate?
  
  /// Set this callback to provide a custom handler for what should happen when a user selects a trip.
  ///
  /// If not provided, or you return `true` it will lead to the standard of pushing a ``TKUITripOverviewCard``.
  /// Returning `false` will do nothing, i.e., the callback should handle displaying the trip.
  public var onSelection: ((Trip) -> Bool)? = nil
  
  private let destination: MKAnnotation?
  private let origin: MKAnnotation?
  private var request: TripRequest? // Updated for debugging purposes
  private let editable: Bool

  private var viewModel: TKUIRoutingResultsViewModel!
  let disposeBag = DisposeBag()
  private var realTimeBag = DisposeBag()
  
  private var titleView: TKUIResultsTitleView?
  private let accessoryView = TKUIResultsAccessoryView.instantiate()
  private weak var modePicker: RoutingModePicker?
  private weak var errorView: UIView?
  private weak var tableView: UITableView?
  
  private let emptyHeader = UIView(frame: CGRect(x:0, y:0, width: 100, height: CGFloat.leastNonzeroMagnitude))
  
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TKUIRoutingResultsViewModel.Section>!
  
  private let showSearch = PublishSubject<Void>()
  private let changedTime = PublishSubject<TKUIRoutingResultsViewModel.RouteBuilder.Time>()
  private let changedModes = PublishSubject<[String]?>()
  private let changedSearch = PublishSubject<TKUIRoutingResultsViewModel.SearchResult>()
  private let tappedSectionButton = PublishSubject<TKUIRoutingResultsViewModel.ActionPayload>()
  
  /// Initializes and returns a newly allocated card showing results of routing from current
  /// location to a specified destination. The card will be placed at the specified initial
  /// position.
  ///
  /// If the initial card position is not provided to the initializer, the value specified in the
  /// global configuration will be used. The default position is `.peaking`.
  ///
  /// - Parameters:
  ///   - destination: The destination of the routing request.
  ///   - origin: Optionally, the origin lf the routing request. if not supplied, will use current location.
  ///   - zoomToDestination: Whether the map should zoom to `destination` immediately. (Defaults to `true` if not provided.)
  ///   - initialPosition: The initial position at which the card is placed when it's displayed.
  public init(destination: MKAnnotation, origin: MKAnnotation? = nil, zoomToDestination: Bool = true, initialPosition: TGCardPosition? = nil) {
    self.destination = destination
    self.origin = origin
    self.request = nil
    self.editable = true
    
    let mapManager = Self.config.mapManagerFactory(destination, zoomToDestination)
    
    let resultsTitle = TKUIResultsTitleView.newInstance()
    
    // We hide the "Transport" button if a list of transport modes
    // is provided in the configuration.
    if Self.config.limitToModes != nil {
      accessoryView.hideTransportButton()
    }
    
    resultsTitle.accessoryView = accessoryView
    self.titleView = resultsTitle
    
    super.init(
      title: .custom(resultsTitle, dismissButton: resultsTitle.dismissButton),
      style: .grouped,
      mapManager: mapManager,
      initialPosition: initialPosition ?? Self.config.initialCardPosition
    )
    
    didInit()
  }
  
  public init(request: TripRequest, editable: Bool = true) {
    self.destination = nil
    self.origin = nil
    self.request = request
    self.editable = editable
    
    let mapManager = Self.config.mapManagerFactory(request.toLocation, true)
    
    let resultsTitle = TKUIResultsTitleView.newInstance()
    
    // We hide the "Transport" button if a list of transport modes
    // is provided in the configuration.
    if Self.config.limitToModes != nil {
      accessoryView.hideTransportButton()
    }
    
    resultsTitle.accessoryView = accessoryView
    self.titleView = resultsTitle
    
    super.init(
      title: .custom(resultsTitle, dismissButton: resultsTitle.dismissButton),
      style: .grouped,
      mapManager: mapManager,
      initialPosition: .extended // show fully as we'll have routes shortly
    )
    
    didInit()
  }
  
  private func didInit() {
    // Don't de-select as we use a custom style and want to keep highlighting
    // the best trip (as it's also highlighted on the map still).
    self.deselectOnAppear = false
    
    switch self.title {
    case .custom(_, let dismissButton):
      let styledCloseImage = TGCard.closeButtonImage(style: style)
      dismissButton?.setImage(styledCloseImage, for: .normal)
      dismissButton?.setTitle(nil, for: .normal)
    default: return
    }
    
    if let knownMapManager = mapManager as? TKUIMapManager {
      knownMapManager.attributionDisplayer = { [weak self] sources, sender in
        let displayer = TKUIAttributionTableViewController(attributions: sources)
        self?.controller?.present(displayer, inNavigator: true, preferredStyle: .popover, sender: sender)
      }
    }
  }
  
  public override var preferredView: UIView? {
    // See if we have an overlay; if so, don't say we have a preferred view
    // to not read out something from VoiceOver that has an overlay on top.
    return findOverlay() != nil ? nil : titleView?.preferredView
  }
  
  override public func didBuild(tableView: UITableView, cardView: TGCardView) {
    super.didBuild(tableView: tableView, cardView: cardView)
    
    guard let mapManager = mapManager as? TKUIRoutingResultsMapManagerType else { preconditionFailure() }
    
    self.tableView = tableView
    
    // Build the view model
    
    let searchTriggers = Observable.merge([
        showSearch,
        titleView?.locationTapped.asObservable()
      ].compactMap { $0 }
    )
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIRoutingResultsViewModel.Section>(
      configureCell: { [unowned self] in
        self.configureCell(dataSource: $0, tableView: $1, indexPath: $2, item: $3)
      }
    )
    self.dataSource = dataSource
    
    let inputs: TKUIRoutingResultsViewModel.UIInput = (
      selected: selectedItem(in: tableView, dataSource: dataSource),
      tappedSectionButton: tappedSectionButton.asAssertingSignal(),
      tappedSearch: searchTriggers.asAssertingSignal(),
      tappedDate: accessoryView.timeButton.rx.tap.asSignal(),
      tappedShowModes: accessoryView.transportButton.rx.tap.asSignal(),
      tappedShowModeOptions: .empty(),
      changedDate: changedTime.asAssertingSignal(),
      changedModes: changedModes.asAssertingSignal(),
      changedSortOrder: .empty(),
      changedSearch: changedSearch.asAssertingSignal()
    )
    
    let mapInput: TKUIRoutingResultsViewModel.MapInput = (
      tappedMapRoute: mapManager.selectedMapRoute,
      droppedPin: mapManager.droppedPin,
      tappedPin: (mapManager as? TKUIRoutingResultsMapManager)?.tappedPin ?? .empty()
    )
    
    let viewModel: TKUIRoutingResultsViewModel
    if let destination = self.destination {
      viewModel = TKUIRoutingResultsViewModel(destination: destination, origin: origin, limitTo: Self.config.limitToModes, inputs: inputs, mapInput: mapInput)
    } else if let request = self.request {
      viewModel = TKUIRoutingResultsViewModel(request: request, editable: editable, limitTo: Self.config.limitToModes, inputs: inputs, mapInput: mapInput)
    } else {
      preconditionFailure()
    }
    self.viewModel = viewModel
    (mapManager as? TKUIRoutingResultsMapManager)?.viewModel = viewModel
    
    // Table view configuration
    
    tableView.register(TKUITripCell.nib, forCellReuseIdentifier: TKUITripCell.reuseIdentifier)
    tableView.register(TKUIProgressCell.nib, forCellReuseIdentifier: TKUIProgressCell.reuseIdentifier)
    tableView.register(TKUIResultsSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TKUIResultsSectionFooterView.reuseIdentifier)
    tableView.register(TKUIResultsSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TKUIResultsSectionHeaderView.reuseIdentifier)
    TKUIRoutingResultsCard.config.customItemProvider?.registerCell(with: tableView)

    tableView.backgroundColor = .tkBackgroundGrouped
    tableView.separatorStyle = .none
    tableView.tableFooterView = UIView()
    tableView.tableHeaderView = emptyHeader

    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    tableView.dataSource = nil
    
    // Set this immediately before we get sections, to make sure we
    // size all the footers and headers correctly
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)

    // Bind outputs
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.sections
      .drive(onNext: { [weak self] in
        self?.updateVisibleSectionBadges(sections: $0, tableView: tableView)
      })
    .disposed(by: disposeBag)

    viewModel.selectedItem
      .drive(onNext: { [weak self] in
        guard let indexPath = self?.dataSource.indexPath(of: $0) else { return }
        if let visible = tableView.indexPathsForVisibleRows, visible.contains(indexPath) { return }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
      })
      .disposed(by: disposeBag)

    viewModel.originDestination
      .drive(onNext: { [weak self] input in
        self?.titleView?.configure(destination: input.destination , origin: input.origin)
      })
      .disposed(by: disposeBag)

    viewModel.timeTitle
      .drive(onNext: { [weak self] in
        self?.accessoryView.setTimeLabel($0.text, highlight: $0.highlight)
      })
      .disposed(by: disposeBag)
    
    viewModel.availableModes
      .drive(onNext: { [weak self] in
        self?.updateModePicker($0, in: tableView)
        // When available modes change, e.g., from toggling the Transport button on and off,
        // an error view may be sitting above the table view, covering the mode picker. This
        // repositions it so the mode picker is always visible. See this ticket for details
        // https://redmine.buzzhives.com/issues/15305
        if let errorView = self?.errorView {
          self?.offset(errorView, by: tableView.tableHeaderView?.frame.height ?? 0)
        }
      })
      .disposed(by: disposeBag)
    
    // Monitor progress (note: without this, we won't fetch!)
    viewModel.fetchProgress
      .drive(onNext: { [weak self] progress in
        guard let self = self, let controller = self.controller else { return }
        switch progress {
        case .started:
          if let errorView = self.errorView {
            self.clear(errorView)
          }
          self.showTripGoAttribution(in: tableView)

        case .finished:
          if let request = self.request {
            TKUIEventCallback.handler(.routesLoaded(request, controller: controller))
          }
          self.showTripGoAttribution(in: tableView)
          
        default:
          break
        }
      })
      .disposed(by: disposeBag)
    
    viewModel.requestIsMutable
      .drive(onNext: { [weak self] in self?.allowChangingQuery = $0 })
      .disposed(by: disposeBag)
    
    viewModel.request
      .drive(onNext: TKUICustomization.shared.feedbackActiveItemHandler)
      .disposed(by: disposeBag)
    
    viewModel.request
      .drive(onNext: { [weak self] in self?.request = $0 })
      .disposed(by: disposeBag)

    viewModel.error
      .asObservable()
      .withLatestFrom(viewModel.request.startOptional()) { ($0, $1) }
      .subscribe(onNext: { [weak self] in
        self?.errorView = self?.show($0, for: $1, cardView: cardView, tableView: tableView)
      })
      .disposed(by: disposeBag)
    
    viewModel.sections
      .map { $0.first?.items.isEmpty }
      .distinctUntilChanged()
      .filter { $0 == false } // we got results!
      .drive(onNext: { [weak self] _ in
        if let errorView = self?.errorView {
          self?.clear(errorView)
        }
      })
      .disposed(by: disposeBag)
    
    viewModel.next
      .emit(onNext: { [weak self] in self?.navigate(to: $0) })
      .disposed(by: disposeBag)
  }
  
  public override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)

    if let controller {
      accessoryView.update(preferredContentSizeCategory: controller.traitCollection.preferredContentSizeCategory)
    }
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))

    viewModel.realTimeUpdate
      .drive()
      .disposed(by: realTimeBag)
  }
  
  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    if let controller {
      accessoryView.update(preferredContentSizeCategory: controller.traitCollection.preferredContentSizeCategory)
    }
  }
  
  public override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    
    realTimeBag = DisposeBag()
  }
  
  // MARK: - Keyboard shortcuts
  
  public override var keyCommands: [UIKeyCommand]? {
    var commands = super.keyCommands ?? []
    
    // ⌘+F: Search (show query input)
    commands.append(UIKeyCommand(title: Loc.Search, image: nil, action: #selector(triggerSearch), input: "F", modifierFlags: [.command]))
    
    return commands
  }
  
  override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    if action == #selector(TKUIDebugActionHandler.debugActionCopyPrimaryRequest) {
      return request != nil
    } else {
      return super.canPerformAction(action, withSender: sender)
    }
  }
  
  @objc func triggerSearch() {
    showSearch.onNext(())
  }
  
  @objc
  public func debugActionCopyPrimaryRequest(_ sender: AnyObject?) {
    guard let request = request else { return }
   
    // Note: Only gets modes if picker is visible
    let modes = modePicker?.pickedModes.map { $0.identifier }
    
    let url = TKRouter.routingRequestURL(for: request, modes: modes.flatMap(Set.init))
    UIPasteboard.general.string = url
  }
  
  // MARK: - Disabling interaction

  var allowChangingQuery: Bool = true {
    didSet {
      accessoryView.timeButton.isEnabled = allowChangingQuery
      
      accessoryView.transportButton.isEnabled = true // we disable the mode picker instead
      modePicker?.isEnabled = allowChangingQuery
      
      titleView?.enableTappingLocation = allowChangingQuery
    }
  }
}



// MARK: - Cell configuration

extension TKUIRoutingResultsCard {
  
  func configureCell(dataSource: TableViewSectionedDataSource<TKUIRoutingResultsViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUIRoutingResultsViewModel.Item) -> UITableViewCell {
    let preferredContentSizeCategory = controller?.traitCollection.preferredContentSizeCategory ?? .unspecified
    
    switch item {
    case .progress:
      let progressCell = tableView.dequeueReusableCell(withIdentifier: TKUIProgressCell.reuseIdentifier, for: indexPath) as! TKUIProgressCell
      progressCell.contentView.backgroundColor = .tkBackgroundSecondary // this blends in the background beneath tiles
      return progressCell
      
    case .trip(let trip):
      let tripCell = tableView.dequeueReusableCell(withIdentifier: TKUITripCell.reuseIdentifier, for: indexPath) as! TKUITripCell
      tripCell.configure(trip, preferredContentSizeCategory: preferredContentSizeCategory)
      tripCell.separatorView.isHidden = !(dataSource.sectionModels[indexPath.section].items.count > 1)
      #if targetEnvironment(macCatalyst)
      tripCell.accessoryType = .disclosureIndicator
      #endif
      tripCell.accessibilityTraits = .button
      
      tripCell.actionButton.rx.tap
        .subscribe(onNext: { [weak self] in
          guard
            let self,
            let primaryAction = TKUITripOverviewCard.config.tripActionsFactory?(trip).first(where: { $0.priority >= TKUITripOverviewCard.DefaultActionPriority.book.rawValue }),
            let view = self.controller?.view else { return }
          let _ = primaryAction.handler(primaryAction, self, trip, view)
        })
        .disposed(by: tripCell.disposeBag)
      
      return tripCell
    
    case .customItem(let item):
      guard let provider = TKUIRoutingResultsCard.config.customItemProvider else {
        assertionFailure(); return UITableViewCell()
      }
      return provider.cell(for: item, tableView: tableView, indexPath: indexPath)
    }
  }
  
}

extension TKUITripCell {
  public func configure(_ trip: Trip, allowFading: Bool = true, isArriveBefore: Bool? = nil, preferredContentSizeCategory: UIContentSizeCategory) {
    configure(.init(trip, allowFading: allowFading, isArriveBefore: isArriveBefore), preferredContentSizeCategory: preferredContentSizeCategory)
  }
}

extension TKMetricClassifier.Classification {
  
  fileprivate var footerContent: (UIImage?, String, UIColor) {
    return (icon, text, color)
  }
  
}

extension TKUIRoutingResultsCard {
  private func updateVisibleSectionBadges(sections: [TKUIRoutingResultsViewModel.Section], tableView: UITableView) {
    guard let visible = tableView.indexPathsForVisibleRows else { return }
    let indices = visible.reduce(into: Set<Int>()) { $0.insert($1.section) }
    for section in indices {
      guard let header = tableView.headerView(forSection: section) as? TKUIResultsSectionHeaderView else { continue }
      header.badge = sections[section].badge?.footerContent
    }
  }
}

extension TKUIRoutingResultsCard: UITableViewDelegate {

  typealias FooterContent = TKUIResultsSectionFooterView.Content
  
  private func footer(for sectionIndex: Int) -> FooterContent? {
    // progress cell does not need a footer
    let items = dataSource.sectionModels[sectionIndex].items
    guard let firstTrip = items.first?.trip else {
      return nil
    }

    let section = dataSource.sectionModels[sectionIndex]
    var content = FooterContent(action: section.action)
    if items.count == 1, let info = firstTrip.availabilityInfo {
      content.cost = info
      content.isWarning = true
    } else if controller?.traitCollection.preferredContentSizeCategory.isAccessibilityCategory != true {
      content.cost = TKUITripCell.Formatter.costString(costs: section.costs)
      content.costAccessibility = TKUITripCell.Formatter.costAccessibilityLabel(costs: section.costs)
    }
    return content
  }
  
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TKUIResultsSectionFooterView.reuseIdentifier) as? TKUIResultsSectionFooterView else {
      assertionFailure()
      return nil
    }
   
    guard let content = footer(for: section) else { return nil }
    footerView.configure(content) { [unowned tappedSectionButton] action in
      tappedSectionButton.onNext(action.payload)
    }
    
    return footerView
  }
  
  public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
    let content = footer(for: section)
    return TKUIResultsSectionFooterView.height(for: content, maxWidth: tableView.frame.width)
  }
  
  public func tableView(_ tableView: UITableView, estimatedHeightForFooterInSection section: Int) -> CGFloat {
    let content = footer(for: section)
    return TKUIResultsSectionFooterView.height(for: content, maxWidth: tableView.frame.width)
  }
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    let section = dataSource.sectionModels[section]
    guard let content = section.badge?.footerContent else {
      return UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 16))
    }

    guard let headerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TKUIResultsSectionHeaderView.reuseIdentifier) as? TKUIResultsSectionHeaderView else {
      assertionFailure()
      return nil
    }

    headerView.badge = content
    return headerView
  }
  
  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    return getHeaderHeight(from: section)
  }
  
  public func tableView(_ tableView: UITableView, estimatedHeightForHeaderInSection section: Int) -> CGFloat {
    return getHeaderHeight(from: section)
  }
    
  private func getHeaderHeight(from section: Int) -> CGFloat {
    let section = dataSource.sectionModels[section]
    if section.badge?.footerContent == nil {
      return 16
    } else {
      let sizingHeader = TKUIResultsSectionHeaderView.forSizing
      let size = sizingHeader.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
      return size.height
    }
  }
  
}

extension TKUIRoutingResultsCard {
  public func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
    guard
      let trip = dataSource[indexPath].trip,
      let factory = TKUITripOverviewCard.config.tripActionsFactory
      else { return nil }
    
    let actions = factory(trip)
    guard !actions.isEmpty else { return nil }
    
    guard let cell = tableView.cellForRow(at: indexPath) else { assertionFailure(); return nil }
    
    let menu: ([UIMenuElement]) -> UIMenu? = { [unowned self] existing in
      let items: [UIAction] = actions.map { [unowned self] action in
        UIAction(title: action.title, image: action.icon) { [unowned self] _ in
          _ = action.handler(action, self, trip, cell)
        }
      }
      return UIMenu(title: "", image: nil, identifier: nil, options: [], children: items)
    }
    
    return UIContextMenuConfiguration(identifier: nil, previewProvider: nil, actionProvider: menu)
  }
}

// MARK: - Mode picker

private extension TKUIRoutingResultsCard {
  
  func updateModePicker(_ modes: TKUIRoutingResultsViewModel.AvailableModes, in tableView: UITableView) {
    accessoryView.setTransport(isOpen: !modes.available.isEmpty)
    
    guard !modes.available.isEmpty else {
      tableView.tableHeaderView = emptyHeader
      self.modePicker = nil
      return
    }
    
    // Make sure mode picker is visible
    if let controller = controller, controller.cardPosition == .collapsed {
      controller.moveCard(to: .extended, animated: true)
    }
    
    let modePicker: RoutingModePicker
    let scrollToPicker: Bool
    
    if let existing = self.modePicker {
      modePicker = existing
      scrollToPicker = false
    } else {
      modePicker = self.buildModePicker()
      self.modePicker = modePicker
      scrollToPicker = true
    }

    modePicker.isEnabled = allowChangingQuery
    modePicker.frame.size.width = tableView.frame.width
    modePicker.configure(all: modes.available, updateAll: true, currentlyEnabled: modes.isEnabled)
    
    let pickerHeight = modePicker.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: pickerHeight))
    header.addSubview(modePicker)
    
    modePicker.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      modePicker.topAnchor.constraint(equalTo: header.topAnchor),
      modePicker.bottomAnchor.constraint(equalTo: header.bottomAnchor),
      modePicker.leadingAnchor.constraint(equalTo: header.leadingAnchor),
      modePicker.trailingAnchor.constraint(equalTo: header.trailingAnchor)
    ])
    
    tableView.tableHeaderView = header
    
    if scrollToPicker {
      tableView.scrollRectToVisible(header.frame, animated: true)
    }
  }
  
  func buildModePicker() -> RoutingModePicker {
    let modePicker = RoutingModePicker()
    modePicker.containerView = controller?.view
    modePicker.backgroundColor = .tkBackgroundGrouped
    
    modePicker.rx_pickedModes
      .emit(onNext: { [weak self] in
        self?.changedModes.onNext($0.map { $0.identifier })
      })
      .disposed(by: disposeBag)
    
    return modePicker
  }
  
  func offset(_ errorView: UIView, by topPadding: CGFloat) {
    errorView.frame.origin.y = topPadding
  }
  
}

// MARK: - Navigation

private extension TKUIRoutingResultsCard {
  
  func navigate(to next: TKUIRoutingResultsViewModel.Next) {
    guard let controller else { return }
    
    switch next {
    case .showTrip(let trip):
      if let onSelection = onSelection, !onSelection(trip) {
        break // caller handles presenting it
      } else {
        controller.push(TKUITripsPageCard(highlighting: trip))
      }
      
    case .showCustomItem(let item):
      TKUIRoutingResultsCard.config.customItemProvider?.show(item, presenter: controller)
      if let tableView, let selection = tableView.indexPathForSelectedRow {
        tableView.deselectRow(at: selection, animated: true)
      }

    case let .showSearch(origin, destination, mode):
      showSearch(origin: origin, destination: destination, startMode: mode)
      
    case .presentModeConfigurator(let modes, let region):      
      showTransportOptions(modes: modes, for: region)
      
    case .presentDatePicker(let time, let timeZone):
      showTimePicker(time: time, timeZone: timeZone)
      
    case .trigger(let action, let group):
      _ = action.handler(action, self, group, controller.view)
      
    case .showLocation(let annotation, _):
      guard let handler = TKUICustomization.shared.locationInfoTapHandler else {
        return assertionFailure("Shouldn't show that disclosure icon without a tap handler")
      }
      switch handler(.init(annotation: annotation, routeButton: .notAllowed)) {
      case .push(let card):
        controller.push(card)
      }
    }
  }
  
}

// MARK: - Search places

private extension TKUIRoutingResultsCard {
  
  func showSearch(origin: MKAnnotation?, destination: MKAnnotation?, startMode: TKUIRoutingResultsViewModel.SearchMode?) {
    let biasMapRect = (mapManager as? TGMapManager)?.mapView?.visibleMapRect ?? .null
    
    let card = TKUIRoutingQueryInputCard(origin: origin, destination: destination, biasMapRect: biasMapRect)
    card.startMode = startMode
    card.queryDelegate = self
    
    controller?.push(card)
  }
  
}

extension TKUIRoutingResultsCard: TKUIRoutingQueryInputCardDelegate {
  public func routingQueryInput(card: TKUIRoutingQueryInputCard, selectedOrigin origin: MKAnnotation, destination: MKAnnotation) {
    
    changedSearch.onNext(TKUIRoutingResultsViewModel.SearchResult(mode: .origin, location: origin))
    changedSearch.onNext(TKUIRoutingResultsViewModel.SearchResult(mode: .destination, location: destination))
    
    controller?.pop()
  }
}


// MARK: - Picking times

private extension TKUIRoutingResultsCard {
  
  func findOverlay() -> UIView? {
    if let presentee = controller?.presentedViewController {
      return presentee.view
    } else if let sheet = controller?.view.subviews.first(where: { $0 is TKUISheet }) {
      return sheet
    } else {
      return nil
    }
  }
  
  func showTimePicker(time: TKUIRoutingResultsViewModel.RouteBuilder.Time, timeZone: TimeZone) {
    guard let controller = controller else {
      preconditionFailure("Shouldn't be able to show time picker!")
    }
    
    let sender: UIButton = accessoryView.timeButton
    
    let picker = TKUITimePickerSheet(time: time.date, timeType: time.timeType, timeZone: timeZone, config: Self.config.timePickerConfig)
    picker.selectAction = { [weak self] timeType, date in
      self?.changedTime.onNext(TKUIRoutingResultsViewModel.RouteBuilder.Time(timeType: timeType, date: date))
    }
    
    if controller.traitCollection.horizontalSizeClass == .regular {
      picker.delegate = self
      
      let pickerController = TKUISheetViewController(sheet: picker)
      pickerController.modalPresentationStyle = .popover
      let presenter = pickerController.popoverPresentationController
      presenter?.sourceView = controller.view
      presenter?.sourceRect = controller.view.convert(sender.bounds, from: sender)
      controller.present(pickerController, animated: true)
      
    } else {
      picker.showWithOverlay(in: controller.view)
    }
  }
  
}

extension TKUIRoutingResultsCard: TKUITimePickerSheetDelegate {
  
  public func timePicker(_ picker: TKUITimePickerSheet, pickedDate: Date, for type: TKTimeType) {
    // We use the select action + dismissal instead
  }
  
  public func timePickerRequestsResign(_ pickerSheet: TKUITimePickerSheet) {
    func onDismissal() {
      let selection = TKUIRoutingResultsViewModel.RouteBuilder.Time(timeType: pickerSheet.selectedTimeType, date: pickerSheet.selectedDate)
      self.changedTime.onNext(selection)
    }
    
    if controller?.presentedViewController != nil {
      controller?.dismiss(animated: true, completion: onDismissal)
    } else {
      // e.g., on iPad where it's displayed as a popover
      onDismissal()
    }
  }
  
}

// MARK: - Picking transport modes

extension TKUIRoutingResultsCard {
  
  private func showTransportOptions(modes: [String], for region: TKRegion) {
    resultsDelegate?.resultsCard(self, requestsModePickerWithModes: modes, for: region, sender: accessoryView.transportButton)
  }
  
  public func refreshForUpdatedModes() {
    changedModes.onNext(nil)
  }
  
}

// MARK: - TripGo attribution

extension TKUIRoutingResultsCard {
  
  func showTripGoAttribution(in tableView: UITableView) {
    guard TKConfig.shared.attributionRequired else { return }
    let logo = TKImage(named: "logo-tripgo", in: .tripKitUI, compatibleWith: nil)
    let footer = TKUIAttributionView.newView(title: "TripGo", icon: logo, iconURL: nil, url: URL(string: "https://www.skedgo.com"), alignment: .leading, wording: .poweredBy)
    footer.frame.size.width = tableView.frame.width
    footer.frame.size.height = footer.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    tableView.tableFooterView = footer
  }
  
}
