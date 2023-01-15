//
//  TKUITripOverviewCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

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
  
}

public class TKUITripOverviewCard: TKUITableCard {
  
  typealias TripOverviewCardActionsView = TKUICardActionsView<TGCard, Trip>
  
  public static var config = Configuration.empty
  
  private let initialTrip: Trip
  private let index: Int? // for restoring
  private var zoomToTrip: Bool = false // for restoring

  /// Set this callback to include a "Show routes" button, which then presents the `TKUIRoutingResultsCard`
  /// and selecting a different trip will trigger this callback.
  ///
  /// Returning `true` will lead to that trip being displayed as usual in *another* `TKUITripOverviewCard`
  /// that gets pushed, and returning `false` will do nothing, i.e., the callback handles displaying it.
  public var selectedAlternativeTripCallback: ((Trip) -> Bool)? = nil
  
  fileprivate var viewModel: TKUITripOverviewViewModel!
  private let disposeBag = DisposeBag()
  
  private let alternativesTapped = PublishSubject<IndexPath>()
  private let isVisible = BehaviorSubject<Bool>(value: false)
  
  // The trip being presented may be changing as a result of user actions
  // in the MxM card, e.g., selecting a different departures , therefore,
  // we model it as an observable sequence.
  private let presentedTripPublisher = PublishSubject<Trip>()
  
  private var titleView: TKUITripTitleView?
  private weak var tableView: UITableView?
  
  var tripMapManager: TKUITripMapManager? { mapManager as? TKUITripMapManager }

  public init(trip: Trip, index: Int? = nil) {
    self.initialTrip = trip
    self.index = index
    
    let tripTitle = TKUITripTitleView.newInstance()
    tripTitle.configure(with: .init(trip, allowFading: false))
    self.titleView = tripTitle
    
    let mapManager = TKUITripOverviewCard.config.mapManagerFactory(trip)
    super.init(title: .custom(tripTitle, dismissButton: tripTitle.dismissButton), mapManager: mapManager)

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
    tableView.register(TKUISegmentStationaryDoubleCell.nib, forCellReuseIdentifier: TKUISegmentStationaryDoubleCell.reuseIdentifier)
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
          if item.endSubtitle != nil {
            return TKUITripOverviewCard.stationaryDoubleCell(for: item, tableView: tv, indexPath: ip)
          } else {
            return stationaryCell(for: item, tableView: tv, indexPath: ip)
          }
        case .moving(let item):
          return self.movingCell(for: item, tableView: tv, indexPath: ip)
        case .alert(let item):
          return self.alertCell(for: item, tableView: tv, indexPath: ip)
        case .impossible(_, let title):
          return self.impossibleCell(text: title, tableView: tv, indexPath: ip)
        }
    })
    
    let presentedTrip = presentedTripPublisher
        .asInfallible(onErrorFallbackTo: .just(initialTrip))
        .startWith(initialTrip)
    
    let mergedSelection = Observable.merge(
        selectedItem(in: tableView, dataSource: dataSource).asObservable(),
        alternativesTapped.map { dataSource[$0] }
      ).asSignal(onErrorSignalWith: .empty())
    
    viewModel = TKUITripOverviewViewModel(
      presentedTrip: presentedTrip,
      inputs: TKUITripOverviewViewModel.UIInput(
        selected: mergedSelection,
        isVisible: isVisible.asDriver(onErrorJustReturn: true)
      )
    )

    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.refreshMap
      .emit(onNext: { [weak tripMapManager] trip in
        tripMapManager?.refresh(with: trip)
      })
      .disposed(by: disposeBag)

    viewModel.next
      .emit(onNext: { [weak self] in self?.handle($0) })
      .disposed(by: disposeBag)
    
    // We check if the view is visible before showing attribution
    // and card actions view, otherwise we'd get AL warnings due
    // to the table view hasn't had the correct size when the card's
    // `didBuild(tableView:cardView)` is called.
    
    isVisible.asDriver(onErrorJustReturn: true)
      .filter { $0 }
      .withLatestFrom(viewModel.actions)
      .drive(onNext: { [weak self] actions in
        tableView.tableHeaderView = self?.buildActionsView(from: actions.0, trip: actions.1)
      })
      .disposed(by: disposeBag)
    
    isVisible.asDriver(onErrorJustReturn: true)
      .filter { $0 }
      .withLatestFrom(viewModel.dataSources)
      .drive(onNext: { [weak self] dataSources in
        tableView.tableFooterView = self?.buildTableFooterView()
        self?.showNotification(in: tableView)
        self?.showAttribution(for: dataSources, in: tableView)
      })
      .disposed(by: disposeBag)
    
    isVisible
      .filter { $0 }
      .withLatestFrom(viewModel.refreshMap.startWith(initialTrip))
      .withUnretained(self)
      .subscribe(onNext: { owner, trip in
        TKUICustomization.shared.feedbackActiveItemHandler?(trip)
        if let controller = owner.controller {
          TKUIEventCallback.handler(.tripSelected(trip, controller: controller, owner.disposeBag))
        }
      })
      .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
   
    isVisible.onNext(true)
    
    if zoomToTrip {
      tripMapManager?.showTrip(animated: animated)
      zoomToTrip = false
    } else {
      tripMapManager?.deselectSegment(animated: animated)
    }
    
    TKUIEventCallback.handler(.cardAppeared(self))
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
    cell.accessibilityTraits = .none // No action on terminals
    return cell
  }

  private func stationaryCell(for stationary: TKUITripOverviewViewModel.StationaryItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentStationaryCell.reuseIdentifier, for: indexPath) as? TKUISegmentStationaryCell else { preconditionFailure() }
    cell.configure(with: stationary, for: self)
    cell.accessibilityTraits = TKUITripOverviewCard.config.presentSegmentHandler != nil ? .button : .none
    return cell
  }

  private static func stationaryDoubleCell(for stationary: TKUITripOverviewViewModel.StationaryItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentStationaryDoubleCell.reuseIdentifier, for: indexPath) as? TKUISegmentStationaryDoubleCell else { preconditionFailure() }
    cell.configure(with: stationary)
    cell.accessibilityTraits = TKUITripOverviewCard.config.presentSegmentHandler != nil ? .button : .none
    return cell
  }

  private func alertCell(for alertItem: TKUITripOverviewViewModel.AlertItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentAlertCell.reuseIdentifier, for: indexPath) as? TKUISegmentAlertCell else { preconditionFailure() }
    cell.configure(with: alertItem)    
    cell.accessibilityTraits = .button // Will show alerts
    return cell
  }

  private func movingCell(for moving: TKUITripOverviewViewModel.MovingItem, tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: TKUISegmentMovingCell.reuseIdentifier, for: indexPath) as? TKUISegmentMovingCell else { preconditionFailure() }
    cell.configure(with: moving, for: self)
    cell.accessibilityTraits = TKUITripOverviewCard.config.presentSegmentHandler != nil ? .button : .none
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

// MARK: - Table Footer

extension TKUITripOverviewCard {
  
  private func buildTableFooterView() -> UIStackView {
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.isUserInteractionEnabled = true
    stackView.distribution = .equalSpacing
    return stackView
  }
  
}

// MARK: - Notification

extension TKUITripOverviewCard {
  
  private func showNotification(in tableView: UITableView) {
    guard let tableFooterView = tableView.tableFooterView as? UIStackView
    else {
      return
    }
    
    let footer = TKUINotificationView.newInstance()
    footer.backgroundColor = tableView.backgroundColor
    footer.configure(with: viewModel)
    
    tableFooterView.addArrangedSubview(footer)
    tableFooterView.layoutIfNeeded()
    tableFooterView.frame.size.height = tableFooterView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
  }
  
}

// MARK: - Attribution

extension TKUITripOverviewCard {
  
  private func showAttribution(for sources: [TKAPI.DataAttribution], in tableView: UITableView) {
    guard let tableFooterView = tableView.tableFooterView as? UIStackView,
          let footer = TKUIAttributionView.newView(sources, fitsIn: tableView)
    else {
      return
    }
    
    footer.backgroundColor = tableView.backgroundColor
    let tapper = UITapGestureRecognizer(target: nil, action: nil)
    tapper.rx.event
      .filter { $0.state == .ended }
      .subscribe(onNext: { [weak self] _ in
        self?.presentAttributions(for: sources, sender: footer)
      })
      .disposed(by: disposeBag)
    footer.addGestureRecognizer(tapper)
    footer.accessibilityTraits = .button
    
    tableFooterView.addArrangedSubview(footer)
    tableFooterView.layoutIfNeeded()
    tableFooterView.frame.size.height = tableFooterView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
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

// MARK: - Mode-by-mode updates

extension TKUITripOverviewCard: TKUITripModeByModeCardDelegate {
  
  public func modeByModeCard(_ card: TKUITripModeByModeCard, updatedTrip trip: Trip) {
    presentedTripPublisher.onNext(trip)
  }
  
}

// MARK: - Trip actions

extension TKUITripOverviewCard {
  
  private func buildActionsView(from actions: [TKUITripOverviewCard.TripAction], trip: Trip) -> TripOverviewCardActionsView? {
    var mutable = actions
    if selectedAlternativeTripCallback != nil {
      mutable.append(TripAction(title: "Alternatives", icon: .iconAlternative) { [weak self] (_, _, trip, _) -> Bool in
        trip.request.expandForFavorite = true
        self?.handle(.showAlternativeRoutes(trip.request))
        return false
      })
    }
    
    guard !mutable.isEmpty else { return nil }
    
    let actionsView = TripOverviewCardActionsView(frame: CGRect(x: 0, y: 0, width: 414, height: 80))
    actionsView.configure(with: mutable, model: trip, card: self)
    actionsView.frame.size.height = actionsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    return actionsView
  }

}
