//
//  TKUIServiceCard.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine

import RxSwift
import RxCocoa
import TGCardViewController

import TripKit

/// A card that lists the route of an individual public transport
/// service. Starts at the provided embarkation and optionally
/// highlights where to get off.
public class TKUIServiceCard: TGHostingCard<TKUIServiceContent> {
  
  public static var config = Configuration.empty
  
  private var dataInput: TKUIServiceViewModel.DataInput
  private let viewModel: TKUIServiceViewModel
  private let serviceMapManager: TKUIServiceMapManager
  private var cancellables = Set<AnyCancellable>()
  
  private let itemSelected = PublishSubject<TKUIServiceViewModel.Item>()

  private let titleView: TKUIServiceTitleView?
  private weak var tableView: UITableView?
  
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
    } else if false {
      let header = TKUIServiceTitleView.newInstance()
      title = .custom(header, dismissButton: header.dismissButton)
      self.titleView = header
    } else {
      title = .default("Departure")
      self.titleView = nil
    }
    
//    let style: UITableView.Style
//    if #available(iOS 26.0, *) {
//      style = .insetGrouped
//    } else {
//      style = .plain
//    }
    
    self.serviceMapManager = TKUIServiceMapManager()
    let mapManager: TGMapManager
    if let trip = reusing {
      mapManager = TKUIComposingMapManager(composing: serviceMapManager, onTopOf: trip)
    } else {
      mapManager = serviceMapManager
    }
    
    // Build the view model
    
    viewModel = TKUIServiceViewModel(
      dataInput: dataInput,
      itemSelected: itemSelected.asAssertingSignal()
    )
    
    serviceMapManager.viewModel = viewModel

    
    super.init(
      title: title,
      rootView: TKUIServiceContent(model: viewModel),
      mapManager: mapManager,
      initialPosition: .peaking
    )
    
    switch self.title {
    case .custom(_, let dismissButton):
      let styledButtonImage = TGCard.closeButtonImage(style: self.style)
      dismissButton?.setImage(styledButtonImage, for: .normal)
      dismissButton?.setTitle(nil, for: .normal)
    default:
      return
    }

    if let knownMapManager = mapManager as? TKUIMapManager {
      knownMapManager.attributionDisplayer = { [weak self] sources, sender in
        let displayer = TKUIAttributionTableViewController(attributions: sources)
        self?.controller?.present(displayer, inNavigator: true, preferredStyle: .popover, sender: sender)
      }
    }
  }
  
  // MARK: - Card life cycle

  public override func didBuild(scrollView: UIScrollView) {
    super.didBuild(scrollView: scrollView)
    
    if #unavailable(iOS 26.0) {
      scrollView.backgroundColor = .tkBackgroundGrouped
    }
    
    if let title = titleView {
      viewModel.headerPublisher
        .compactMap { $0 }
        .sink { title.configure(with: $0) }
        .store(in: &cancellables)
    }

  }

  private func didBuild(tableView: UITableView) {

    self.tableView = tableView
    
    // Table view configuration
    
    tableView.register(TKUIServiceVisitCell.nib, forCellReuseIdentifier: TKUIServiceVisitCell.reuseIdentifier)
    
//    let dataSource = DataSource(tableView: tableView) { tv, ip, item in
//      switch item {
//      case .timing(let timing):
//        let cell = tv.dequeueReusableCell(withIdentifier: TKUIServiceVisitCell.reuseIdentifier, for: ip) as! TKUIServiceVisitCell
//        cell.configure(with: timing)
//        if #available(iOS 26.0, *) {
//          cell.backgroundColor = .tkBackgroundNotClear
//        }
//        return cell
//        
//      case .info(let content):
//        let cell = UITableViewCell()
//        cell.contentConfiguration = UIHostingConfiguration {
//          TKUIServiceInfoView(content: content)
//        }
//        return cell
//      }
//    }
    
    
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
      viewModel.headerPublisher
        .compactMap { $0 }
        .sink { title.configure(with: $0) }
        .store(in: &cancellables)
    }

//    viewModel.sectionsPublisher
//      .sink { [weak self, weak tableView] sections in
//        guard let self, let tableView else { return }
//        self.applySnapshot(for: sections) { [weak tableView] isInitial in
//          // When initially populating, scroll to the first embarkation
//          guard let tableView, isInitial else { return }
//          
//          // This sometimes crashes when called too quickly, so we add this
//          // delay. Crash is insuide UIKit and look like:
//          /*
//           #0  (null) in __exceptionPreprocess ()
//           #1  (null) in objc_exception_throw ()
//           #2  (null) in -[NSAssertionHandler handleFailureInMethod:object:file:lineNumber:description:] ()
//           #3  (null) in -[UITableView _createPreparedCellForGlobalRow:withIndexPath:willDisplay:] ()
//           #4  (null) in -[UITableView _createPreparedCellForRowAtIndexPath:willDisplay:] ()
//           #5  (null) in -[UITableView _heightForRowAtIndexPath:] ()
//           #6  (null) in -[UISectionRowData heightForRow:inSection:canGuess:] ()
//           #7  (null) in -[UITableViewRowData heightForRow:inSection:canGuess:adjustForReorderedRow:] ()
//           #8  (null) in -[UITableViewRowData ensureHeightsFaultedInForScrollToIndexPath:boundsHeight:] ()
//           #9  (null) in -[UITableView _contentOffsetForScrollingToRowAtIndexPath:atScrollPosition:usingPresentationValues:] ()
//           #10  (null) in -[UITableView _scrollToRowAtIndexPath:atScrollPosition:animated:usingPresentationValues:] ()
//           #11  (null) in -[UITableView scrollToRowAtIndexPath:atScrollPosition:animated:] ()
//           #12  0x1049081b0 in closure #1 in closure #7 in TKUIServiceCard.didBuild(tableView:) at TKUIServiceCard.swift:195
//           */
//          DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
//            if let before = TKUIServiceViewModel.beforeEmbarkationIndexPath(in: sections) {
//              tableView.scrollToRow(at: before, at: .top, animated: false)
//            } else if let embarkation = TKUIServiceViewModel.embarkationIndexPath(in: sections) {
//              tableView.scrollToRow(at: embarkation, at: .top, animated: false)
//            }
//          }
//        }
//      }
//      .store(in: &cancellables)

    viewModel.next
      .sink(
        receiveCompletion: { _ in assertionFailure() },
        receiveValue: { [weak self] in self?.handle($0) }
      )
      .store(in: &cancellables)

    // Additional customisations
    
//    tableView.rx.setDelegate(self)
//      .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
  
//  private func applySnapshot(for sections: [TKUIServiceViewModel.Section], completion: @escaping (Bool) -> Void) {
//    let isInitial = dataSource.snapshot().numberOfItems == 0
//    
//    var snapshot = NSDiffableDataSourceSnapshot<TKUIServiceViewModel.SectionGroup, TKUIServiceViewModel.Item>()
//    snapshot.appendSections(sections.map(\.group))
//    for section in sections {
//      snapshot.appendItems(section.items, toSection: section.group)
//    }
//    
//    dataSource.apply(snapshot, animatingDifferences: isInitial) {
//      completion(isInitial)
//    }
//  }
  
  private func handle(_ next: TKUIServiceViewModel.Next) {
    switch next {
    case .showAlerts(let alerts):
      let alertController = TKUIAlertViewController(style: .plain)
      alertController.alerts = alerts
      self.controller?.present(alertController, inNavigator: true)
    }
  }
  
  private func scrollToEmbarkation() {
    guard let tableView, let indexPath = TKUIServiceViewModel.embarkationIndexPath(in: viewModel.sections) else { return }
    tableView.scrollToRow(at: indexPath, at: .top, animated: true)
  }
  
}

// MARK: - UITableViewDelegate + Headers

extension TKUIServiceCard: UITableViewDelegate {

  public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    guard scrollView is UITableView else {
      return true
    }
    
    scrollToEmbarkation()
    return false
  }
  
//  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//    guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
//    itemSelected.onNext(item)
//    
//    tableView.deselectRow(at: indexPath, animated: true)
//  }
  
}

// MARK: - Content

public struct TKUIServiceContent: View {
  @ObservedObject var model: TKUIServiceViewModel
  
  public var body: some View {
    VStack(alignment: .leading) {
      if model.header == nil {
        Text("Loading...")
      } else {
        ForEach(model.sections) { section in
          VStack(alignment: .leading) {
            ForEach(section.items) { item in
              switch item {
              case .info(let content):
                TKUIServiceInfoView(content: content)
                
              case .timing(let content):
                Text("Departure \(content)")
              }
              
            }
          }
          .padding()
          .background(Color(.tkBackgroundNotClear))
          .cornerRadius(22)
        }
      }
    }
    .padding()
    .modify { view in
      if #available(iOS 26.0, *) {
        view
          .background(.clear)
      } else {
        view
          .background(Color(.tkBackgroundGrouped))
      }
    }
    .task {
      try? await model.populate()
    }
  }
}
