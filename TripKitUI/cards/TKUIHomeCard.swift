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

public class TKUIHomeCard: TGTableCard {
  
  public var searchProviders: [TKAutocompleting]?
  
  private let searchTextPublisher = PublishSubject<String>()
  
  private let searchResultAccessoryTapped = PublishSubject<TKUIAutocompletionViewModel.Item>()
  
  private var searchViewModel: TKUIAutocompletionViewModel!
  
  private let disposeBag = DisposeBag()
  
  init() {
    let mapManager = TKUIMapManager()
    
    // Home card requires a custom title view that includes
    // a search bar only.
    let searchBar = UISearchBar()
    
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
      selected: tableView.rx.itemSelected.map { dataSource[$0] }.asSignal(onErrorSignalWith: .empty())
    )
    
    searchViewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    searchViewModel.selection
      .emit(onNext: { annotation in
        print("selected annotation: \(annotation)")
      })
      .disposed(by: disposeBag)
    
    searchViewModel.accessorySelection
      .emit(onNext: { annotation in
        print("accessory tapped for annotation: \(annotation)")
      })
      .disposed(by: disposeBag)
  }
  
}

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
    // Clear the text on search bar
    searchBar.text = ""
    
    // Clear the results
    searchTextPublisher.onNext("")
    
    // Dismiss the keyboard
    searchBar.resignFirstResponder()
    
    // We don't need to be extended mode.
    self.controller?.moveCard(to: .peaking, animated: true)
  }
  
  public func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    searchBar.resignFirstResponder()
    self.controller?.moveCard(to: .peaking, animated: true)
  }
  
}

