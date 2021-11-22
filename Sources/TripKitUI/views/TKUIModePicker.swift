//
//  TKUIModePicker.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 22/5/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift
import TripKit

/// An item that `TKUIModePicker` can display
public protocol TKUIModePickerItem: Hashable {
  
  /// The default image to show for the mode. Items without images are ignored.
  var image: TKImage? { get }
  
  /// A textual representation for the image. Should describe the item. Used for accessibility support.
  var imageTextRepresentation: String { get }
  
  /// An optional URL to an image to replace the default image
  var imageURL: URL? { get }
  
  /// Whether `imageURL` points at an image that can be used in template mode
  var imageURLIsTemplate: Bool { get }
  
  /// Whether `imageURL` points at a branding image.
  var imageURLIsBranding: Bool { get }
  
}

/// Displays a list of items that the user can toggle on and off.
///
/// Call the `configure` method to set the available items, then attach to `rx_pickModes` to listen to changes
/// of the user tapping on items.
public class TKUIModePicker<Item>: UIView where Item: TKUIModePickerItem {
  
  private let disposeBag = DisposeBag()
  
  private var visibleModes: [Item] = []
  
  public weak var containerView: UIView?
  
  private weak var collectionView: UICollectionView!
  private weak var collectionViewHeightConstraint: NSLayoutConstraint!
  private var layoutHelper: TKUIModePickerLayoutHelper?

  /// Whether user can enable/disable modes
  public var isEnabled: Bool = true
  
  private var lastTappedItem: Item?
  
  public init() {
    super.init(frame: .zero)
    prepareCollectionView()
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  private func prepareCollectionView() {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.showsVerticalScrollIndicator = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(collectionView)
    
    // We need to give the collection view a height constraint, or
    // its content won't be loaded properly. This initial height is
    // likely to be different than the parent view, so to avoid auto
    // layout warning, we reduce its priority.
    let heightConstraint = collectionView.heightAnchor.constraint(equalToConstant: 100)
    heightConstraint.priority = .init(rawValue: 999)
    self.collectionViewHeightConstraint = heightConstraint
    
    NSLayoutConstraint.activate([
      heightConstraint,
      collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
      collectionView.topAnchor.constraint(equalTo: topAnchor),
      trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
      bottomAnchor.constraint(equalTo: collectionView.bottomAnchor)
    ])
    
    let longTap = UILongPressGestureRecognizer(target: self, action: #selector(handleLongTap))
    longTap.delaysTouchesBegan = true
    longTap.minimumPressDuration = 0.25
    collectionView.addGestureRecognizer(longTap)
    
    self.collectionView = collectionView
    
    // `TKUIModePicker` is a generic class, so it cannot be the data source and
    // delegate for the collection view. Hence, we use a helper class to manage
    // its layout.
    let layoutHelper = TKUIModePickerLayoutHelper(collectionView: collectionView, delegate: self)
    self.layoutHelper = layoutHelper
  }
  
  /// Configures the currently visible items
  ///
  /// - Note: you can call `configure` multiple times with different sets of items. The mode picker will keep track
  ///     of which items were previously selected (or not) and maintains that information even if the items are
  ///     temporarily removed from the `configure` method's `modes`.
  ///
  /// - Important: you must set a desired width for the mode picker **before** calling this method, otherwise,
  ///       the number of modes per row will not be calculated properly. 
  ///
  /// - Parameters:
  ///   - modes: These are all the available/visible modes
  ///   - currentlyEnabled:  Optional handler to check if an item should be enabled; by default all are enabled
  public func configure(all modes: [Item], updateAll: Bool = false, currentlyEnabled: (Item) -> Bool = { _ in true }) {

    // Need to set this first, as updating modes will trigger the observable
    visibleModes = modes

    // For any new modes, use the visibility as determined by the handler
    var toggled = self.toggledModes
    for mode in modes where updateAll || !seenModes.contains(mode) {
      seenModes.insert(mode)
      if currentlyEnabled(mode) {
        toggled.insert(mode)
      } else {
        toggled.remove(mode)
      }
    }
    toggledModes = toggled
    
    // Must be called after `pickedModes` is set, so mode icon can be dimmed
    // properly.
    updateUI()
  }
  
  // MARK: - Configuration
  
  private func updateUI() {
    guard visibleModes.count > 0 else { return }
    collectionView.reloadData()
    
    // Once the collection view has loaded its content, we do a layout pass
    // and adjust its height, so the caller of `TKUIModePicker` can get the
    // right size to work with, e.g., embedding in a table view header.
    collectionView.layoutIfNeeded()
    self.collectionViewHeightConstraint.constant = collectionView.collectionViewLayout.collectionViewContentSize.height
  }
  
  // MARK: - Handling touch up and down
  
  private var labels = [Item: UIView]()
  
  private func show(item: Item, above: UIView) {
    guard let containerView = self.containerView else { return }
    guard labels[item] == nil else { return }
    
    let enabled = getMode(item)

    self.clipsToBounds = false

    let wrapper = UIView()
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    wrapper.backgroundColor = .tkBackground
    wrapper.layer.cornerRadius = 4
    labels[item] = wrapper
    
    let modeImageView = UIImageView()
    modeImageView.setImage(with: item.imageURL, asTemplate: item.imageURLIsTemplate, placeholder: item.image)
    modeImageView.backgroundColor = .clear
    modeImageView.translatesAutoresizingMaskIntoConstraints = false
    modeImageView.alpha = enabled ? 1 : 0.2
    wrapper.addSubview(modeImageView)
    
    let modeNameLabel = UILabel()
    modeNameLabel.backgroundColor = .clear
    modeNameLabel.textColor = .tkLabelSecondary
    modeNameLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .subheadline)
    modeNameLabel.text = item.imageTextRepresentation
    modeNameLabel.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(modeNameLabel)
    
    let statusLabel = UILabel()
    statusLabel.backgroundColor = .clear
    statusLabel.textColor = enabled ? .tkStateSuccess : .tkStateError
    statusLabel.font = TKStyleManager.boldCustomFont(forTextStyle: .footnote)
    statusLabel.text = enabled ? Loc.Enabled : Loc.Disabled
    statusLabel.translatesAutoresizingMaskIntoConstraints = false
    wrapper.addSubview(statusLabel)
    
    NSLayoutConstraint.activate([
      modeImageView.centerYAnchor.constraint(equalTo: wrapper.centerYAnchor),
      modeNameLabel.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 8),
      statusLabel.topAnchor.constraint(equalTo: modeNameLabel.bottomAnchor, constant: 4),
      wrapper.bottomAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 8),

      modeImageView.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 16),
      modeNameLabel.leadingAnchor.constraint(equalTo: modeImageView.trailingAnchor, constant: 16),
      modeNameLabel.leadingAnchor.constraint(equalTo: statusLabel.leadingAnchor),
      modeNameLabel.trailingAnchor.constraint(equalTo: statusLabel.trailingAnchor),
      wrapper.trailingAnchor.constraint(equalTo: modeNameLabel.trailingAnchor, constant: 24)
    ])
    
    wrapper.layer.shadowColor = UIColor.tkLabelPrimary.cgColor
    wrapper.layer.shadowOpacity = 0.2
    wrapper.layer.shadowRadius = 16

    containerView.addSubview(wrapper)
    above.topAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: 8).isActive = true
    
    let center = wrapper.centerXAnchor.constraint(equalTo: above.centerXAnchor)
    center.priority = .defaultHigh
    center.isActive = true
    
    wrapper.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor).isActive = true
    containerView.trailingAnchor.constraint(greaterThanOrEqualTo: wrapper.trailingAnchor).isActive = true
    
    wrapper.setNeedsLayout()
    wrapper.layoutIfNeeded()
    wrapper.layer.cornerRadius = wrapper.bounds.height / 2
  }
  
  private func hide(item: Item) {
    guard let label = labels[item] else { return }
    label.removeFromSuperview()
    labels[item] = nil
    lastTappedItem = nil
  }
  
  // MARK: - Handling tap on mode icons

  func getMode(_ mode: Item) -> Bool {
    return toggledModes.contains(mode)
  }

  func toggleMode(_ mode: Item) -> Bool {
    let selected = toggledModes.contains(mode)
    guard isEnabled else { return selected }

    setMode(mode, selected: !selected)
    return !selected
  }
  
  func setMode(_ mode: Item, selected: Bool) {
    guard isEnabled else { return }

    if selected {
      toggledModes.insert(mode)
    } else {
      toggledModes.remove(mode)
    }
  }
  
  /// For keeping track of what modes we've encountered before, i.e., if a mode
  /// disappears and then re-appears, we'll remember its toggled state.
  private var seenModes: Set<Item> = []

  /// For keeping track of what modes a user has toggled on/off before. This is
  /// all the enabled modes, even though they might not currently be visible,
  /// i.e., they are not in `modes`.
  private var toggledModes: Set<Item> = []
  
  private let tap = PublishSubject<Void>()

  public var rx_pickedModes: Signal<Set<Item>> {
    return tap
      .map { [weak self] in self?.pickedModes ?? [] }
      .asSignal(onErrorSignalWith: .empty())
  }
  
  /// Visible modes that are currently enabled
  var pickedModes: Set<Item> {
    get {
      return toggledModes.filter(visibleModes.contains)
    }
  }
  
  @objc func handleLongTap(gestureRecognizer: UILongPressGestureRecognizer) {
    let touchPoint = gestureRecognizer.location(in: collectionView)
    
    switch gestureRecognizer.state {
    case .began, .changed:
      guard
        let indexPath = collectionView.indexPathForItem(at: touchPoint),
        let cell = collectionView.cellForItem(at: indexPath) else {
          if let lastTapped = self.lastTappedItem {
            hide(item: lastTapped)
          }
          return
        }
      
      let tappedItem = visibleModes[indexPath.row]
      if let lastTapped = self.lastTappedItem, lastTapped != tappedItem {
        hide(item: lastTapped)
      }
      show(item: tappedItem, above: cell)
      self.lastTappedItem = tappedItem
      
    default:
      if let lastTapped = self.lastTappedItem {
        hide(item: lastTapped)
      }
    }
  }
  
}

// MARK: - Layout

extension TKUIModePicker: TKUIModePickerLayoutHelperDelegate {
  
  func numberOfModesToDisplay(in collectionView: UICollectionView) -> Int {
    return visibleModes.count
  }
  
  func pickerCellToDisplay(at indexPath: IndexPath, in collectionView: UICollectionView) -> TKUIModePickerCell {
    assert(indexPath.row < visibleModes.count, "attempted to display a non-existent mode")
    
    let item = visibleModes[indexPath.row]
    
    let pickerCell = collectionView.dequeueReusableCell(withReuseIdentifier: TKUIModePickerCell.reuseIdentifier, for: indexPath) as! TKUIModePickerCell
    configure(pickerCell: pickerCell, with: item, asSelected: pickedModes.contains(item))
    
    return pickerCell
  }
  
  func size(for pickerCell: TKUIModePickerCell, at indexPath: IndexPath) -> CGSize {
    assert(indexPath.row < visibleModes.count, "attempted to display a non-existent mode")
    
    let item = visibleModes[indexPath.row]
    configure(pickerCell: pickerCell, with: item, asSelected: pickedModes.contains(item))
    pickerCell.layoutIfNeeded()
    return pickerCell.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
  }
  
  func selectedItem(at indexPath: IndexPath, in collectionView: UICollectionView) {
    guard isEnabled, indexPath.row < visibleModes.count else { return }
    
    let item = visibleModes[indexPath.row]
    let newSelected = toggleMode(item)
    
    if let pickerCell = collectionView.cellForItem(at: indexPath) as? TKUIModePickerCell {
      style(pickerCell: pickerCell, asSelected: newSelected)
    }
    
    self.tap.onNext(())
  }
  
}

// MARK: - Cell

extension TKUIModePicker {
  
  func configure(pickerCell: TKUIModePickerCell, with item: Item, asSelected selected: Bool) {
    pickerCell.accessibilityLabel = item.imageTextRepresentation
    
    style(pickerCell: pickerCell, asSelected: selected)
    
    if let remoteImageURL = item.imageURL, item.imageURLIsBranding {
      pickerCell.rightImageView.setImage(with: remoteImageURL)
      pickerCell.leftImageView.image = item.image
      pickerCell.hideRightImage(false)
    } else {
      pickerCell.leftImageView.setImage(with: item.imageURL, asTemplate: item.imageURLIsTemplate, placeholder: item.image, completion: nil)
      pickerCell.hideRightImage(true)
    }
    
    let selected = self.getMode(item)
    self.style(pickerCell: pickerCell, asSelected: selected)
  }
  
  func style(pickerCell: TKUIModePickerCell, asSelected selected: Bool) {
    pickerCell.contentWrapper.backgroundColor = selected ? .tkBackground : .tkLabelQuarternary
    pickerCell.contentWrapper.alpha = selected ? 1 : 0.2
    pickerCell.tintColor = .tkLabelPrimary
    
    if selected {
      pickerCell.accessibilityTraits.insert(.selected)
    } else {
      pickerCell.accessibilityTraits.remove(.selected)
    }
  }
  
}

