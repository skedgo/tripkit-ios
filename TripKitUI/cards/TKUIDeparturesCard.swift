//
//  TKUIDeparturesCard.swift
//  TripGo
//
//  Created by Adrian Schoenig on 19/5/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift
import RxCocoa
import RxDataSources

public protocol TKUIDeparturesCardDelegate: class {
  func TKUIDeparturesCard(_ card: TKUIDeparturesCard, selectedDeparture: StopVisits)
}

/// A card that lists all the departures from a public transport stop (or a
/// list thereof).
public class TKUIDeparturesCard : TGTableCard {
  
  enum Input {
    case stops([TKUIStopAnnotation])
    case dls(TKDLSTable, start: Date, selectedServiceID: String?)
    case restored(TKUIDeparturesViewModel.RestorableState)
  }
  
  public static var config = Configuration.empty
  
  /// Provide a departures delegate to handle taps on departures, rather than
  /// using the default behaviour of pushing a card displaying the service.
  public weak var departuresDelegate: TKUIDeparturesCardDelegate?
  
  private let input: Input

  private var viewModel: TKUIDeparturesViewModel!
  private var dataSource: RxTableViewSectionedAnimatedDataSource<TKUIDeparturesViewModel.Section>!
  private var tableView: UITableView!
  
  private let disposeBag = DisposeBag()
  private var realTimeDisposeBag = DisposeBag()

  private let datePublisher = PublishSubject<Date>()
  private let loadMorePublisher = PublishSubject<IndexPath>()
  private let scrollToTopPublisher = PublishSubject<Void>()

  private let accessoryView = TKUIDeparturesAccessoryView.newInstance()
  
  /// Configures a new instance that'll fetch and display the departures for
  /// the provided public transport stop(s).
  ///
  /// - Parameters:
  ///   - stops: Stops
  ///   - mapManager: Optional map manager, which will be asked to display
  ///       the stop(s) on appearance, by asking its map view to select the
  ///       first stop and calling `mapManager.zoom(to:animated)`.
  public init(titleView: (UIView, UIButton)? = nil, stops: [TKUIStopAnnotation], reusing mapManager: TGMapManager? = nil) {
    self.input = .stops(stops)

    let title: CardTitle
    if let view = titleView {
      title = .custom(view.0, dismissButton: view.1)
    } else {
      title = .default(Loc.Timetable, nil, self.accessoryView)
    }
    
    super.init(title: title, mapManager: mapManager, initialPosition: .extended)
    didInit()
  }

  /// Configures a new instance that'll fetch and display the departures for
  /// the provided DLS table
  ///
  /// - Parameters:
  ///   - dlsTable: A stop pair
  ///   - startDate: Date to start on
  ///   - mapManager: Optional map manager, which will be asked to display
  ///       the stop(s) on appearance, by asking its map view to select the
  ///       first stop and calling `mapManager.zoom(to:animated)`.
  public init(titleView: (UIView, UIButton)? = nil, dlsTable: TKDLSTable, startDate: Date, selectedServiceID: String? = nil, reusing mapManager: TGMapManager? = nil) {
    self.input = .dls(dlsTable, start: startDate, selectedServiceID: selectedServiceID)
    
    let title: CardTitle
    if let view = titleView {
      title = .custom(view.0, dismissButton: view.1)
    } else {
      title = .default(Loc.Timetable, nil, self.accessoryView)
    }
    
    super.init(title: title, mapManager: mapManager, initialPosition: .extended)
    didInit()
  }
  
  required public init?(coder: NSCoder) {
    guard
      let data = coder.decodeData(),
      let restoredState = TKUIDeparturesViewModel.restoredState(from: data)
      else {
        return nil
    }
    
    self.input = .restored(restoredState)
    super.init(title: .default(Loc.Timetable, nil, accessoryView), mapManager: nil, initialPosition: .extended)
    didInit()
  }
  
  private func didInit() {
    // Don't de-select as we use a custom style and want to keep highlighting
    // the selected departure
    self.deselectOnAppear = false
  }
  
  override public func encode(with aCoder: NSCoder) {
    guard let data = try? viewModel.save() else { return }
    aCoder.encode(data)
    
    // Not keeping around reused map manager, as that's complicated
  }
  
  // MARK: - Public methods
  
  public func visibleDepartures() -> [StopVisits] {
    guard let visible = tableView?.indexPathsForVisibleRows else { return [] }
    
    let items = visible.compactMap { dataSource[$0] }
    return viewModel.stopVisits(for: items)
  }
  
  // MARK: - Card Life Cycle
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    super.didBuild(cardView: cardView, headerView: headerView)
    
    guard let tableView = (cardView as? TGScrollCardView)?.tableView else {
      preconditionFailure()
    }
    
    tableView.register(TKUIDepartureCell.nib, forCellReuseIdentifier: TKUIDepartureCell.reuseIdentifier)
    
    let cellAlertPublisher = PublishSubject<TKUIDeparturesViewModel.Item>()

    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIDeparturesViewModel.Section>(
      configureCell: { ds, tv, ip, item in
        guard let cell = tv.dequeueReusableCell(withIdentifier: TKUIDepartureCell.reuseIdentifier, for: ip) as? TKUIDepartureCell else {
          preconditionFailure()
        }
        
        cell.dataSource = item.contentModel
        return cell
        
      }, titleForHeaderInSection: { ds, index in
        return ds.sectionModels[index].title
      })
    
    self.tableView = tableView
    self.dataSource = dataSource
    
    
    // Inputs to the VM
    
    let loadMoreAfter = loadMorePublisher
      .map { dataSource[$0] }
      .asSignal(onErrorSignalWith: .empty())
    
    let filter = accessoryView.searchBar.rx.text.orEmpty
    
    let input: TKUIDeparturesViewModel.UIInput = (
      selected: tableView.rx.modelSelected(TKUIDeparturesViewModel.Item.self).asSignal(),
      showAlerts: cellAlertPublisher.asSignal(onErrorSignalWith: .empty()),
      filter: filter.asDriver(),
      date: datePublisher.asDriver(onErrorDriveWith: .empty()),
      refresh: .empty(),
      loadMoreAfter: loadMoreAfter
    )
    
    switch self.input {
    case .stops(let stops):
      viewModel = TKUIDeparturesViewModel(stops: stops, input: input)
    case .dls(let dls, let start, let selection):
      viewModel = TKUIDeparturesViewModel(dlsTable: dls, startDate: start, selectedServiceID: selection, input: input)
    case .restored(let state):
      viewModel = TKUIDeparturesViewModel(restoredState: state, input: input)
    }
    
    
    // Bind VM outputs
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)

    viewModel.selectedItem
      .drive(onNext: {
        let indexPath = dataSource.indexPath(of: $0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
      })
      .disposed(by: disposeBag)
    

    viewModel.titles
      .drive(cardView.rx.titles)
      .disposed(by: disposeBag)

    viewModel.timeTitle
      .drive(accessoryView.timeButton.rx.title(for: .normal))
      .disposed(by: disposeBag)
    
    viewModel.lines
      .drive(accessoryView.rx.lines)
      .disposed(by: disposeBag)

    
    // TODO: Add viewModel.embarkationStopAlerts
    
    // TODO: Add viewModel.error

    let actions: [TKUIDeparturesCardAction]
    if let factory = TKUIDeparturesCard.config.departuresActionsFactory {
      actions = factory(viewModel.departureStops)
    } else {
      actions = []
    }
    accessoryView.setCustomActions(actions, for: viewModel.departureStops, card: self)

    // Interactions

    accessoryView.timeButton.rx.tap
      .withLatestFrom(viewModel.time)
      .subscribe(onNext: { [unowned self] date in
        guard let sender = self.accessoryView.timeButton else { assertionFailure(); return }
        self.showTimePicker(date: date, sender: sender)
      })
      .disposed(by: disposeBag)
    
    viewModel.next
      .emit(onNext: { [weak self] in self?.navigate(to: $0) })
      .disposed(by: disposeBag)

    
    // Additional customisations
    
    // When initially populating, scroll to the top, but wait a little
    // while to give the table view a chance to populate itself
    viewModel.sections
      .asObservable()
      .compactMap(viewModel.topIndexPath)
      .take(1)
      .delay(.milliseconds(250), scheduler: MainScheduler.instance)
      .subscribe(onNext: { indexPath in
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
      })
      .disposed(by: disposeBag)

    scrollToTopPublisher
      .withLatestFrom(viewModel.sections)
      .map(viewModel.topIndexPath)
      .subscribe(onNext: {
        if let indexPath = $0 {
          tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
      })
      .disposed(by: disposeBag)

    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
  
  public override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)
    
    guard let mapManager = mapManager as? TGMapManager else { return }
    
    if case .stops(let stops) = input, let first = stops.first {
      mapManager.zoom(to: stops, animated: animated)
      mapManager.mapView?.selectAnnotation(first, animated: animated)
    }
    
    viewModel.realTimeUpdate
      .drive()
      .disposed(by: realTimeDisposeBag)
  }
  
  public override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    
    realTimeDisposeBag = DisposeBag()
  }
}


// MARK: - Navigation

extension TKUIDeparturesCard {
  
  private func navigate(to next: TKUIDeparturesViewModel.Next) {
    guard let controller = controller else { return } // Delayed callback
    
    switch next {
    case .departure(let departure):
      if let delegate = departuresDelegate {
        delegate.TKUIDeparturesCard(self, selectedDeparture: departure)
      } else {
        controller.push(TKUIServiceCard(embarkation: departure))
      }
      
    case .alerts(let alerts):
      show(alerts)
    }
  }
  
}


// MARK: - Time selection

private extension TKUIDeparturesCard {
  
  func showTimePicker(date: Date, sender: UIView) {
    
    guard let controller = controller else {
      preconditionFailure("Shouldn't be able to show time picker!")
    }
    
    let picker = TKUITimePickerSheet(time: date, timeZone: viewModel.timeZone)
    picker.selectAction = { [unowned self] timeType, date in
      self.datePublisher.onNext(date)
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

extension TKUIDeparturesCard: TKUITimePickerSheetDelegate {
  
  public func timePickerRequestsResign(_ pickerSheet: TKUITimePickerSheet) {
    controller?.dismiss(animated: true) {
      self.datePublisher.onNext(pickerSheet.selectedDate())
    }
  }
  
}


// MARK: - Scrolling to base data and to bottom

extension TKUIDeparturesCard: UITableViewDelegate {
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    guard let tableView = scrollView as? UITableView else {
      return
    }
    
    // Dismiss keyboard, unless we're typing
    if scrollView.isDragging, !scrollView.isDecelerating, scrollView.contentOffset.y > 40 {
//      [self.searchBar resignFirstResponder];
//
//      // edge insets
//      UIEdgeInsets contentInsets = self.insets;
//      tableView.contentInset = contentInsets;
//      tableView.scrollIndicatorInsets = contentInsets;
    }
    
    let percentScrolled = (tableView.contentOffset.y + tableView.frame.height) / tableView.contentSize.height
    if percentScrolled > 0.95, let last = tableView.lastIndexPath {
      loadMorePublisher.onNext(last)
    }
  }
  
  public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    guard scrollView is UITableView else {
      return true
    }

    scrollToTopPublisher.onNext(())
    return false
  }
  
}

extension UITableView {
  
  var lastIndexPath: IndexPath? {
    guard
      let dataSource = dataSource,
      let sections = dataSource.numberOfSections?(in: self),
      sections > 0
      else { return nil }

    let items = dataSource.tableView(self, numberOfRowsInSection: sections - 1)
    
    guard items > 0
      else { return nil }
    
    return IndexPath(item: items - 1, section: sections - 1)
  }
  
}

// MARK: - Alerts

extension TKUIDeparturesCard {
  
  private func show(_ alerts: [TKAlert]) {
    guard !alerts.isEmpty else { return }
    
    let presenter = TKUIAlertViewController(style: .plain)
    presenter.alerts = alerts
    controller?.present(presenter, inNavigator: true)
  }
  
}
