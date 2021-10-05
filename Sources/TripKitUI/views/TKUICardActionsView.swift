//
//  TKUICardActionsView.swift
//  TripKitUI-iOS
//
//  Created by Brian Huang on 4/3/20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TGCardViewController

public class TKUICardActionsView<C, M>: UIView where C: TGCard {
  
  public var showActionTitleInCompactLayout: Bool?
  
  private var separator: UIView?
  
  public var hideSeparator: Bool = false {
    didSet {
      separator?.isHidden = hideSeparator
    }
  }
  
  private var actions: [TKUICardAction<C, M>]?
  private var model: M?
  private weak var card: C?
  
  private var compactLayoutHelper: TKUICardActionsViewLayoutHelper?
  
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }
  
  public func configure(with actions: [TKUICardAction<C, M>], model: M, card: C) {
    self.actions = actions
    self.card = card
    self.model = model
    
    subviews.forEach { $0.removeFromSuperview() }
    
    backgroundColor = .clear
    
    if actions.count > 2 || TKUICustomization.shared.forceCompactActionsLayout {
      useCompactLayout(in: card, for: actions, with: model)
    } else {
      useExtendedLayout(in: card, for: actions, with: model)
    }
  }
  
}

extension TKUICardActionsView {
  
  private func addSeparator() {
    let separator = UIView()
    separator.backgroundColor = .tkSeparatorSubtle
    addSubview(separator)
    self.separator = separator
    
    separator.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      separator.leadingAnchor.constraint(equalTo: leadingAnchor),
      separator.bottomAnchor.constraint(equalTo: bottomAnchor),
      separator.trailingAnchor.constraint(equalTo: trailingAnchor),
      separator.heightAnchor.constraint(equalToConstant: 0.5)
    ])
  }
  
  private func useCompactLayout<C, M>(in card: C, for actions: [TKUICardAction<C, M>], with model: M) {
    addSeparator()
    
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = false
    let layoutHelper = TKUICardActionsViewLayoutHelper(collectionView: collectionView)
    layoutHelper.delegate = self
    self.compactLayoutHelper = layoutHelper
    addSubview(collectionView)
    
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    
    // We need to give the collection view a height constraint, or
    // its content won't be loaded properly. This initial height is
    // liely to be different than the parent view, so to avoid auto
    // layout warning, we reduce its priority.
    let collectionViewHeightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100)
    collectionViewHeightConstraint.priority = UILayoutPriority(999)
    
    NSLayoutConstraint.activate([
        collectionViewHeightConstraint,
        collectionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
        collectionView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
        trailingAnchor.constraint(equalTo: collectionView.trailingAnchor, constant: 8),
        bottomAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 8),
      ]
    )
    
    // Reload the collection view so it has the correct number of
    // items to calculate its content size.
    collectionView.reloadData()
    
    // This causes the collection view to have the right size.
    collectionView.layoutIfNeeded()
    
    // Now update the height constraint to the proper value
    collectionViewHeightConstraint.constant = collectionView.collectionViewLayout.collectionViewContentSize.height
  }
  
  private func useExtendedLayout<C, M>(in card: C, for actions: [TKUICardAction<C, M>], with model: M) {
    addSeparator()
    
    var previousActionView: UIView?
    
    for (index, action) in actions.enumerated() {
      let actionView = TKUIExtendedActionView.newInstance()
      actionView.tintColor = .tkAppTintColor
      actionView.imageView.image = action.icon
      actionView.label.text = action.title
      actionView.wrapper.isAccessibilityElement = true
      actionView.wrapper.accessibilityLabel = action.title
      actionView.wrapper.accessibilityTraits = .button
      actionView.bold = action.style == .bold
      actionView.onTap = { [weak card, unowned actionView] sender in
        guard let card = card else { return }
        let update = action.handler(action, card, model, sender)
        if update {
          actionView.imageView.image = action.icon
          actionView.label.text = action.title
          actionView.accessibilityLabel = action.title
          actionView.bold = action.style == .bold
        }
      }
      
      addSubview(actionView)
      
      actionView.translatesAutoresizingMaskIntoConstraints = false
      if index == 0 {
        actionView.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true
        actionView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true
        actionView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
      } else {
        guard let previous = previousActionView else { preconditionFailure() }
        actionView.leadingAnchor.constraint(equalTo: previous.trailingAnchor, constant: 8).isActive = true
        actionView.topAnchor.constraint(equalTo: previous.topAnchor).isActive = true
        actionView.bottomAnchor.constraint(equalTo: previous.bottomAnchor).isActive = true
        actionView.centerYAnchor.constraint(equalTo: previous.centerYAnchor).isActive = true
        let widthConstraint = actionView.widthAnchor.constraint(equalTo: previous.widthAnchor)
        widthConstraint.priority = .defaultLow
        widthConstraint.isActive = true
      }
      
      if index == actions.count - 1 {
        actionView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
      }
      
      previousActionView = actionView
    }
  }
  
}

// MARK: -

extension TKUICompactActionCell {
  
  func configure<C, M>(with action: TKUICardAction<C, M>, card: C, model: M, showTitle: Bool = true) {
    tintColor = .tkAppTintColor
    accessibilityLabel = action.title
    accessibilityTraits = .button
    imageView.image = action.icon
    titleLabel.text = showTitle ? action.title : nil
    bold = action.style == .bold
    onTap = { [weak card, unowned self] sender in
      guard let card = card else { return false }
      let update = action.handler(action, card, model, sender)
      if update {
        self.imageView.image = action.icon
        self.titleLabel.text = showTitle ? action.title : nil
        self.accessibilityLabel = action.title
        self.bold = action.style == .bold
      }
      return update
    }
  }
  
}

// MARK: -

extension TKUICardActionsView: TKUICardActionsViewLayoutHelperDelegate {
  
  func numberOfActionsToDisplay(in collectionView: UICollectionView) -> Int {
    return self.actions?.count ?? 0
  }
  
  func actionCellToDisplay(at indexPath: IndexPath, in collectionView: UICollectionView) -> UICollectionViewCell? {
    guard
      let action = self.actions?[indexPath.row],
      let card = self.card,
      let model = self.model
      else { return nil }
    
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TKUICompactActionCell.identifier, for: indexPath) as! TKUICompactActionCell
    cell.configure(with: action, card: card, model: model)
    return cell
  }
  
  func size(for cell: UICollectionViewCell, at indexPath: IndexPath) -> CGSize? {
    guard
      let actionCell = cell as? TKUICompactActionCell,
      let action = self.actions?[indexPath.row],
      let card = self.card,
      let model = self.model
      else { return nil }
    
    actionCell.configure(with: action, card: card, model: model)
    actionCell.layoutIfNeeded()
    return actionCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
  }
  
}
