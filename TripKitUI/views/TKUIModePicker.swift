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

  /// Whether `imageURL` points at an image which should not be displayed on coloured background
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
  
  private var modeIsBranded: [Item: Bool] = [:]

  /// Configures the currently visible items
  ///
  /// - Note: you can call `configure` multiple times with different sets of items. The mode picker will keep track
  ///     of which items were previously selected (or not) and maintains that information even if the items are
  ///     temporarily removed from the `configure` method's `modes`
  ///
  /// - Parameters:
  ///   - modes: These are all the available/visible modes
  ///   - currentlyEnabled:  Optional handler to check if an item should be enabled; by default all are enabled
  public func configure(all modes: [Item], updateAll: Bool = false, currentlyEnabled: (Item) -> Bool = { _ in true }) {

    // Need to set this first, as updating modes will trigger the observable
    visibleModes = modes

    // For any new modes, use the visibility as determined by the handler
    for mode in modes where updateAll || !seenModes.contains(mode) {
      seenModes.insert(mode)
      if currentlyEnabled(mode) {
        toggledModes.insert(mode)
      } else {
        toggledModes.remove(mode)
      }
    }
    
    // Must be called after `pickedModes` is set, so mode icon can be dimmed
    // properly.
    updateUI()
    
    if let container = superview {
      self.frame.size.width = container.frame.width
      container.frame.size.height = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    }
  }
  
  // MARK: - Configuration
  
  private func updateUI() {
    guard visibleModes.count > 0 else { return }
    
    // Clean up
    removeAllSubviews()
    
    // This is a "row" of mode icons.
    var currentModeButtonStackView: UIStackView?
    
    // This is an array holding all of the above rows of mode icons.
    var modeButtonStackViews = [UIStackView]()

    // Calculate the number of modes per stack, depending on the available
    // width
    let modesPerStack: Int
    if let container = superview {
      let widthPerMode = Constants.modeButtonWidth + Constants.modeButtonSpacing
      modesPerStack = Int(container.bounds.width / widthPerMode)
    } else {
      modesPerStack = Constants.modesPerStackView
    }

    for (index, mode) in visibleModes.enumerated() {
      if (index % modesPerStack) == 0 {
        // Here we need a new stack view holding another row of mode icons.
        currentModeButtonStackView = modeButtonStackView()
        modeButtonStackViews.append(currentModeButtonStackView!)
      }
      currentModeButtonStackView?.addArrangedSubview(modeButton(for: mode))
    }
    
    // This is a hacky way to create equally spaced mode icons in stack
    // that does not have enough modes.
    if let lastModeButtonStackView = modeButtonStackViews.last {
      for _ in 0 ..< modesPerStack - lastModeButtonStackView.arrangedSubviews.count {
        let hiddenModeButtonView = templateModeButton()
        hiddenModeButtonView.backgroundColor = .clear
        hiddenModeButtonView.isUserInteractionEnabled = false
        lastModeButtonStackView.addArrangedSubview(hiddenModeButtonView)
      }
    }
    
    // Create the stack view that holds all mode image stack views together
    let combinedStackView = UIStackView()
    combinedStackView.axis = .vertical
    combinedStackView.alignment = .fill
    combinedStackView.distribution = .fillEqually
    combinedStackView.spacing = Constants.modeStackSpacing
    combinedStackView.translatesAutoresizingMaskIntoConstraints = false
    addSubview(combinedStackView)
    
    combinedStackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.viewPaddingVertical).isActive = true
    combinedStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.viewPaddingHorizontal).isActive = true
    trailingAnchor.constraint(equalTo: combinedStackView.trailingAnchor, constant: Constants.viewPaddingHorizontal).isActive = true
    
    // Adding the mode image stack views.
    modeButtonStackViews.forEach {
      combinedStackView.addArrangedSubview($0)
    }
    
    // Add separator
    let separator = UIView()
    separator.translatesAutoresizingMaskIntoConstraints = false
    separator.backgroundColor = #colorLiteral(red: 0.8196078431, green: 0.8196078431, blue: 0.831372549, alpha: 1)
    addSubview(separator)
    
    separator.heightAnchor.constraint(equalToConstant: Constants.separatorHeight).isActive = true
    separator.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
    trailingAnchor.constraint(equalTo: separator.trailingAnchor).isActive = true
    separator.topAnchor.constraint(equalTo: combinedStackView.bottomAnchor, constant: Constants.viewPaddingVertical).isActive = true
    bottomAnchor.constraint(equalTo: separator.bottomAnchor).isActive = true    
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
  
  private func modeButton(for mode: Item) -> UIButton {
    let button = templateModeButton()
    button.accessibilityLabel = mode.imageTextRepresentation
    button.layer.cornerRadius = Constants.modeButtonWidth * 0.5
    
    TKUIModePicker.styleModeButton(button, selected: pickedModes.contains(mode))
    
    button.setImage(with: mode.imageURL, asTemplate: mode.imageURLIsTemplate, placeholder: mode.image) { [weak self] gotImage in
      guard let self = self else { return }
      self.modeIsBranded[mode] = gotImage
      let selected = self.getMode(mode)
      TKUIModePicker.styleModeButton(button, selected: selected, isBranded: mode.imageURLIsBranding && gotImage)
    }
    
    button.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        let newSelected = self.toggleMode(mode)
        let isBranded = self.modeIsBranded[mode] ?? false
        TKUIModePicker.styleModeButton(button, selected: newSelected, isBranded: mode.imageURLIsBranding && isBranded)
      })
      .disposed(by: disposeBag)
    
    return button
  }
  
  // MARK: - Handling tap on mode icons

  func getMode(_ mode: Item) -> Bool {
    return toggledModes.contains(mode)
  }

  func toggleMode(_ mode: Item) -> Bool {
    let selected = toggledModes.contains(mode)
    setMode(mode, selected: !selected)
    return !selected
  }
  
  func setMode(_ mode: Item, selected: Bool) {
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
  private let rx_toggledModes = BehaviorRelay<Set<Item>>(value: [])

  private var toggledModes: Set<Item> {
    get {
      return rx_toggledModes.value
    }
    set {
      rx_toggledModes.accept(newValue)
    }
  }

  public var rx_pickedModes: Driver<Set<Item>> {
    return rx_toggledModes
      .asDriver()
      .distinctUntilChanged()
      .map { [weak self] in
        guard let self = self else { return [] }
        return $0.filter(self.visibleModes.contains)
      }
  }
  
  /// Visible modes that are currently enabled
  var pickedModes: Set<Item> {
    get {
      return rx_toggledModes.value.filter(visibleModes.contains)
    }
  }
  
}

extension TKUIModePicker {
  private static func styleModeButton(_ button: UIButton, selected: Bool, isBranded: Bool = false) {
    button.layer.borderWidth  = 2

    if isBranded {
      button.backgroundColor    = .tkBackground
      button.layer.borderColor  = (selected ? UIColor.tkStateSuccess : .tkLabelTertiary).cgColor

    } else {
      button.backgroundColor    = selected ? .tkStateSuccess : .tkBackground
      button.tintColor          = selected ? .tkBackground : .tkLabelTertiary
      button.layer.borderColor  = (selected ? UIColor.tkStateSuccess : .tkLabelTertiary).cgColor
    }
    
    button.alpha              = selected ? 1 : 0.3
  }
}
