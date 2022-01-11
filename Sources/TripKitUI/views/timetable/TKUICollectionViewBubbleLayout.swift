//
//  TKUICollectionViewBubbleLayout.swift
//  based on MICollectionViewBubbleLayout.swift
//  TripKitUI-iOS
//
//  Created by mac-0007 on 05/12/17.
//  Modified by Adrian Schönig on 10.09.19.
//
//  Copyright © 2017 Jignesh-0007. All rights reserved.
//

import UIKit

protocol TKUICollectionViewBubbleLayoutDelegate: AnyObject {
  func collectionView(_ collectionView: UICollectionView, itemSizeAt indexPath: IndexPath) -> CGSize
}

class TKUICollectionViewBubbleLayout: UICollectionViewFlowLayout {
  
  private let interItemSpacing: CGFloat = 5.0
  private let lineSpacing: CGFloat = 5.0
  
  private var itemAttributesCache = [UICollectionViewLayoutAttributes]()
  private var contentSize: CGSize = .zero
  weak var delegate: TKUICollectionViewBubbleLayoutDelegate?
  
  override var collectionViewContentSize: CGSize {
    return contentSize
  }
  
  // MARK:-
  // MARK:- Initialize
  
  override init() {
    super.init()
    
    scrollDirection = .vertical
    minimumLineSpacing = lineSpacing
    minimumInteritemSpacing = interItemSpacing
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    scrollDirection = .vertical
    minimumLineSpacing = lineSpacing
    minimumInteritemSpacing = interItemSpacing
  }
  
  
  // MARK:-
  // MARK:- Override
  
  override func prepare() {
    super.prepare()
    
    guard
      let collectionView = self.collectionView,
      collectionView.numberOfSections > 0,
      collectionView.numberOfItems(inSection: 0) > 0
      else {
        return
    }
    
    guard
      let delegate = delegate
      else {
        assertionFailure("Didn't yet set delegate. Aborting.")
        return
    }
    
    let isRightToLeft = collectionView.traitCollection.layoutDirection == .rightToLeft
    
    var x: CGFloat = 0
    var y: CGFloat = 0
    var iSize: CGSize = .zero
    
    let numberOfItems = collectionView.numberOfItems(inSection: 0)
    itemAttributesCache = []
    
    let maxWidth = collectionView.frame.width
    
    for index in 0..<numberOfItems {
      let indexPath = IndexPath(item: index, section: 0)
      iSize = delegate.collectionView(collectionView, itemSizeAt: indexPath)
      
      var itemRect = CGRect(x: x, y: y, width: iSize.width, height: iSize.height)
      if (x > 0 && (x + iSize.width + minimumInteritemSpacing > maxWidth)) {
        //... Checking if item width is greater than collection view width then set item in new row.
        itemRect.origin.x = 0
        itemRect.origin.y = y + iSize.height + minimumLineSpacing
      }
      
      let leftyX = itemRect.origin.x
      if isRightToLeft {
        itemRect.origin.x = maxWidth - itemRect.maxX
      }
      
      let itemAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
      itemAttributes.frame = itemRect
      itemAttributesCache.append(itemAttributes)
      
      x = leftyX + iSize.width + minimumInteritemSpacing
      y = itemRect.origin.y
    }
    
    y += iSize.height + self.minimumLineSpacing
    
    contentSize = CGSize(width: maxWidth, height: y)
  }
  
  override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
    return true
  }
  
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    guard let collectionView = self.collectionView else { return nil }

    let numberOfItems = collectionView.numberOfItems(inSection: 0)
    let itemAttributes = itemAttributesCache.filter {
      $0.frame.intersects(rect) && $0.indexPath.row < numberOfItems
    }
    return itemAttributes
  }
  
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    return itemAttributesCache.first { $0.indexPath == indexPath }
  }
}
