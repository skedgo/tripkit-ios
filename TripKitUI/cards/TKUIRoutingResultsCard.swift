//
//  TKUIRoutingResultsCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift
import RxCocoa
import RxDataSources

#if TK_NO_MODULE
#else
  import TripKit
#endif

@available(*, unavailable, renamed: "TKUIRoutingResultsCard")
public typealias TKUIResultsCard = TKUIRoutingResultsCard

@available(*, unavailable, renamed: "TKUIRoutingResultsCardDelegate")
public typealias TKUIResultsCardDelegate = TKUIRoutingResultsCardDelegate


public protocol TKUIRoutingResultsCardDelegate: class {
  func resultsCard(_ card: TKUIRoutingResultsCard, requestsModePickerWithModes modes: [String], for region: TKRegion, sender: Any?)
}

public class TKUIRoutingResultsCard: TGTableCard {
  
  typealias RoutingModePicker = TKUIModePicker<TKRegion.RoutingMode>
  
  public static var config = Configuration.empty

  public weak var resultsDelegate: TKUIRoutingResultsCardDelegate?
  
  private let destination: MKAnnotation?
  private var request: TripRequest? // also for saving

  private var viewModel: TKUIRoutingResultsViewModel!
  let disposeBag = DisposeBag()
  private var realTimeBag = DisposeBag()
  
  private var titleView: TKUIResultsTitleView?
  private let accessoryView = TKUIResultsAccessoryView.instantiate()
  private weak var modePicker: RoutingModePicker?
  
  let emptyHeader = UIView(frame: CGRect(x:0, y:0, width: 100, height: CGFloat.leastNonzeroMagnitude))
  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIRoutingResultsViewModel.Section>(
    configureCell: TKUIRoutingResultsCard.cell
  )
  
  private var searchSpecifier: TKUILocationSearchSpecifier?
  
  private let changedTime = PublishSubject<TKUIRoutingResultsViewModel.RouteBuilder.Time>()
  private let changedModes = PublishSubject<[String]?>()
  private let changedOrigin = PublishSubject<MKAnnotation>()
  private let changedDestination = PublishSubject<MKAnnotation>()
  private let tappedToggleButton = PublishSubject<TripGroup?>()

  public init(destination: MKAnnotation) {
    self.destination = destination
    self.request = nil
    
    let mapManager = TKUIRoutingResultsCard.config.mapManagerFactory(destination)
    
    let resultsTitle = TKUIResultsTitleView.newInstance()
    resultsTitle.accessoryView = accessoryView
    self.titleView = resultsTitle
    
    super.init(
      title: .custom(resultsTitle, dismissButton: resultsTitle.dismissButton),
      style: .grouped,
      mapManager: mapManager,
      initialPosition: nil
    )

    didInit()
  }
  
  public init(request: TripRequest) {
    self.destination = nil
    self.request = request
    
    let mapManager = TKUIRoutingResultsCard.config.mapManagerFactory(request.toLocation)
    
    let resultsTitle = TKUIResultsTitleView.newInstance()
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
  
  public required convenience init?(coder: NSCoder) {
    guard
      let data = coder.decodeObject(forKey: "viewModel") as? Data,
      let request = TKUIRoutingResultsViewModel.restore(from: data)
      else { return nil }
    
    self.init(request: request)
  }
  
  private func didInit() {
    // Don't de-select as we use a custom style and want to keep highlighting
    // the best trip (as it's also highlighted on the map still).
    self.deselectOnAppear = false
  }
  
  public override func encode(with aCoder: NSCoder) {
    aCoder.encode(TKUIRoutingResultsViewModel.save(request: request), forKey: "viewModel")
  }
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard
      let tableView = (cardView as? TGScrollCardView)?.tableView,
      let mapManager = mapManager as? TKUIRoutingResultsMapManagerType
      else { preconditionFailure() }
    
    // Build the view model
    
    let inputs: TKUIRoutingResultsViewModel.UIInput = (
      selected: tableView.rx.modelSelected(TKUIRoutingResultsViewModel.Item.self).asSignal(),
      tappedToggleButton: tappedToggleButton.asSignal(onErrorSignalWith: .empty()),
      tappedDate: accessoryView.timeButton.rx.tap.asSignal(),
      tappedShowModes: accessoryView.transportButton.rx.tap.asSignal(),
      tappedShowModeOptions: .empty(),
      changedDate: changedTime.asSignal(onErrorSignalWith: .empty()),
      changedModes: changedModes.asSignal(onErrorSignalWith: .empty()),
      changedSortOrder: .empty(),
      changedOrigin: changedOrigin.asSignal(onErrorSignalWith: .empty()),
      changedDestination: changedDestination.asSignal(onErrorSignalWith: .empty())
    )
    
    let mapInput: TKUIRoutingResultsViewModel.MapInput = (
      tappedMapRoute: mapManager.selectedMapRoute,
      droppedPin: mapManager.droppedPin
    )
    
    let viewModel: TKUIRoutingResultsViewModel
    if let destination = self.destination {
      viewModel = TKUIRoutingResultsViewModel(destination: destination, inputs: inputs, mapInput: mapInput)
    } else if let request = self.request {
      viewModel = TKUIRoutingResultsViewModel(request: request, inputs: inputs, mapInput: mapInput)
    } else {
      preconditionFailure()
    }
    self.viewModel = viewModel
    mapManager.viewModel = viewModel
    
    // Table view configuration
    
    tableView.register(TKUITripCell.nib, forCellReuseIdentifier: TKUITripCell.reuseIdentifier)
    tableView.register(TKUIResultsSectionFooterView.self, forHeaderFooterViewReuseIdentifier: TKUIResultsSectionFooterView.reuseIdentifier)
    tableView.register(TKUIResultsSectionHeaderView.self, forHeaderFooterViewReuseIdentifier: TKUIResultsSectionHeaderView.reuseIdentifier)

    tableView.backgroundColor = .tkBackgroundGrouped
    tableView.separatorStyle = .none
    tableView.tableFooterView = UIView()
    tableView.tableHeaderView = emptyHeader

    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    tableView.dataSource = nil
    
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

    viewModel.titles
      .drive(onNext: { [weak self] input in
        self?.titleView?.configure(destination: input.title , origin: input.subtitle)
      })
      .disposed(by: disposeBag)

    viewModel.timeTitle
      .drive(accessoryView.timeButton.rx.title())
      .disposed(by: disposeBag)
    
    viewModel.availableModes
      .drive(onNext: { [weak self] in self?.updateModePicker($0, in: tableView) })
      .disposed(by: disposeBag)
    
    // Monitor progress (note: without this, we won't fetch!)
    viewModel.fetchProgress
      .drive()
      .disposed(by: disposeBag)
    
    viewModel.request
      .drive(onNext: TKUICustomization.shared.feedbackActiveItemHandler)
      .disposed(by: disposeBag)
    
    viewModel.request
      .drive(onNext: { [weak self] in self?.request = $0 })
      .disposed(by: disposeBag)

    viewModel.error
      .asObservable()
      .withLatestFrom(viewModel.request) { ($0, $1) }
      .subscribe(onNext: { [weak self] in
        self?.show($0, for: $1, cardView: cardView, tableView: tableView)
      })
      .disposed(by: disposeBag)
    
    viewModel.sections
      .map { $0.first?.items.isEmpty }
      .distinctUntilChanged()
      .filter { $0 == false } // we got results!
      .drive(onNext: { [weak self] _ in self?.clearError(in: cardView) })
      .disposed(by: disposeBag)
    
    viewModel.next
      .emit(onNext: { [weak self] in self?.navigate(to: $0) })
      .disposed(by: disposeBag)
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
    
    // Search places
    
    titleView?.locationTapped
    .emit(onNext: { [weak self] in self?.showSearch(for: $0) })
    .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    viewModel.realTimeUpdate
      .drive()
      .disposed(by: realTimeBag)
  }
  
  public override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    
    realTimeBag = DisposeBag()
  }
  
}

// MARK: - Cell configuration

extension TKUIRoutingResultsCard {
  
  static func cell(dataSource: RxDataSources.TableViewSectionedDataSource<TKUIRoutingResultsViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUIRoutingResultsViewModel.Item) -> UITableViewCell {
    
    let showSeparator = dataSource.sectionModels[indexPath.section].items.count > 1
    
    let tripCell = tableView.dequeueReusableCell(withIdentifier: TKUITripCell.reuseIdentifier, for: indexPath) as! TKUITripCell
    tripCell.configure(TKUITripCell.Model(item.trip))
    tripCell.separatorView.isHidden = !showSeparator
    
    return tripCell
  }
  
}

extension TKUITripCell.Model {

  init(_ trip: Trip) {
    self.init(
      departure: trip.departureTime, arrival: trip.arrivalTime,
      departureTimeZone: trip.departureTimeZone, arrivalTimeZone: trip.arrivalTimeZone ?? trip.departureTimeZone,
      focusOnDuration: !trip.departureTimeIsFixed, isArriveBefore: trip.isArriveBefore,
      showFaded: trip.showFaded,
      segments: trip.segments(with: .inSummary)
    )
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
      if let badge = sections[section].badge, let header = tableView.headerView(forSection: section) as? TKUIResultsSectionHeaderView {
        header.badge = badge.footerContent
      }
    }
  }
}

extension TKUIRoutingResultsCard: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TKUIResultsSectionFooterView.reuseIdentifier) as? TKUIResultsSectionFooterView else {
      assertionFailure()
      return nil
    }

    let formatter = TKUITripCell.Formatter()
    formatter.costColor = footerView.costLabel.textColor

    let section = dataSource.sectionModels[section]
    footerView.attributedCost = formatter.costString(costs: section.costs)
    
    if let buttonContent = section.toggleButton {
      footerView.button.isHidden = false
      footerView.button.setTitle(buttonContent.title, for: .normal)
      footerView.button.rx.tap
        .subscribe(onNext: { [unowned tappedToggleButton] in
          tappedToggleButton.onNext(buttonContent.payload)
        })
        .disposed(by: footerView.disposeBag)

    } else {
      footerView.button.isHidden = true
    }
    
    return footerView
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
  
}

// MARK: - Mode picker

private extension TKUIRoutingResultsCard {
  
  func updateModePicker(_ modes: TKUIRoutingResultsViewModel.AvailableModes, in tableView: UITableView) {
    guard !modes.available.isEmpty else {
      tableView.tableHeaderView = emptyHeader
      self.modePicker = nil
      return
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

    modePicker.backgroundColor = .tkBackgroundGrouped
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
    modePicker.backgroundColor = .tkBackground
    
    modePicker.rx_pickedModes
      .emit(onNext: { [weak self] in
        self?.changedModes.onNext($0.map { $0.identifier })
      })
      .disposed(by: disposeBag)
    
    return modePicker
  }
  
}

// MARK: - Navigation

private extension TKUIRoutingResultsCard {
  
  func navigate(to next: TKUIRoutingResultsViewModel.Next) {
    switch next {
    case .showTrip(let trip):
      controller?.push(TKUITripsPageCard(highlighting: trip))
      
    case .presentModeConfigurator(let modes, let region):      
      showTransportOptions(modes: modes, for: region)
      
    case .presentDatePicker(let time, let timeZone):
      showTimePicker(time: time, timeZone: timeZone)
    }
  }
  
}

// MARK: - Search places

private extension TKUIRoutingResultsCard {
  
  func showSearch(for specifier: TKUILocationSearchSpecifier) {
    self.searchSpecifier = specifier
    
    let resultsController = TKUIAutocompletionViewController(providers: TKUIRoutingResultsCard.config.autocompletionDataProviders)
    resultsController.delegate = self
    resultsController.biasMapRect = (mapManager as? TGMapManager)?.mapView?.visibleMapRect ?? .null
    
    if #available(iOS 11.0, *) {
      // Fix for bad padding between search bar and first row
      // Kudos to https://stackoverflow.com/questions/40435806/extra-space-on-top-of-uisearchcontrollers-uitableview
      resultsController.tableView.contentInsetAdjustmentBehavior = .never
    }
    
    let searchController = UISearchController(searchResultsController: resultsController)
    searchController.searchResultsUpdater = resultsController
    searchController.searchBar.placeholder = (specifier == .origin) ? Loc.StartLocation : Loc.EndLocation
    
    TKStyleManager.style(searchController.searchBar, includingBackground: false) {
      $0.backgroundColor = .tkBackground
      $0.tintColor = .tkLabelPrimary
      $0.textColor = .tkLabelPrimary
    }
    
    controller?.present(searchController, animated: true)
  }
  
}

extension TKUIRoutingResultsCard: TKUIAutocompletionViewControllerDelegate {
  
  public func autocompleter(_ controller: TKUIAutocompletionViewController, didSelect annotation: MKAnnotation) {
    self.controller?.dismiss(animated: true, completion: { [weak self] in
      guard let self = self, let specifier = self.searchSpecifier else {
        assertionFailure()
        return
      }
      
      switch specifier {
      case .origin:
        self.changedOrigin.onNext(annotation)
      case .destination:
        self.changedDestination.onNext(annotation)
      }
      
      self.searchSpecifier = nil
    })
  }
  
  public func autocompleter(_ controller: TKUIAutocompletionViewController, didSelectAccessoryFor annotation: MKAnnotation) {
    self.controller?.dismiss(animated: true, completion: {
      //
    })
  }
  
}

// MARK: - Picking times

private extension TKUIRoutingResultsCard {
  
  func showTimePicker(time: TKUIRoutingResultsViewModel.RouteBuilder.Time, timeZone: TimeZone) {
    guard let controller = controller else {
      preconditionFailure("Shouldn't be able to show time picker!")
    }
    
    let sender: UIButton = accessoryView.timeButton
    
    let picker = TKUITimePickerSheet(time: time.date, timeType: time.timeType, timeZone: timeZone)
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
  
  public func timePickerRequestsResign(_ pickerSheet: TKUITimePickerSheet) {
    func onDismissal() {
      let selection = TKUIRoutingResultsViewModel.RouteBuilder.Time(timeType: pickerSheet.selectedTimeType(), date: pickerSheet.selectedDate())
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
