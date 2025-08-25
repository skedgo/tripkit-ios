//
//  TKUIServiceCard.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

/// A card that lists the route of an individual public transport
/// service. Starts at the provided embarkation and optionally
/// highlights where to get off.
public class TKUIServiceCard: TKUITableCard {
  
  typealias DataSource = UITableViewDiffableDataSource<TKUIServiceViewModel.Section, TKUIServiceViewModel.Item>
  
  public static var config = Configuration.empty
  
  private var dataInput: TKUIServiceViewModel.DataInput
  private var viewModel: TKUIServiceViewModel!
  private var dataSource: DataSource!
  private let serviceMapManager: TKUIServiceMapManager
  private let disposeBag = DisposeBag()
  
  private let itemSelected = PublishSubject<TKUIServiceViewModel.Item>()
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
    
    let style: UITableView.Style
    if #available(iOS 26.0, *) {
      style = .insetGrouped
    } else {
      style = .plain
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
      style: style,
      mapManager: mapManager,
      initialPosition: .peaking
    )
    
    didInit()
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
    
    let dataSource = DataSource(tableView: tableView) { tv, ip, item in
      let cell = tv.dequeueReusableCell(withIdentifier: TKUIServiceVisitCell.reuseIdentifier, for: ip) as! TKUIServiceVisitCell
      cell.configure(with: item)
      if #available(iOS 26.0, *) {
        cell.backgroundColor = .tkBackgroundNotClear
      }
      return cell
    }
    self.dataSource = dataSource
    
    // Build the view model
    
    viewModel = TKUIServiceViewModel(
      dataInput: dataInput,
      itemSelected: itemSelected.asAssertingSignal()
    )
    
    serviceMapManager.viewModel = viewModel
    
    // Setting up actions view
    
    if let titleView = self.titleView, let factory = Self.config.serviceActionsFactory, case let .visits(embarkation, disembarkation) = dataInput {
      let pair: TKUIServiceCard.EmbarkationPair = (embarkation, disembarkation)
      let actions = factory(pair)

      let actionsView = TKUICardActionsViewFactory.build(actions: actions, card: self, model: pair, container: tableView)
      actionsView.backgroundColor = .clear
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
        let alerts = content.alerts
        guard let self, !alerts.isEmpty else { return }

        let alertController = TKUIAlertViewController(style: .plain)
        alertController.alerts = alerts
        self.controller?.present(alertController, inNavigator: true)
      })
      .disposed(by: disposeBag)

    viewModel.sections
      .drive { [weak self, weak tableView] sections in
        guard let self, let tableView else { return }
        self.applySnapshot(for: sections) { [weak tableView] isInitial in
          // When initially populating, scroll to the first embarkation
          guard
            let tableView,
            isInitial,
            let embarkation = TKUIServiceViewModel.embarkationIndexPath(in: sections)
          else { return }
          
          // This sometimes crashes when called too quickly, so we add this
          // delay. Crash is insuide UIKit and look like:
          /*
           #0  (null) in __exceptionPreprocess ()
           #1  (null) in objc_exception_throw ()
           #2  (null) in -[NSAssertionHandler handleFailureInMethod:object:file:lineNumber:description:] ()
           #3  (null) in -[UITableView _createPreparedCellForGlobalRow:withIndexPath:willDisplay:] ()
           #4  (null) in -[UITableView _createPreparedCellForRowAtIndexPath:willDisplay:] ()
           #5  (null) in -[UITableView _heightForRowAtIndexPath:] ()
           #6  (null) in -[UISectionRowData heightForRow:inSection:canGuess:] ()
           #7  (null) in -[UITableViewRowData heightForRow:inSection:canGuess:adjustForReorderedRow:] ()
           #8  (null) in -[UITableViewRowData ensureHeightsFaultedInForScrollToIndexPath:boundsHeight:] ()
           #9  (null) in -[UITableView _contentOffsetForScrollingToRowAtIndexPath:atScrollPosition:usingPresentationValues:] ()
           #10  (null) in -[UITableView _scrollToRowAtIndexPath:atScrollPosition:animated:usingPresentationValues:] ()
           #11  (null) in -[UITableView scrollToRowAtIndexPath:atScrollPosition:animated:] ()
           #12  0x1049081b0 in closure #1 in closure #7 in TKUIServiceCard.didBuild(tableView:) at TKUIServiceCard.swift:195
           */
          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
            tableView.scrollToRow(at: embarkation, at: .top, animated: false)
          }
        }
      }
      .disposed(by: disposeBag)
    
    // Additional customisations
    
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
  
  private func applySnapshot(for sections: [(TKUIServiceViewModel.Section, [TKUIServiceViewModel.Item])], completion: @escaping (Bool) -> Void) {
    let isInitial = dataSource.snapshot().numberOfItems == 0
    
    var snapshot = NSDiffableDataSourceSnapshot<TKUIServiceViewModel.Section, TKUIServiceViewModel.Item>()
    snapshot.appendSections(sections.map(\.0))
    for section in sections {
      snapshot.appendItems(section.1, toSection: section.0)
    }
    
    dataSource.apply(snapshot, animatingDifferences: isInitial) {
      completion(isInitial)
    }
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
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
    itemSelected.onNext(item)
  }
  
}
