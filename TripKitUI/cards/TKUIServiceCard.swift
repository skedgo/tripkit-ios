//
//  TKUIServiceCard.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa

import TGCardViewController

/// A card that lists the route of an individual public transport
/// service. Starts at the provided embarkation and optionally
/// highlights where to get off.
public class TKUIServiceCard: TKUITableCard {
  
  typealias ServiceCardActionsView = TKUICardActionsView<TKUIServiceCard, EmbarkationPair>
  
  public static var config = Configuration.empty
  
  private var dataInput: TKUIServiceViewModel.DataInput
  private var viewModel: TKUIServiceViewModel!
  private let serviceMapManager: TKUIServiceMapManager
  private let disposeBag = DisposeBag()
  
  private let scrollToTopPublisher = PublishSubject<Void>()
  private let toggleHeaderPublisher = PublishSubject<Bool>()
  private let showAlertsPublisher = PublishSubject<Void>()

  private let titleView: TKUIServiceTitleView?
  private var headerView: UIView?
  
  /// Configures a new instance that will fetch the service details
  /// and the show them in the list and on the map.
  ///
  /// - Parameters:
  ///   - embarkation: Where to get onto the service
  ///   - disembarkation: Where to get off the service (optional)
  public convenience init(titleView: (UIView, UIButton)? = nil, embarkation: StopVisits, disembarkation: StopVisits? = nil, reusing: TKUITripMapManager? = nil) {
    self.init(titleView: titleView, dataInput: .visits(embarkation: embarkation, disembarkation: disembarkation), reusing: reusing)
  }
  
  /// Configures a new instance that will fetch the service details for the provided public transport segment
  /// and the show them in the list and on the map.
  ///
  /// - Note: When initialised this `config.serviceActionsFactory` is not used.
  ///
  /// - Parameters:
  ///   - segment: A public transport segment. Will not work when provided with a different type of segment.
  public convenience init(titleView: (UIView, UIButton)? = nil, publicTransportSegment segment: TKSegment, reusing: TKUITripMapManager? = nil) {
    assert(segment.isPublicTransport)
    self.init(titleView: titleView, dataInput: .segment(segment), reusing: reusing)
  }
  
  private init(titleView: (UIView, UIButton)? = nil, dataInput: TKUIServiceViewModel.DataInput, reusing: TKUITripMapManager? = nil) {
    self.dataInput = dataInput
    
    let title: CardTitle
    if let view = titleView {
      title = .custom(view.0, dismissButton: view.1)
      self.titleView = nil
    } else {
      let header = TKUIServiceTitleView.newInstance()
      title = .custom(header, dismissButton: header.dismissButton)
      self.titleView = header
    }
    
    self.serviceMapManager = TKUIServiceMapManager()
    let mapManager: TGMapManager
    if let trip = reusing {
      mapManager = TKUIComposingMapManager(composing: serviceMapManager, onTopOf: trip)
    } else {
      mapManager = serviceMapManager
    }
    
    super.init(
      title: title,
      style: .plain,
      mapManager: mapManager,
      initialPosition: .peaking
    )
    
    didInit()
  }
  
  required convenience public init?(coder: NSCoder) {
    return nil // not supported
  }
  
  private func didInit() {
    switch self.title {
    case .custom(_, let dismissButton):
      let styledButtonImage = TGCard.closeButtonImage(style: style)
      dismissButton?.setImage(styledButtonImage, for: .normal)
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
  
  // MARK: - Card life cycle

  override public func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)

    // Table view configuration
    
    tableView.register(TKUIServiceVisitCell.nib, forCellReuseIdentifier: TKUIServiceVisitCell.reuseIdentifier)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIServiceViewModel.Section>(
      configureCell: { ds, tv, ip, item in
        let cell = tv.dequeueReusableCell(withIdentifier: TKUIServiceVisitCell.reuseIdentifier, for: ip) as! TKUIServiceVisitCell
        cell.configure(with: item)
        return cell
      }
    )
    
    // Build the view model
    
    viewModel = TKUIServiceViewModel(
      dataInput: dataInput,
      itemSelected: selectedItem(in: tableView, dataSource: dataSource)
    )
    
    serviceMapManager.viewModel = viewModel
    
    // Setting up actions view
    
    if let titleView = self.titleView, let factory = Self.config.serviceActionsFactory, case let .visits(embarkation, disembarkation) = dataInput {
      let pair: TKUIServiceCard.EmbarkationPair = (embarkation, disembarkation)
      let actions = factory(pair)
      let actionsView = ServiceCardActionsView()
      actionsView.configure(with: actions, model: pair, card: self)
      actionsView.hideSeparator = true
      titleView.accessoryStack.addArrangedSubview(actionsView)
    }

    // Bind outputs
    
    if let title = titleView {
      viewModel.header
        .drive(title.rx.model)
        .disposed(by: disposeBag)
    }
    
    viewModel.header
      .drive(onNext: { [weak self] content in
        guard let self = self else { return }
        if self.headerView == nil {
          self.buildHeader(expanded: !content.alerts.isEmpty, content: content, for: tableView)
        } else if let mini = self.headerView as? TKUIServiceHeaderMiniView {
          mini.configure(with: content)
        } else if let maxi = self.headerView as? TKUIServiceHeaderView {
          maxi.configure(with: content)
        }

      })
      .disposed(by: disposeBag)
    
    toggleHeaderPublisher.withLatestFrom(viewModel.header.asObservable()) { ($0, $1)}
      .subscribe(onNext: { [weak self] expand, content in
        self?.buildHeader(expanded: expand, content: content, for: tableView)
      })
      .disposed(by: disposeBag)
    
    showAlertsPublisher.withLatestFrom(viewModel.header.asObservable()) { ($1) }
      .subscribe(onNext: { [weak self] content in
        self?.showAlerts(content.alerts)
      })
      .disposed(by: disposeBag)

    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // Additional customisations
    
    // When initially populating, scroll to the top, but wait a little
    // while to give the table view a chance to populate itself
    viewModel.sections
      .asObservable()
      .compactMap(TKUIServiceViewModel.embarkationIndexPath)
      .take(1)
      .delay(.milliseconds(250), scheduler: MainScheduler.instance)
      .subscribe(onNext: { indexPath in
        tableView.scrollToRow(at: indexPath, at: .top, animated: false)
      })
      .disposed(by: disposeBag)
    
    scrollToTopPublisher
      .withLatestFrom(viewModel.sections)
      .map(TKUIServiceViewModel.embarkationIndexPath)
      .subscribe(onNext: {
        if let indexPath = $0 {
          tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        }
      })
      .disposed(by: disposeBag)
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
  
}

// MARK: - UITableViewDelegate + Headers

extension TKUIServiceCard: UITableViewDelegate {

  private func buildHeader(expanded: Bool, content: TKUIDepartureCellContent, for tableView: UITableView) {
    if expanded {
      let header = TKUIServiceHeaderView.newInstance()
      header.configure(with: content)

      header.expandyButton.rx.tap
        .subscribe(onNext: { [weak self] in
          self?.toggleHeaderPublisher.onNext(false)
        })
        .disposed(by: disposeBag)
      
      header.alertTapped
        .subscribe(onNext: { [weak self] in
          self?.showAlertsPublisher.onNext(())
        })
        .disposed(by: disposeBag)

      headerView = header
    } else {
      let header = TKUIServiceHeaderMiniView.newInstance()
      header.configure(with: content)

      header.expandyButton.rx.tap
        .subscribe(onNext: { [weak self] in
          self?.toggleHeaderPublisher.onNext(true)
        })
        .disposed(by: disposeBag)
      headerView = header
    }
    
    tableView.reloadData()
  }
  
  public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
    return headerView
  }
  
  public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
    let size = headerView?.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    return size?.height ?? 0
  }
  
  public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    guard scrollView is UITableView else {
      return true
    }
    
    scrollToTopPublisher.onNext(())
    return false
  }
  
}

// MARK: - Alerts

extension TKUIServiceCard {
  
  private func showAlerts(_ alerts: [Alert]) {
    guard !alerts.isEmpty else { return }

    let alertController = TKUIAlertViewController(style: .plain)
    alertController.alerts = alerts
    controller?.present(alertController, inNavigator: true)
  }
  
}
