//
//  TKUITripOverviewCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 11/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import Combine

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
  
  public enum DefaultActionPriority: Int {
    case go = 15
    case notify = 10
    case alternatives = 5
  }
  
  public static var config = Configuration.empty
  
  private let initialTrip: Trip
  private let index: Int? // for restoring
  private var zoomToTrip: Bool = false // for restoring

  /// Set this callback to include a "Show routes" button, which then presents the ``TKUIRoutingResultsCard``
  /// and selecting a different trip will trigger this callback.
  ///
  /// Returning `true` will lead to that trip being displayed as usual in *another* ``TKUITripOverviewCard``
  /// that gets pushed, and returning `false` will do nothing, i.e., the callback handles displaying it.
  public var selectedAlternativeTripCallback: ((Trip) -> Bool)? = nil
  
  /// Controls the "Get ready to leave" notifications when monitoring a trip that starts in the future.
  ///
  /// Defaults to `true`, but can be turned off via this setting.
  public var includeTimeToLeaveNotification: Bool = true
  
  fileprivate var viewModel: TKUITripOverviewViewModel!
  private let disposeBag = DisposeBag()
  
  private let alternativesTapped = PublishSubject<IndexPath>()
  private let alertsToggled = PublishSubject<Bool>()
  private let isVisible = BehaviorSubject<Bool>(value: false)
  
  // The trip being presented may be changing as a result of user actions
  // in the MxM card, e.g., selecting a different departures , therefore,
  // we model it as an observable sequence.
  private let presentedTripPublisher = PublishSubject<Trip>()
  
  private var titleView: TKUITripTitleView?
  private weak var tableView: UITableView?
  
  private lazy var notificationFooterView = TKUINotificationView.newInstance()
  
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
        alertsEnabled: alertsToggled.asSignal(onErrorSignalWith: .empty()),
        isVisible: isVisible.asDriver(onErrorJustReturn: true)
      ),
      includeTimeToLeaveNotification: includeTimeToLeaveNotification
    )

    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.refreshMap
      .emit(onNext: { [weak tripMapManager] trip in
        // Important to update the map, too, as template hash codes can change
        // an the map uses those for selection handling
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

    let footerContent = Driver.combineLatest(viewModel.dataSources, viewModel.notificationKinds)
    isVisible.asDriver(onErrorJustReturn: true)
      .filter { $0 }
      .withLatestFrom(footerContent)
      .drive(onNext: { [weak self] dataSources, notificationKinds in
        self?.showFooter(notifications: notificationKinds, dataSources: dataSources, in: tableView)
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
  
  public override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)

    if let controller {
      titleView?.update(preferredContentSizeCategory: controller.traitCollection.preferredContentSizeCategory)
    }
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

  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    if let controller {
      titleView?.update(preferredContentSizeCategory: controller.traitCollection.preferredContentSizeCategory)
    }
  }

  public override func willDisappear(animated: Bool) {
    super.willDisappear(animated: animated)
    isVisible.onNext(false)
  }
  
  public func shows(_ trip: Trip) -> Bool {
    // The trip map manager keeps a reference to the latest trip, so we can show this
    return initialTrip.tripURL == trip.tripURL
        || tripMapManager?.trip.tripURL == trip.tripURL
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

// MARK: - Table Footer: Notifications & Attributions

extension TKUITripOverviewCard {
  
  private func showFooter(notifications: Set<TKAPI.TripNotification.MessageKind>, dataSources: [TKAPI.DataAttribution], in tableView: UITableView) {
    
    let stackView = UIStackView()
    stackView.axis = .vertical
    stackView.isUserInteractionEnabled = true
    stackView.distribution = .equalSpacing

    if #available(iOS 14.0, *), TKUINotificationManager.shared.isSubscribed(to: .tripAlerts) {
      let notificationView = self.notificationFooterView
      notificationView.frame.size.width = tableView.frame.width      
      notificationView.updateAvailableKinds(notifications, includeTimeToLeaveNotification: includeTimeToLeaveNotification)
      notificationView.backgroundColor = tableView.backgroundColor

      // Footer => View Model
      // It's important here to use `controlEvent(.valueChanged)` and not
      // `value` as `value` will fire just from initialisation, and this
      // shouldn't be treated as a user action.
      notificationView.notificationSwitch.rx.controlEvent(.valueChanged)
        .subscribe(onNext: { [weak self, weak notificationView] isOn in
          guard let self, let notificationView else { return }
          self.alertsToggled.onNext(notificationView.notificationSwitch.isOn)
        })
        .disposed(by: disposeBag)
      
      // View Model => Toggle button
      // Update button state to reflect external changes, e.g., when toggled
      // via some other means or when another trip gets monitored instead.
      viewModel.notificationsEnabled
        .drive(onNext: { [weak notificationView] isOn in
          notificationView?.notificationSwitch.isOn = isOn
        })
        .disposed(by: disposeBag)

      stackView.addArrangedSubview(notificationView)
    }
    
    if let attributionText = TKUIAttributionView.attribution(for: dataSources, wording: .dataProvidedBy) {
      let label = UILabel()
      label.numberOfLines = 0
      label.attributedText = attributionText
      label.translatesAutoresizingMaskIntoConstraints = false

      let tapper = UITapGestureRecognizer(target: nil, action: nil)
      tapper.rx.event
        .filter { $0.state == .ended }
        .subscribe(onNext: { [weak self] _ in
          self?.presentAttributions(for: dataSources, sender: label)
        })
        .disposed(by: disposeBag)
      label.addGestureRecognizer(tapper)
      label.accessibilityTraits = .button
      label.isUserInteractionEnabled = true
      
      let wrapper = UIView()
      wrapper.addSubview(label)
      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
        label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 4),
        wrapper.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 16),
        wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4)
      ])

      stackView.addArrangedSubview(wrapper)
    }
    
    stackView.widthAnchor.constraint(lessThanOrEqualToConstant: tableView.frame.width).isActive = true
    stackView.setNeedsLayout()
    stackView.layoutIfNeeded()
    let newSize = stackView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    
    stackView.frame.size.height = newSize.height

    tableView.tableFooterView = stackView
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
  
  private func buildActionsView(from actions: [TKUITripOverviewCard.TripAction], trip: Trip) -> UIView? {
    var mutable = actions
    
    if #available(iOS 14.0, *), TKUINotificationManager.shared.isSubscribed(to: .tripAlerts) {
      let publisher = viewModel.notificationsEnabled
        .publisher
        .catch { _ in Just(false) }
        .map { isOn in
          // TODO: Localise
          if isOn {
            return TKUICardActionContent(title: "Mute", icon: UIImage(systemName: "bell.slash.fill")?.withRenderingMode(.alwaysTemplate) ?? .iconAlert, style: .destructive)
          } else {
            return TKUICardActionContent(title: "Alert Me", icon: UIImage(systemName: "bell.fill")?.withRenderingMode(.alwaysTemplate) ?? .iconAlert, style: .bold)
          }
        }
        .eraseToAnyPublisher()
      
      
      mutable.append(TripAction(content: publisher, priority: TKUITripOverviewCard.DefaultActionPriority.notify.rawValue) { (action, card, _, _) in
        // TODO: Localise
        let isOn = action.title != "Mute"
        (card as? TKUITripOverviewCard)?.alertsToggled.onNext(isOn)
      })
    }
    
    if selectedAlternativeTripCallback != nil {
      // TODO: Localise
      mutable.append(TripAction(title: "Alternatives", icon: .iconAlternative, priority: TKUITripOverviewCard.DefaultActionPriority.alternatives.rawValue) { [weak self] (_, _, trip, _) -> Bool in
        trip.request.expandForFavorite = true
        self?.handle(.showAlternativeRoutes(trip.request))
        return false
      })
    }
    
    guard !mutable.isEmpty else { return nil }
    
    let actionsView = TKUICardActionsViewFactory.build(
      actions: mutable,
      card: self, model: trip, container: tableView!
    )
    actionsView.frame.size.height = actionsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    return actionsView
  }

}
