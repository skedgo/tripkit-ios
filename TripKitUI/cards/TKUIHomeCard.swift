//
//  TKUIHomeCard.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 28/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import RxDataSources

import TGCardViewController

public protocol TKUIHomeCardSearchResultsDelegate: class {
  
  func homeCard(_ card: TKUIHomeCard, selected searchResult: MKAnnotation)
  
}


// MARK: -

public class TKUIHomeCard: TGTableCard {
  
  public var searchProviders: [TKAutocompleting]?
  
  public var searchResultDelegate: TKUIHomeCardSearchResultsDelegate?
  
  private let searchTextPublisher = PublishSubject<String>()
  
  private let searchResultAccessoryTapped = PublishSubject<TKUIAutocompletionViewModel.Item>()
  
  private var searchViewModel: TKUIAutocompletionViewModel!
  
  private let disposeBag = DisposeBag()
  
  private let searchBar = UISearchBar()
  
  init() {
    let mapManager = TKUIMapManager()
    
    // Home card requires a custom title view that includes
    // a search bar only.
    super.init(title: .custom(searchBar, dismissButton: nil), mapManager: mapManager, initialPosition: .peaking)
    
    searchBar.delegate = self
  }
  
  required convenience init?(coder: NSCoder) {
    self.init()
  }
  
  public override func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard let tableView = (cardView as? TGScrollCardView)?.tableView else {
      preconditionFailure()
    }
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIAutocompletionViewModel.Section>(
      configureCell: { [weak self] _, tv, ip, item in
        guard let self = self else {
          // Shouldn't but can happen on dealloc
          return UITableViewCell(style: .default, reuseIdentifier: nil)
        }
        
        guard let cell = tv.dequeueReusableCell(withIdentifier: TKUIAutocompletionResultCell.reuseIdentifier, for: ip) as? TKUIAutocompletionResultCell else {
          preconditionFailure("Couldn't dequeue TKUIAutocompletionResultCell")
        }
        
        cell.configure(with: item, onAccessoryTapped: self.searchResultAccessoryTapped)
        
        return cell
      },
      titleForHeaderInSection: { ds, index in
        return ds.sectionModels[index].title
      }
    )
    
    tableView.register(TKUIAutocompletionResultCell.self, forCellReuseIdentifier: TKUIAutocompletionResultCell.reuseIdentifier)
    
    searchViewModel = TKUIAutocompletionViewModel(
      providers: searchProviders ?? [TKAppleGeocoder(), TKSkedGoGeocoder()],
      searchText: searchTextPublisher.asObserver(),
      selected: tableView.rx.itemSelected.map { dataSource[$0] }.asSignal(onErrorSignalWith: .empty()),
      accessorySelected: searchResultAccessoryTapped.asSignal(onErrorSignalWith: .empty())
    )
    
    searchViewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    searchViewModel.selection
      .emit(onNext: { [weak self] annotation in
        guard let self = self else { return }
        
        // To replicate Apple Maps, once a user dismiss the routing card,
        // the search bar is cleared and the card in which it's embedeed,
        // i.e., Home card, is moved back to the peaking position. To do
        // this, we call `clearSearchBar` method, however, this **must**
        // be called before the routing card is pushed.
        self.clearSearchBar()
        
        // Push the routing card
        self.showRoutes(to: annotation)
        
        // Notify the delegate
        self.searchResultDelegate?.homeCard(self, selected: annotation)
      })
      .disposed(by: disposeBag)
    
    searchViewModel.accessorySelection
      .emit(onNext: { [weak self] annotation in
        guard let stop = annotation as? TKUIStopAnnotation else {
          assertionFailure("Expecting a stop annotation, but got \(annotation)")
          return
        }
        // To replicate Apple Maps, once a user dismiss the timetable card,
        // the search bar is cleared and the card in which it's embedeed,
        // i.e., Home card, is moved back to the peaking position. To do
        // this, we call `clearSearchBar` method, however, this **must**
        // be called before the timetable card is pushed.
        self?.clearSearchBar()
        self?.showTimetable(for: stop)
      })
      .disposed(by: disposeBag)
  }
  
}

// MARK: - Action on search result

extension TKUIHomeCard {
  
  private func showRoutes(to destination: MKAnnotation) {
    // We push the routing card. To replicate Apple Maps, we put
    // the routing card at the peaking position when it's pushed.
    let routingResultCard = TKUIRoutingResultsCard(destination: destination, initialPosition: .peaking)
    controller?.push(routingResultCard)    
  }
  
  private func showTimetable(for stop: TKUIStopAnnotation) {
    // We push the timetable card. To replicate Apple Maps, we put
    // the timetable card at the peaking position when it's pushed.
    let timetableCard = TKUITimetableCard(stops: [stop], reusing: (mapManager as? TKUIMapManager), initialPosition: .peaking)
    controller?.push(timetableCard)
  }
  
}

// MARK: - Search bar

extension TKUIHomeCard: UISearchBarDelegate {
  
  public func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    searchTextPublisher.onNext(searchText)
  }
  
  public func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = true
    self.controller?.moveCard(to: .extended, animated: true)
  }
  
  public func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    searchBar.showsCancelButton = false
  }
  
  public func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    clearSearchBar()
  }
  
  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    self.controller?.moveCard(to: .peaking, animated: true)
  }
  
  private func clearSearchBar() {
    // Clear the text on search bar
    searchBar.text = ""
    
    // Clear the results
    searchTextPublisher.onNext("")
    
    // Dismiss the keyboard
    searchBar.resignFirstResponder()
    
    // We don't need to be extended mode.
    self.controller?.moveCard(to: .peaking, animated: true)
  }
  
}

