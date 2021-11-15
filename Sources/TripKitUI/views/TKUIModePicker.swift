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

// MARK: -
fileprivate enum Constants {
  /// Padding on top of first and below last stack views. Note that the
  /// separatator will pin a the bottom of the view.
  static let viewPaddingVertical: CGFloat   =  8
  
  /// Padding on the left and right of all stack views.
  static let viewPaddingHorizontal: CGFloat = 16
  
  static let modeButtonWidth: CGFloat       = 40
  static let modeButtonSpacing: CGFloat     = 10
  static let modeStackSpacing: CGFloat      =  8
  static let modesPerStackView: Int         =  5
  
  static let separatorHeight: CGFloat       =  1
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
    // liely to be different than the parent view, so to avoid auto
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
    
    collectionView.layoutIfNeeded()
    
    self.collectionViewHeightConstraint.constant = collectionView.collectionViewLayout.collectionViewContentSize.height
    
//    // Clean up
//    subviews.forEach { $0.removeFromSuperview() }
//
//    // This is a "row" of mode icons.
//    var currentModeButtonStackView: UIStackView?
//
//    // This is an array holding all of the above rows of mode icons.
//    var modeButtonStackViews = [UIStackView]()
//
//    // Calculate the number of modes per stack, depending on the available
//    // width
//    let modesPerStack: Int
//    if frame == .zero {
//      modesPerStack = Constants.modesPerStackView
//    } else {
//      let widthPerMode = Constants.modeButtonWidth + Constants.modeButtonSpacing
//      let availableWidth = frame.width - Constants.viewPaddingHorizontal * 2
//      modesPerStack = Int(availableWidth / widthPerMode)
//    }
//
//    for (index, mode) in visibleModes.enumerated() {
//      if (index % modesPerStack) == 0 {
//        // Here we need a new stack view holding another row of mode icons.
//        currentModeButtonStackView = modeButtonStackView()
//        modeButtonStackViews.append(currentModeButtonStackView!)
//      }
//      currentModeButtonStackView?.addArrangedSubview(modeButton(for: mode))
//    }
//
//    // Create equally spaced mode icons in stack that does not have enough modes.
//    if let lastModeButtonStackView = modeButtonStackViews.last {
//      for _ in 0 ..< modesPerStack - lastModeButtonStackView.arrangedSubviews.count {
//        let invisiblePlaceholder = placeholder()
//        invisiblePlaceholder.backgroundColor = .clear
//        lastModeButtonStackView.addArrangedSubview(invisiblePlaceholder)
//      }
//    }
//
//    // Create the stack view that holds all mode image stack views together
//    let combinedStackView = UIStackView()
//    combinedStackView.axis = .vertical
//    combinedStackView.alignment = .fill
//    combinedStackView.distribution = .fillEqually
//    combinedStackView.spacing = Constants.modeStackSpacing
//    combinedStackView.translatesAutoresizingMaskIntoConstraints = false
//    addSubview(combinedStackView)
//
//    combinedStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.viewPaddingVertical).isActive = true
//    combinedStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.viewPaddingHorizontal).isActive = true
//    trailingAnchor.constraint(equalTo: combinedStackView.trailingAnchor, constant: Constants.viewPaddingHorizontal).isActive = true
//    bottomAnchor.constraint(equalTo: combinedStackView.bottomAnchor, constant: Constants.viewPaddingVertical).isActive = true
//
//    // Adding the mode image stack views.
//    modeButtonStackViews.forEach(combinedStackView.addArrangedSubview)
  }
  
  private func modeButtonStackView() -> UIStackView {
    let stackView = UIStackView()
    stackView.axis = .horizontal
    stackView.alignment = .center
    stackView.distribution = .equalSpacing
    stackView.spacing = Constants.modeButtonSpacing
    return stackView
  }
  
  private func templateModeButton() -> UIButton {
    let button = UIButton(type: .custom)
    button.contentMode = .center
    button.heightAnchor.constraint(equalToConstant: Constants.modeButtonWidth).isActive = true
    button.widthAnchor.constraint(equalToConstant: Constants.modeButtonWidth).isActive = true
    return button
  }
  
  private func placeholder() -> UIView {
    let placeholder = UIView()
    placeholder.contentMode = .center
    placeholder.heightAnchor.constraint(equalToConstant: Constants.modeButtonWidth).isActive = true
    placeholder.widthAnchor.constraint(equalToConstant: Constants.modeButtonWidth).isActive = true
    return placeholder
  }
  
  private func modeButton(for item: Item) -> UIButton {
    let button = templateModeButton()
    button.accessibilityLabel = item.imageTextRepresentation
    button.layer.cornerRadius = Constants.modeButtonWidth * 0.5
    
    TKUIModePicker.styleModeButton(button, selected: pickedModes.contains(item))
    
    button.setImage(with: item.imageURL, asTemplate: item.imageURLIsTemplate, placeholder: item.image) { [weak self] gotImage in
      guard let self = self else { return }
      let selected = self.getMode(item)
      TKUIModePicker.styleModeButton(button, selected: selected)
    }
    
    button.rx.controlEvent(.touchDown)
      .subscribe(onNext: { [weak self] in
        self?.show(item: item, above: button)
      })
      .disposed(by: disposeBag)

    Signal.merge([
        button.rx.controlEvent(.touchUpInside).asSignal(),
        button.rx.controlEvent(.touchCancel).asSignal(),
        button.rx.controlEvent(.touchDragExit).asSignal()
      ])
      .emit(onNext: { [weak self] in
        self?.hide(item: item)
      })
      .disposed(by: disposeBag)

    let hover = UIHoverGestureRecognizer()
    hover.rx.event
      .subscribe { [weak self] event in
        guard let self = self, let state = event.element?.state else { return }
        switch state {
        case .began,
             .changed:  self.show(item: item, above: button)
        case .ended:    self.hide(item: item)
        default:        break
        }
      }
      .disposed(by: disposeBag)
    button.addGestureRecognizer(hover)
    
    button.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let self = self, self.isEnabled else { return }
        let newSelected = self.toggleMode(item)
        TKUIModePicker.styleModeButton(button, selected: newSelected)
        
        self.tap.onNext(())
      })
      .disposed(by: disposeBag)
    
    return button
  }
  
  // MARK: - Handling touch up and down
  
  private var labels = [Item: UIView]()
  
  private func show(item: Item, above: UIButton) {
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
  
}

// MARK: - Styling

extension TKUIModePicker {
  
  private static func styleModeButton(_ button: UIButton, selected: Bool) {
    button.backgroundColor    = selected ? .tkBackground : .tkLabelQuarternary
    button.tintColor          = .tkLabelPrimary
    button.alpha              = selected ? 1 : 0.2
    
    if selected {
      button.accessibilityTraits.insert(.selected)
    } else {
      button.accessibilityTraits.remove(.selected)
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

