//
//  TKUITimetableAccessoryView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.06.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

class TKUITimetableAccessoryView: UIView {
  
  typealias TimetableCardActionsView = TKUICardActionsView<TKUITimetableCard, [TKUIStopAnnotation]>

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
  
  @IBOutlet weak var customActionView: UIView!
  @IBOutlet weak var customActionViewToBottomBarConstraint: NSLayoutConstraint!
  @IBOutlet weak var serviceCollectionToCustomActionViewConstraint: NSLayoutConstraint!
  
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
    
    customActionView.isHidden = true
    customActionViewToBottomBarConstraint.isActive = false
    serviceCollectionToCustomActionViewConstraint.isActive = false
    serviceCollectionToBottomBarConstraint.isActive = true

    bottomBar.backgroundColor = .tkBackgroundSecondary
    
    // Apply default style, removing the search bar's background
    TKStyleManager.style(searchBar, includingBackground: false) { textField in
      textField.backgroundColor = .tkBackground
    }
    searchBar.placeholder = Loc.Search

    timeButton.setTitle(nil, for: .normal)
    timeButton.setImage(.iconChevronTimetable, for: .normal)
    timeButton.tintColor = .tkAppTintColor
  }
  
  func setCustomActions(_ actions: [TKUITimetableCard.Action], for model: [TKUIStopAnnotation], card: TKUITimetableCard) {
    customActionView.subviews.forEach { $0.removeFromSuperview() }
    
    // We deal with empty actions separately here, since it's best to
    // deactivate constraints first before activating. Otherwise, AL
    // will complain about unable to satisfy simultaneously
    if actions.isEmpty {
      customActionView.isHidden = true
      serviceCollectionToCustomActionViewConstraint.isActive = false
      customActionViewToBottomBarConstraint.isActive = false
      serviceCollectionToBottomBarConstraint.isActive = true
    } else {
      customActionView.isHidden = false
      serviceCollectionToBottomBarConstraint.isActive = false
      serviceCollectionToCustomActionViewConstraint.isActive = true
      customActionViewToBottomBarConstraint.isActive = true
      
      let actionView = TimetableCardActionsView(frame: CGRect(x: 0, y: 0, width: frame.width, height: 80))
      actionView.configure(with: actions, model: model, card: card)
      actionView.hideSeparator = true
      customActionView.addSubview(actionView)
      
      actionView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        actionView.leadingAnchor.constraint(equalTo: customActionView.leadingAnchor),
        actionView.topAnchor.constraint(equalTo: customActionView.topAnchor),
        actionView.trailingAnchor.constraint(equalTo: customActionView.trailingAnchor),
        actionView.bottomAnchor.constraint(equalTo: customActionView.bottomAnchor)
      ])
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
    
    if let serviceColor = line.color {
      numberLabel.textColor = serviceColor.isDark ? .tkLabelOnDark : .tkLabelOnLight
      wrapperView.backgroundColor = serviceColor
    } else {
      numberLabel.textColor = .tkBackground
      wrapperView.backgroundColor = .tkLabelPrimary
    }
  }
}