//
//  TKUIServiceCard.swift
//  TripGoAppKit
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

import TGCardViewController

/// A card that lists the route of an individual public transport
/// service. Starts at the provided embarkation and optionally
/// highlights where to get off.
public class TKUIServiceCard: TGTableCard {
  
  private var dataInput: TKUIServiceViewModel.DataInput
  private var viewModel: TKUIServiceViewModel!
  private let serviceMapManager: TKUIServiceMapManager
  private let disposeBag = DisposeBag()
  
  private let scrollToTopPublisher = PublishSubject<Void>()

  private let titleView: TKUIServiceTitleView?
  
  /// Configures a new instance that will fetch the service details
  /// and the show them in the list and on the map.
  ///
  /// - Parameters:
  ///   - embarkation: Where to get onto the service
  ///   - disembarkation: Where to get off the service (optional)
  public init(titleView: (UIView, UIButton)? = nil, embarkation: StopVisits, disembarkation: StopVisits? = nil, reusing: TKUITripMapManager? = nil) {
    dataInput = (embarkation, disembarkation)
    
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
  }
  
  required convenience public init?(coder: NSCoder) {
    guard let embarkation: StopVisits = coder.decodeManaged(forKey: "embarkation", in: TripKit.shared.tripKitContext) else {
      return nil
    }
    let disembarkation: StopVisits? = coder.decodeManaged(forKey: "disembarkation", in: TripKit.shared.tripKitContext)
    self.init(embarkation: embarkation, disembarkation: disembarkation)
  }
  
  override public func encode(with aCoder: NSCoder) {
    aCoder.encodeManaged(dataInput.embarkation, forKey: "embarkation")
    aCoder.encodeManaged(dataInput.disembarkation, forKey: "disembarkation")
  }
  
  // MARK: - Card life cycle

  public override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard
      let tableView = (cardView as? TGScrollCardView)?.tableView
      else {
        preconditionFailure()
    }
    
    // Build the view model
    
    viewModel = TKUIServiceViewModel(
      dataInput: dataInput,
      itemSelected: tableView.rx.modelSelected(TKUIServiceViewModel.Item.self).asDriver()
    )
    
    serviceMapManager.viewModel = viewModel

    // Table view configuration
    
    tableView.register(TKUIServiceVisitCell.nib, forCellReuseIdentifier: TKUIServiceVisitCell.reuseIdentifier)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIServiceViewModel.Section>(
      configureCell: { ds, tv, ip, item in
        let cell = tv.dequeueReusableCell(withIdentifier: TKUIServiceVisitCell.reuseIdentifier, for: ip) as! TKUIServiceVisitCell
        cell.configure(with: item)
        return cell
      }
    )
    
    // Bind outputs
    
    if let title = titleView {
      viewModel.header
        .drive(title.rx.model)
        .disposed(by: disposeBag)
    }

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
  
}


// MARK: - Scrolling to embarkation

extension TKUIServiceCard: UITableViewDelegate {
  
  public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    guard scrollView is UITableView else {
      return true
    }
    
    scrollToTopPublisher.onNext(())
    return false
  }
  
}

