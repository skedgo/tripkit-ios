//
//  TKUITimetableAccessoryView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

class TKUITimetableAccessoryView: UIView {

  struct Line: Hashable {
    let text: String
    var color: UIColor? = nil
    var faded: Bool = false
  }
  

  @IBOutlet weak var serviceCollectionView: UICollectionView!
  @IBOutlet weak var serviceCollectionLayout: TKUICollectionViewBubbleLayout!
  @IBOutlet weak var serviceCollectionHeightConstraint: NSLayoutConstraint!
  
  /// Constraint between collection view and bottom bar. Should be activated when `customActionStack` is hidden.
  @IBOutlet weak var serviceCollectionToBottomBarConstraint: NSLayoutConstraint!
  
  @IBOutlet weak var customActionStack: UIStackView!

  @IBOutlet weak var bottomBar: UIView!
  @IBOutlet weak var searchBar: UISearchBar!
  @IBOutlet weak var timeButton: UIButton!
    
  var lines: [Line] = [] {
    didSet {
      serviceCollectionView.reloadData()
      
      serviceCollectionView.bounds = CGRect(x: 0, y: 0, width: bounds.width, height: 200) // .infinity or .max lead to crashes or infinite loops in iOS 13 :(
      serviceCollectionView.layoutIfNeeded()
      serviceCollectionHeightConstraint.constant = serviceCollectionLayout.collectionViewContentSize.height
    }
  }
  
  private var sizingCell: TKUIServiceNumberCell!
  
  static func newInstance() -> TKUITimetableAccessoryView {
    let bundle = Bundle(for: self)
    guard
      let view = bundle.loadNibNamed("TKUITimetableAccessoryView", owner: nil, options: nil)!.first as? TKUITimetableAccessoryView
      else { preconditionFailure() }
    return view
  }
  
  override func awakeFromNib() {
    super.awakeFromNib()
    
    sizingCell = TKUIServiceNumberCell.newInstance()
    serviceCollectionView.register(TKUIServiceNumberCell.nib, forCellWithReuseIdentifier: TKUIServiceNumberCell.reuseIdentifier)
    serviceCollectionView.dataSource = self
    serviceCollectionLayout.delegate = self
    
    customActionStack.isHidden = true
    serviceCollectionToBottomBarConstraint.isActive = true

    bottomBar.backgroundColor = .tkBackgroundSecondary
    
    // Apply default style, removing the search bar's background
    TKStyleManager.style(searchBar, includingBackground: false) { textField in
      textField.backgroundColor = .tkBackground
    }
    searchBar.placeholder = Loc.Search

    timeButton.setTitle(nil, for: .normal)
    timeButton.setImage(.iconChevronDown, for: .normal)
    timeButton.switchImageToOtherSide()
  }
  
  func setCustomActions(_ actions: [TKUITimetableCardAction], for model: [TKUIStopAnnotation], card: TKUITimetableCard) {
    customActionStack.arrangedSubviews.forEach(customActionStack.removeArrangedSubview)
    customActionStack.removeAllSubviews()
    
    customActionStack.isHidden = actions.isEmpty
    serviceCollectionToBottomBarConstraint.isActive = actions.isEmpty
    
    for action in actions {
      let actionView = TKUITimetableActionView.newInstance()
      actionView.imageView.image = action.icon
      actionView.label.text = action.title
      actionView.bold = action.style == .bold
      actionView.onTap = { [weak card, unowned actionView] sender in
        guard let card = card else { return }
        let update = action.handler(card, model, sender)
        if update {
          actionView.imageView.image = action.icon
          actionView.label.text = action.title
        }
      }
      customActionStack.addArrangedSubview(actionView)
    }
  }
  
}

extension TKUITimetableAccessoryView: UICollectionViewDataSource {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return lines.count
  }
  
  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TKUIServiceNumberCell.reuseIdentifier, for: indexPath) as! TKUIServiceNumberCell
    cell.configure(lines[indexPath.item])
    return cell
  }
}

extension TKUITimetableAccessoryView: TKUICollectionViewBubbleLayoutDelegate {
  
  func collectionView(_ collectionView: UICollectionView, itemSizeAt indexPath: IndexPath) -> CGSize {
    sizingCell.configure(lines[indexPath.item])
    sizingCell.layoutIfNeeded()
    sizingCell.sizeToFit()
    return sizingCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
  }
  
}

extension TKUIServiceNumberCell {
  func configure(_ line: TKUITimetableAccessoryView.Line) {
    wrapperView.alpha = line.faded ? 0.2 : 1
    
    numberLabel.text = line.text
    
    let serviceColor = line.color ?? .tkLabelPrimary
    // TODO: This isn't correct if we use model.serviceColor as those aren't dynamic
    let textColor: UIColor = serviceColor.isDark() ? .tkBackground : .tkLabelPrimary
    numberLabel.textColor = textColor
    wrapperView.backgroundColor = serviceColor
  }
}
