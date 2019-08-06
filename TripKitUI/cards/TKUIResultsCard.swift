//
//  TKUIResultsCard.swift
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

public protocol TKUIResultsCardDelegate: class {
  func resultsCard(_ card: TKUIResultsCard, requestsModePickerWithModes modes: [String], for region: TKRegion, sender: Any?)
}

public class TKUIResultsCard: TGTableCard {
  
  typealias RoutingModePicker = TKUIModePicker<TKRegion.RoutingMode>
  
  public static var config = Configuration.empty

  public weak var resultsDelegate: TKUIResultsCardDelegate?
  
  private let destination: MKAnnotation?
  private var request: TripRequest? // also for saving

  private var viewModel: TKUIResultsViewModel!
  let disposeBag = DisposeBag()
  private var realTimeBag = DisposeBag()
  
  private let accessoryView = TKUIResultsAccessoryView.instantiate()
  private weak var modePicker: RoutingModePicker?
  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIResultsViewModel.Section>(
    configureCell: TKUIResultsCard.cell
  )
  
  private let changedTime = PublishSubject<TKUIResultsViewModel.RouteBuilder.Time>()
  private let changedModes = PublishSubject<[String]?>()
  
  public init(destination: MKAnnotation) {
    self.destination = destination
    self.request = nil
    
    let title = Loc.PlanTrip
    let mapManager = TKUIResultsCard.config.mapManagerFactory(destination)
    super.init(
      title: title, style: .grouped,
      accessoryView: accessoryView, mapManager: mapManager,
      initialPosition: nil // keep same as before (so that user can drop another pin)
    )
    didInit()
  }
  
  
  public init(request: TripRequest) {
    self.destination = nil
    self.request = request

    let title = Loc.Trips
    let mapManager = TKUIResultsCard.config.mapManagerFactory(request.toLocation)
    super.init(
      title: title, style: .grouped,
      accessoryView: accessoryView, mapManager: mapManager,
      initialPosition: .extended // show fully as we'll have routes shortly
    )
    didInit()
  }
  
  public required convenience init?(coder: NSCoder) {
    guard
      let data = coder.decodeObject(forKey: "viewModel") as? Data,
      let request = TKUIResultsViewModel.restore(from: data)
      else {
        return nil
    }
    
    self.init(request: request)
  }
  
  private func didInit() {
    // Don't de-select as we use a custom style and want to keep highlighting
    // the best trip (as it's also highlighted on the map still).
    self.deselectOnAppear = false
  }
  
  public override func encode(with aCoder: NSCoder) {
    aCoder.encode(TKUIResultsViewModel.save(request: request), forKey: "viewModel")
  }
  
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard
      let tableView = (cardView as? TGScrollCardView)?.tableView,
      let mapManager = mapManager as? TKUIResultsMapManagerType
      else {
        preconditionFailure()
    }
    
    // Build the view model
    
    let inputs: TKUIResultsViewModel.UIInput = (
      selected: tableView.rx.modelSelected(TKUIResultsViewModel.Item.self).asSignal(),
      tappedDate: accessoryView.timeButton.rx.tap.asSignal(),
      tappedShowModes: accessoryView.transportButton.rx.tap.asSignal(),
      tappedShowModeOptions: .empty(),
      changedDate: changedTime.asSignal(onErrorSignalWith: .empty()),
      changedModes: changedModes.asSignal(onErrorSignalWith: .empty()),
      changedSortOrder: .empty()
    )
    
    let mapInput: TKUIResultsViewModel.MapInput = (
      tappedMapRoute: mapManager.selectedMapRoute,
      droppedPin: mapManager.droppedPin
    )
    
    let viewModel: TKUIResultsViewModel
    if let destination = self.destination {
      viewModel = TKUIResultsViewModel(destination: destination, inputs: inputs, mapInput: mapInput)
    } else if let request = self.request {
      viewModel = TKUIResultsViewModel(request: request, inputs: inputs, mapInput: mapInput)
    } else {
      preconditionFailure()
    }
    self.viewModel = viewModel
    mapManager.viewModel = viewModel
    
    // Table view configuration
    
    tableView.register(TKUITripCell.nib, forCellReuseIdentifier: TKUITripCell.reuseIdentifier)
    tableView.register(TKUIResultsSectionFooterView.nib, forHeaderFooterViewReuseIdentifier: TKUIResultsSectionFooterView.reuseIdentifier)
    
    tableView.tableFooterView = UIView()

    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    tableView.dataSource = nil
    
    // Bind outputs
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.selectedItem
      .drive(onNext: { [weak self] in
        guard let indexPath = self?.dataSource.indexPath(of: $0) else { return }
        if let visible = tableView.indexPathsForVisibleRows, visible.contains(indexPath) { return }
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
      })
      .disposed(by: disposeBag)

    viewModel.titles
      .drive(cardView.rx.titles)
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

extension TKUIResultsCard {
  
  static func cell(dataSource: RxDataSources.TableViewSectionedDataSource<TKUIResultsViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUIResultsViewModel.Item) -> UITableViewCell {
    
    if let trip = item.trip {
      let tripCell = tableView.dequeueReusableCell(withIdentifier: TKUITripCell.reuseIdentifier, for: indexPath) as! TKUITripCell
      tripCell.configure(TKUITripCell.Model(trip))
      return tripCell
      
    } else {
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      switch item {
      case .lessIndicator: cell.textLabel?.text = "Less"
      case .moreIndicator: cell.textLabel?.text = "More"
      case .nano, .trip: preconditionFailure()
      }
      return cell
    }
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

extension TKUIResultsCard: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TKUIResultsSectionFooterView.reuseIdentifier) as? TKUIResultsSectionFooterView else {
      assertionFailure()
      return nil
    }

    let formatter = TKUITripCell.Formatter()
    formatter.costColor = footerView.costLabel.textColor

    let section = dataSource.sectionModels[section]
    footerView.badge = section.badge?.footerContent
    footerView.attributedCost = formatter.costString(costs: section.costs)
    return footerView
  }
  
}

// MARK: - Mode picker

private extension TKUIResultsCard {
  func updateModePicker(_ modes: TKUIResultsViewModel.AvailableModes, in tableView: UITableView) {
    if modes.available.isEmpty {
      tableView.tableHeaderView = nil
      
    } else {
      let modePicker: RoutingModePicker
      if let existing = self.modePicker {
        modePicker = existing
      } else {
        modePicker = self.buildModePicker()
        modePicker.addAsHeader(to: tableView)
        self.modePicker = modePicker
      }
      modePicker.configure(all: modes.available, updateAll: true, currentlyEnabled: modes.isEnabled)
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

private extension TKUIResultsCard {
  func navigate(to next: TKUIResultsViewModel.Next) {
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

// MARK: - Picking times

private extension TKUIResultsCard {
  
  func showTimePicker(time: TKUIResultsViewModel.RouteBuilder.Time, timeZone: TimeZone) {
    
    guard let controller = controller else {
      preconditionFailure("Shouldn't be able to show time picker!")
    }
    let sender: UIButton = accessoryView.timeButton
    
    let picker = TKUITimePickerSheet(time: time.date, timeType: time.timeType, timeZone: timeZone)
    picker.selectAction = { [weak self] timeType, date in
      self?.changedTime.onNext(TKUIResultsViewModel.RouteBuilder.Time(timeType: timeType, date: date))
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

extension TKUIResultsCard: TKUITimePickerSheetDelegate {
  
  public func timePickerRequestsResign(_ pickerSheet: TKUITimePickerSheet) {
    func onDismissal() {
      let selection = TKUIResultsViewModel.RouteBuilder.Time(timeType: pickerSheet.selectedTimeType(), date: pickerSheet.selectedDate())
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

extension TKUIResultsCard {
  
  private func showTransportOptions(modes: [String], for region: TKRegion) {
    resultsDelegate?.resultsCard(self, requestsModePickerWithModes: modes, for: region, sender: accessoryView.transportButton)
  }
  
  public func refreshForUpdatedModes() {
    changedModes.onNext(nil)
  }
  
}
