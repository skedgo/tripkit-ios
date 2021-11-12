//
//  TKUIModePickerLayoutHelper.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 12/11/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import TripKit

protocol TKUIModePickerLayoutHelperDelegate: AnyObject {
  
  func numberOfModesToDisplay(in collectionView: UICollectionView) -> Int
  
  func pickerCellToDisplay(at indexPath: IndexPath, in collectionView: UICollectionView) -> TKUIModePickerCell
  
  func size(for pickerCell: TKUIModePickerCell, at indexPath: IndexPath) -> CGSize
  
  func selectedItem(at indexPath: IndexPath, in collectionView: UICollectionView)
  
}

class TKUIModePickerLayoutHelper: NSObject {
  
  weak var delegate: TKUIModePickerLayoutHelperDelegate!
  
  weak var collectionView: UICollectionView!
  
  private let sectionInset: UIEdgeInsets = .init(top: 8, left: 8, bottom: 8, right: 8)
  private let sizingCell = TKUIModePickerCell.newInstance()
  
  init(collectionView: UICollectionView, delegate: TKUIModePickerLayoutHelperDelegate) {
    self.collectionView = collectionView
    self.delegate = delegate
    
    super.init()
    
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.backgroundColor = .clear
    collectionView.register(TKUIModePickerCell.nib, forCellWithReuseIdentifier: TKUIModePickerCell.reuseIdentifier)
  }
  
}

// MARK: - Data source

extension TKUIModePickerLayoutHelper: UICollectionViewDataSource {
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate.numberOfModesToDisplay(in: collectionView)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    return delegate.pickerCellToDisplay(at: indexPath, in: collectionView)
  }
  
}

// MARK: - Delegate

extension TKUIModePickerLayoutHelper: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    delegate.selectedItem(at: indexPath, in: collectionView)
  }
  
  func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
    TKLog.info("Picker", text: "did highlight")
  }
  
}

// MARK: - Layout

extension TKUIModePickerLayoutHelper: UICollectionViewDelegateFlowLayout {

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return delegate.size(for: sizingCell, at: indexPath)
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
    return sectionInset
  }
  
  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
    return sectionInset.left
  }

}
