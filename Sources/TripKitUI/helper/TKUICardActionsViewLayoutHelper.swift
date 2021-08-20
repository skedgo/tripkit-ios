//
//  TKUICardActionsViewLayoutHelper.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 6/4/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit

protocol TKUICardActionsViewLayoutHelperDelegate: AnyObject {
  
  func numberOfActionsToDisplay(in collectionView: UICollectionView) -> Int
  
  func actionCellToDisplay(at indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell?
  
  func size(for cell: UICollectionViewCell, at indexPath: IndexPath) -> CGSize?
  
}

class TKUICardActionsViewLayoutHelper: NSObject {
  
  weak var delegate: TKUICardActionsViewLayoutHelperDelegate!
  
  weak var collectionView: UICollectionView!
  
  private let sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
  private let sizingCell = TKUICompactActionCell.newInstance()
  
  init(collectionView: UICollectionView) {
    self.collectionView = collectionView
    
    super.init()
    
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = .clear
    collectionView.register(TKUICompactActionCell.nib, forCellWithReuseIdentifier: TKUICompactActionCell.identifier)
  }
  
}

// MARK: -

extension TKUICardActionsViewLayoutHelper: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate.numberOfActionsToDisplay(in: collectionView)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return delegate.actionCellToDisplay(at: indexPath, in: collectionView) ?? UICollectionViewCell()
  }
  
}

// MARK: -

extension TKUICardActionsViewLayoutHelper: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    #if targetEnvironment(macCatalyst)
    // Ignore, we'll use highlight instead
    #else
    guard
      let cell = collectionView.cellForItem(at: indexPath) as? TKUICompactActionCell,
      let onTapHandler = cell.onTap
      else { return }
    
    if onTapHandler(cell) {
      collectionView.reloadData()
    }
    #endif
  }
  
  func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
    #if targetEnvironment(macCatalyst)
    guard
      let cell = collectionView.cellForItem(at: indexPath) as? TKUICompactActionCell,
      let onTapHandler = cell.onTap
      else { return }
    
    if onTapHandler(cell) {
      collectionView.reloadData()
    }
    #else
    // Ignore, we'll use selected instead
    #endif
  }
  
}

// MARK: -

extension TKUICardActionsViewLayoutHelper: UICollectionViewDelegateFlowLayout {
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return delegate.size(for: sizingCell, at: indexPath) ?? .zero
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInset
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInset.left
  }
  
}
