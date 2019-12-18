//
//  TKUIRoutingQueryInputCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
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

public protocol TKUIRoutingQueryInputCardDelegate: class {
  func routingQueryInput(card: TKUIRoutingQueryInputCard, selectedOrigin origin: MKAnnotation, destination: MKAnnotation)
}

public class TKUIRoutingQueryInputCard: TGTableCard {
  public weak var queryDelegate: TKUIRoutingQueryInputCardDelegate?
  
  private let origin: MKAnnotation?
  private let destination: MKAnnotation?
  private let biasMapRect: MKMapRect
  
  private var viewModel: TKUIRoutingQueryInputViewModel!
  private let didAppear = PublishSubject<Void>()
  private let disposeBag = DisposeBag()

  private let titleView: TKUIRoutingQueryInputTitleView

  public init(origin: MKAnnotation? = nil, destination: MKAnnotation? = nil, biasMapRect: MKMapRect) {
    
    self.origin = origin
    self.destination = destination
    self.biasMapRect = biasMapRect
    self.titleView = TKUIRoutingQueryInputTitleView.newInstance()
    
    super.init(title: .custom(titleView, dismissButton: titleView.closeButton))
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  override public func didBuild(tableView: UITableView, headerView: TGHeaderView?) {
    super.didBuild(tableView: tableView, headerView: headerView)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIAutocompletionViewModel.Section>(
      configureCell: { _, tv, ip, item in
        guard let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell else {
          preconditionFailure("Couldn't dequeue TKUIAutocompletionResultCell")
        }
        cell.configure(with: item)
        return cell
      },
      titleForHeaderInSection: { ds, index in
        return ds.sectionModels[index].title
      }
    )
    
    // Reset to `nil` as we'll overwrite these
    tableView.delegate = nil
    tableView.dataSource = nil

    tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    
    viewModel = TKUIRoutingQueryInputViewModel(
      origin: origin,
      destination: destination,
      biasMapRect: biasMapRect,
      inputs: TKUIRoutingQueryInputViewModel.UIInput(
        searchText: titleView.rx.searchText,
        tappedDone: titleView.rx.route,
        selected: tableView.rx.modelSelected(TKUIRoutingQueryInputViewModel.Item.self).asSignal(onErrorSignalWith: .empty()),
        selectedSearchMode: titleView.rx.selectedSearchMode,
        tappedSwap: titleView.swapButton.rx.tap.asSignal()
      )
    )
    
    viewModel.activeMode
      .drive(titleView.rx.searchMode)
      .disposed(by: disposeBag)
    
    viewModel.originDestination
      .drive(titleView.rx.originDestination)
      .disposed(by: disposeBag)
    
    viewModel.enableRouteButton
      .drive(titleView.rx.enableRoute)
      .disposed(by: disposeBag)

    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    // Only become first responder once we appeared and after a brief delay,
    // as immediately on `didAppear` doesn't work in testing on iOS 13.
    didAppear
      .delay(.milliseconds(100), scheduler: MainScheduler.instance)
      .withLatestFrom(viewModel.activeMode)
      .subscribe(onNext: { [weak self] mode in
        guard let self = self else { return }
        self.titleView.becomeFirstResponder(mode: mode)
      })
    .disposed(by: disposeBag)

    viewModel.triggerAction
      .asObservable()
      .flatMapLatest { [weak self] action -> Observable<Bool> in
        guard let controller = self?.controller else { return .empty() }
        return action.triggerAdditional(presenter: controller).asObservable()
      }
      .subscribe()
      .disposed(by: disposeBag)
    
    viewModel.selections
      .emit(onNext: { [weak self] origin, destination in
        guard let self = self, let delegate = self.queryDelegate else { return }
        delegate.routingQueryInput(card: self, selectedOrigin: origin, destination: destination)
      })
      .disposed(by: disposeBag)

    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    self.didAppear.onNext(())
  }
}

extension TKUIRoutingQueryInputCard: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)
  }
  
  public func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView.contentOffset.y > 40, !scrollView.isDecelerating {
      // we are actively scrolling a fair bit => disable the keyboard
      _ = titleView.resignFirstResponder()
    }
  }
  
}

