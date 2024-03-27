//
//  TKUIRoutingQueryInputCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import MapKit
import SwiftUI

import TGCardViewController
import RxSwift
import RxCocoa

import TripKit

public protocol TKUIRoutingQueryInputCardDelegate: AnyObject {
  func routingQueryInput(card: TKUIRoutingQueryInputCard, selectedOrigin origin: MKAnnotation, destination: MKAnnotation)
}

/// An interactive card for searching for from and to locations.
///
/// Can be used standalone and is also integrated into ``TKUIRoutingResultsCard``.
///
/// When using standalone, you can provide a ``queryDelegate`` to determine what to do
/// when the "Route" button is pressed. Otherwise, a ``TKUIRoutingResultsCard`` will
/// be pushed onto the card stack.
public class TKUIRoutingQueryInputCard: TKUITableCard {
  public weak var queryDelegate: TKUIRoutingQueryInputCardDelegate?
  
  private let origin: MKAnnotation?
  private let destination: MKAnnotation?
  private let biasMapRect: MKMapRect
  var startMode: TKUIRoutingResultsViewModel.SearchMode? = nil
  
  private var viewModel: TKUIRoutingQueryInputViewModel!
  private let didAppear = PublishSubject<Void>()
  private let routeTriggered = PublishSubject<Void>()
  private let accessoryTapped: PublishSubject<TKUIRoutingQueryInputViewModel.Item>?
  private let accessoryCallback = PublishSubject<(MKAnnotation, TKUIRoutingResultsViewModel.SearchMode)>()
  private let disposeBag = DisposeBag()
  
  private let titleView: TKUIRoutingQueryInputTitleView

  public init(origin: MKAnnotation? = nil, destination: MKAnnotation? = nil, biasMapRect: MKMapRect) {
    self.origin = origin
    self.destination = destination
    self.biasMapRect = biasMapRect
    self.titleView = TKUIRoutingQueryInputTitleView.newInstance()
    
    if TKUICustomization.shared.locationInfoTapHandler != nil {
      accessoryTapped = .init()
    } else {
      accessoryTapped = nil
    }
    
    super.init(title: .custom(titleView, dismissButton: titleView.closeButton))
  }
  
  override public func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIAutocompletionViewModel.Section>(
      decideViewTransition: { _, _, _ in
        // Thanks to https://stackoverflow.com/a/59716978
        return UIAccessibility.isReduceMotionEnabled ? .reload : .animated
      },
      configureCell: { [weak accessoryTapped] _, tv, ip, item in
        if #available(iOS 16, *) {
          let cell = tv.dequeueReusableCell(withIdentifier: "plain", for: ip)
          cell.contentConfiguration = UIHostingConfiguration {
            TKUIAutocompletionResultView(item: item) { [weak accessoryTapped] in
              accessoryTapped?.onNext($0)
            }
          }
          return cell
          
        } else {
          guard let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell else {
            preconditionFailure("Couldn't dequeue TKUIAutocompletionResultCell")
          }
          if let accessoryTapped {
            cell.configure(with: item, onAccessoryTapped: { accessoryTapped.onNext($0) })
          } else {
            cell.configure(with: item)
          }
          cell.accessibilityTraits = .button
          return cell
        }
      },
      titleForHeaderInSection: { ds, index in
        return ds.sectionModels[index].title
      }
    )
    
    // Reset to `nil` as we'll overwrite these
    tableView.delegate = nil
    tableView.dataSource = nil

    if #available(iOS 16, *) {
      tableView.register(UITableViewCell.self, forCellReuseIdentifier: "plain")
    } else {
      tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    }
    
    let route = Signal.merge(
      titleView.rx.route,
      routeTriggered.asAssertingSignal()
    )
    
    viewModel = TKUIRoutingQueryInputViewModel(
      origin: origin,
      destination: destination,
      biasMapRect: biasMapRect,
      startMode: startMode,
      inputs: TKUIRoutingQueryInputViewModel.UIInput(
        searchText: titleView.rx.searchText.map { ($0, forced: false) },
        tappedRoute: route,
        selected: selectedItem(in: tableView, dataSource: dataSource),
        selectedSearchMode: titleView.rx.selectedSearchMode,
        tappedSwap: titleView.swapButton.rx.tap.asSignal(),
        accessoryTapped: accessoryTapped?.asAssertingSignal(),
        accessoryCallback: accessoryCallback.asAssertingSignal()
      )
    )
    
    viewModel.activeMode
      .asObservable()
      .observe(on: MainScheduler.asyncInstance) // Avoid reentrancy
      .bind(to: titleView.rx.searchMode)
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
    // as immediately on `didAppear` doesn't work in testing on iOS 13-15.
    didAppear
      .delay(.milliseconds(100), scheduler: MainScheduler.instance)
      .withLatestFrom(viewModel.activeMode)
      .subscribe(onNext: { [weak self] mode in
        guard let self = self else { return }
        self.titleView.didAppear = true
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
    
    viewModel.next
      .emit(onNext: { [weak self] in self?.handle($0) })
      .disposed(by: disposeBag)

    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
  
  public override func willAppear(animated: Bool) {
    super.willAppear(animated: animated)

    if let controller {
      titleView.update(preferredContentSizeCategory: controller.traitCollection.preferredContentSizeCategory)
    }
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))

    self.didAppear.onNext(())
  }
  
  public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    
    if let controller {
      titleView.update(preferredContentSizeCategory: controller.traitCollection.preferredContentSizeCategory)
    }
  }
  
  public override var preferredView: UIView? {
    nil // We'll manage this manually, by letting the search bar become first responder
  }
  
  public override var keyCommands: [UIKeyCommand]? {
    var commands = super.keyCommands ?? []
    
    // ⌘+⏎: Route
    commands.append(UIKeyCommand(title: Loc.Route, image: nil, action: #selector(triggerRoute), input: "\r", modifierFlags: [.command]))
    
    return commands
  }
  
  @objc func triggerRoute() {
    routeTriggered.onNext(())
  }
  
  private func handle(_ next: TKUIRoutingQueryInputViewModel.Next) {
    switch next {
    case let .route(origin, destination):
      if let delegate = self.queryDelegate {
        delegate.routingQueryInput(card: self, selectedOrigin: origin, destination: destination)
      } else {
        let routingResultsCard = TKUIRoutingResultsCard(destination: destination, origin: origin)
        controller?.push(routingResultsCard)
      }
    case let .push(card):
      controller?.push(card, animated: true)
    case let .popBack(select, mode, route):
      controller?.pop(animated: !route) {
        self.accessoryCallback.onNext((select, mode))
      }
    }
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

