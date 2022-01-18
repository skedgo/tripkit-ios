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
  
  func hoverChanged(isActive: Bool, at indexPath: IndexPath?, in collectionView: UICollectionView)
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
  
  #if targetEnvironment(macCatalyst)
  @objc
  func tapped(sender: UITapGestureRecognizer) {
    guard let collectionView = collectionView else { return }
    let point = sender.location(in: collectionView)
    if let indexPath = collectionView.indexPathForItem(at: point) {
      delegate.selectedItem(at: indexPath, in: collectionView)
    }
  }
  
  @objc
  func hover(sender: UIHoverGestureRecognizer) {
    guard let collectionView = collectionView else { return }
    let point = sender.location(in: collectionView)
    if let indexPath = collectionView.indexPathForItem(at: point) {
      switch sender.state {
      case .began:
        delegate.hoverChanged(isActive: true, at: indexPath, in: collectionView)
      case .ended, .cancelled, .failed:
        delegate.hoverChanged(isActive: false, at: indexPath, in: collectionView)
      default:
        break
      }
    } else {
      delegate.hoverChanged(isActive: false, at: nil, in: collectionView)
    }
  }

  #endif
  
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return delegate.numberOfModesToDisplay(in: collectionView)
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let pickerCell = delegate.pickerCellToDisplay(at: indexPath, in: collectionView)
      
    #if targetEnvironment(macCatalyst)
    if (pickerCell.gestureRecognizers ?? []).isEmpty {
      // For some reason, the 'did select' delegate callback won't fire on
      // Mac Catalyst, so we immitate that manually.
      let tapper = UITapGestureRecognizer(target: self, action: #selector(tapped(sender:)))
      pickerCell.addGestureRecognizer(tapper)
      
      let hover = UIHoverGestureRecognizer(target: self, action: #selector(hover(sender:)))
      pickerCell.addGestureRecognizer(hover)
    }
    #endif
    
    return pickerCell
  }
  
}

// MARK: - Delegate

extension TKUIModePickerLayoutHelper: UICollectionViewDelegate {
  
  func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    delegate.selectedItem(at: indexPath, in: collectionView)
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
