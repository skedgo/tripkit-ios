//
//  TKUITripOverviewCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources
import TGCardViewController

#if TK_NO_MODULE
#else
  import TripKit
#endif


class TKUITripsPageCard: TGPageCard {
  
  /// Constructs a page card configured for displaying the alternative trips
  /// of a request.
  ///
  /// - Parameter trip: Trip to focus on first
  init(highlighting trip: Trip) {
    // make sure this is the visible trip in our group
    trip.setAsPreferredTrip()
    
    let trips = trip.request.sortedVisibleTrips()
    guard let index = trips.firstIndex(of: trip) else { preconditionFailure() }
    
    let cards = trips.enumerated().map { TKUITripOverviewCard(trip: $1, index: $0) }
    
    super.init(cards: cards, initialPage: index, includeHeader: false)
  }
  
  required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
}

public class TKUITripOverviewCard: TGTableCard {
  
  typealias TripOverviewCardActionsView = TKUICardActionsView<TGCard, Trip>
  
  public static var config = Configuration.empty
  
  private let trip: Trip
  private let index: Int? // for restoring
  private var zoomToTrip: Bool = false // for restoring

  /// Set this callback to include a "Show routes" button, which then presents the `TKUIRoutingResultsCard`
  /// and selecting a different trip will trigger this callback.
  ///
  /// Returning `true` will lead to that trip being displayed as usual in *another* `TKUITripOverviewCard`
  /// that gets pushed, and returning `false` will do nothing, i.e., the callback handles displaying it.
  var selectedAlternativeTripCallback: ((Trip) -> Bool)? = nil
  
  fileprivate var viewModel: TKUITripOverviewViewModel!
  private let disposeBag = DisposeBag()
  
  private let alternativesTapped = PublishSubject<IndexPath>()
  private let highlighted = PublishSubject<IndexPath>()
  private let isVisible = BehaviorSubject<Bool>(value: false)
  
  private weak var tableView: UITableView?

  public init(trip: Trip, index: Int? = nil) {
    self.trip = trip
    self.index = index
    
    let mapManager = TKUITripOverviewCard.config.mapManagerFactory(trip)
    super.init(title: Loc.Trip(index: index.map { $0 + 1 }), mapManager: mapManager)
    didInit()
  }
  
  public required convenience init?(coder: NSCoder) {
    guard
      let data = coder.decodeObject(forKey: "viewModel") as? Data,
      let trip = TKUITripOverviewViewModel.restore(from: data)
      else {
        return nil
    }
    
    let index = coder.containsValue(forKey: "index")
      ? coder.decodeInteger(forKey: "index")
      : nil
    
    self.init(trip: trip, index: index)
    didInit()

    zoomToTrip = true
  }
  
  public override func encode(with aCoder: NSCoder) {
    aCoder.encode(TKUITripOverviewViewModel.save(trip: viewModel.trip), forKey: "viewModel")

    if let index = index {
      aCoder.encode(index, forKey: "index")
    }
  }
  
  private func didInit() {
    if let knownMapManager = mapManager as? TKUIMapManager {
      knownMapManager.attributionDisplayer = { [weak self] sources, sender in
        let displayer = TKUIAttributionTableViewController(attributions: sources)
        self?.controller?.present(displayer, inNavigator: true, preferredStyle: .popover, sender: sender)
      }
    }
  }

  override public func didBuild(tableView: UITableView, cardView: TGCardView) {
    super.didBuild(tableView: tableView, cardView: cardView)
    
    self.tableView = tableView
    
    tableView.register(TKUISegmentStationaryCell.nib, forCellReuseIdentifier: TKUISegmentStationaryCell.reuseIdentifier)
    tableView.register(TKUISegmentMovingCell.nib, forCellReuseIdentifier: TKUISegmentMovingCell.reuseIdentifier)
    tableView.register(TKUISegmentAlertCell.nib, forCellReuseIdentifier: TKUISegmentAlertCell.reuseIdentifier)
    tableView.register(TKUISegmentImpossibleCell.nib, forCellReuseIdentifier: TKUISegmentImpossibleCell.reuseIdentifier)

    tableView.dataSource = nil
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUITripOverviewViewModel.Section>(
      configureCell: { [unowned self] ds, tv, ip, item in
        switch item {
        case .terminal(let item):
          return self.terminalCell(for: item, tableView: tv, indexPath: ip)
        case .stationary(let item):
          return TKUITripOverviewCard.stationaryCell(for: item, tableView: tv, indexPath: ip)
        case .moving(let item):
          return self.movingCell(for: item, tableView: tv, indexPath: ip)
        case .alert(let item):
          return self.alertCell(for: item, tableView: tv, indexPath: ip)
        case .impossible(_, let title):
          return self.impossibleCell(text: title, tableView: tv, indexPath: ip)
        }
    })
    
    let selected: Observable<TKUITripOverviewViewModel.Item>
    #if targetEnvironment(macCatalyst)
    self.clickToHighlightDoubleClickToSelect = true
    self.handleMacSelection = highlighted.onNext
    selected = highlighted
      .map { dataSource[$0] }
      .asObservable()
    #else
    selected = tableView.rx
      .modelSelected(TKUITripOverviewViewModel.Item.self)
      .asObservable()
    #endif
    
    let mergedSelection = Observable.merge(selected, alternativesTapped.map { dataSource[$0] }).asSignal(onErrorSignalWith: .empty())
    
    viewModel = TKUITripOverviewViewModel(
      trip: trip,
      inputs: TKUITripOverviewViewModel.UIInput(
        selected: mergedSelection,
        isVisible: isVisible.asDriver(onErrorJustReturn: true)
      )
    )
    
    viewModel.titles
      .drive(cardView.rx.titles)
      .disposed(by: disposeBag)

    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.dataSources
      .drive(onNext: { [weak self] sources in
        self?.showAttribution(for: sources, in: tableView)
      })
      .disposed(by: disposeBag)
    
    viewModel.refreshMap
      .emit(onNext: { [weak self] in
        (self?.mapManager as? TKUITripMapManager)?.updateTrip()
      })
      .disposed(by: disposeBag)

    viewModel.next
      .emit(onNext: { [weak self] in self?.handle($0) })
      .disposed(by: disposeBag)
  }
  
  public override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)
    
    guard let tv = self.tableView, tv.tableHeaderView == nil else { return }
    
    var actions: [TKUITripOverviewCard.TripAction] = []
    if let factory = TKUITripOverviewCard.config.tripActionsFactory {
      actions.append(contentsOf: factory(viewModel.trip))
    }
    
    if selectedAlternativeTripCallback != nil {
      actions.append(TripAction(title: "Alternatives", icon: .iconAlternative) { [weak self] (_, _, trip, _) -> Bool in
        trip.request.expandForFavorite = true
        self?.handle(.showAlternativeRoutes(trip.request))
        return false
      })
    }
    
    guard !actions.isEmpty else { return }

    let actionsView = TripOverviewCardActionsView(frame: CGRect(x: 0, y: 0, width: tv.frame.width, height: 80))
    actionsView.configure(with: actions, model: viewModel.trip, card: self)
    actionsView.frame.size.height = actionsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    tv.tableHeaderView = actionsView
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
   
    isVisible.onNext(true)
    TKUICustomization.shared.feedbackActiveItemHandler?(viewModel.trip)
    
    if zoomToTrip {
      (mapManager as? TKUITripMapManager)?.showTrip(animated: animated)
      zoomToTrip = false
    } else {
      (mapManager as? TKUITripMapManager)?.deselectSegment(animated: animated)
    }
  }
  
  public override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    
    isVisible.onNext(false)
  }
  
}

// MARK: - Configuring cells

extension TKUITripOverviewCard {
  
  private func terminalCell(for terminal: TKUITripOverviewViewModel.TerminalItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentStationaryCell.reuseIdentifier, for: indexPath) as? TKUISegmentStationaryCell else { preconditionFailure() }
    cell.configure(with: terminal, for: self)
    return cell
  }

  private static func stationaryCell(for stationary: TKUITripOverviewViewModel.StationaryItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentStationaryCell.reuseIdentifier, for: indexPath) as? TKUISegmentStationaryCell else { preconditionFailure() }
    cell.configure(with: stationary)
    return cell
  }
  
  private func alertCell(for alertItem: TKUITripOverviewViewModel.AlertItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentAlertCell.reuseIdentifier, for: indexPath) as? TKUISegmentAlertCell else { preconditionFailure() }
    cell.configure(with: alertItem)    
    return cell
  }

  private func movingCell(for moving: TKUITripOverviewViewModel.MovingItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentMovingCell.reuseIdentifier, for: indexPath) as? TKUISegmentMovingCell else { preconditionFailure() }
    cell.configure(with: moving, for: self)
    return cell
  }

  private func impossibleCell(text: String, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentImpossibleCell.reuseIdentifier, for: indexPath) as? TKUISegmentImpossibleCell else { preconditionFailure() }
    
    cell.titleLabel.text = text
    
    cell.button.rx.tap
      .subscribe(onNext: { [unowned self] _ in self.alternativesTapped.onNext(indexPath) })
      .disposed(by: cell.disposeBag)
    
    return cell
  }
}

// MARK: - Attribution

extension TKUITripOverviewCard {
  private func showAttribution(for sources: [TKAPI.DataAttribution], in tableView: UITableView) {
    let footer = TKUIAttributionView.newView(sources, fitsIn: tableView)
    footer?.backgroundColor = tableView.backgroundColor
    
    let tapper = UITapGestureRecognizer(target: nil, action: nil)
    tapper.rx.event
      .filter { $0.state == .ended }
      .subscribe(onNext: { [weak self] _ in
        self?.presentAttributions(for: sources, sender: footer)
      })
      .disposed(by: disposeBag)
    footer?.addGestureRecognizer(tapper)
    
    tableView.tableFooterView = footer
  }
  
  private func presentAttributions(for sources: [TKAPI.DataAttribution], sender: Any?) {   
    let attributor = TKUIAttributionTableViewController(attributions: sources)    
    let navigator = UINavigationController(rootViewController: attributor)
    present(navigator, sender: sender)
  }
  
  private func present(_ viewController: UIViewController, sender: Any? = nil) {
    guard let controller = controller else { return }
    if controller.traitCollection.horizontalSizeClass == .regular {
      viewController.modalPresentationStyle = .popover
      let presentation = viewController.popoverPresentationController
      presentation?.sourceView = controller.view
      if let view = sender as? UIView {
        presentation?.sourceView = view
        presentation?.sourceRect = view.bounds
      } else if let barButton = sender as? UIBarButtonItem {
        presentation?.barButtonItem = barButton
      }
    } else {
      viewController.modalPresentationStyle = .currentContext
    }
    controller.present(viewController, animated: true)
  }
  
}

// MARK: - Navigation

extension TKUITripOverviewCard {
  
  private func handle(_ next: TKUITripOverviewViewModel.Next) {
    switch next {
    case .handleSelection(let segment):
      guard let segmentHandler = TKUITripOverviewCard.config.presentSegmentHandler else { return }
      segmentHandler(self, segment)
      
    case .showAlerts(let alerts):
      let alertController = TKUIAlertViewController()
      alertController.alerts = alerts
      controller?.present(alertController, inNavigator: true)

    case .showAlternativeRoutes(let request):
      let card = TKUIRoutingResultsCard(request: request)
      card.onSelection = selectedAlternativeTripCallback
      controller?.push(card)
    }
  }
  
}
