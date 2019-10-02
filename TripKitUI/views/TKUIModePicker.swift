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
  
  weak var containerView: UIView?

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
    
    // Clean up
    removeAllSubviews()
    
    // This is a "row" of mode icons.
    var currentModeButtonStackView: UIStackView?
    
    // This is an array holding all of the above rows of mode icons.
    var modeButtonStackViews = [UIStackView]()

    // Calculate the number of modes per stack, depending on the available
    // width
    let widthPerMode = Constants.modeButtonWidth + Constants.modeButtonSpacing
    let availableWidth = frame.width - Constants.viewPaddingHorizontal * 2
    let modesPerStack = Int(availableWidth / widthPerMode)

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
    separator.backgroundColor = .tkSeparator
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
  
  private func modeButton(for item: Item) -> UIButton {
    let button = templateModeButton()
    button.accessibilityLabel = item.imageTextRepresentation
    button.layer.cornerRadius = Constants.modeButtonWidth * 0.5
    
    TKUIModePicker.styleModeButton(button, selected: pickedModes.contains(item))
    
    button.setImage(with: item.imageURL, asTemplate: item.imageURLIsTemplate, placeholder: item.image) { [weak self] gotImage in
      guard let self = self else { return }
      self.modeIsBranded[item] = gotImage
      let selected = self.getMode(item)
      TKUIModePicker.styleModeButton(button, selected: selected, isBranded: item.imageURLIsBranding && gotImage)
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

    button.rx.tap
      .subscribe(onNext: { [weak self] in
        guard let self = self else { return }
        let newSelected = self.toggleMode(item)
        let isBranded = self.modeIsBranded[item] ?? false
        TKUIModePicker.styleModeButton(button, selected: newSelected, isBranded: item.imageURLIsBranding && isBranded)
        
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
    
    self.clipsToBounds = false
    
    let wrapper = UIView()
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    wrapper.backgroundColor = .tkBackground
    wrapper.layer.cornerRadius = 4
    wrapper.layer.borderColor = UIColor.tkLabelSecondary.cgColor
    wrapper.layer.borderWidth = 2
    labels[item] = wrapper
    
    let label = UILabel()
    label.backgroundColor = .clear
    label.textColor = .tkLabelSecondary
    label.font = TKStyleManager.customFont(forTextStyle: .footnote)
    label.text = item.imageTextRepresentation
    label.translatesAutoresizingMaskIntoConstraints = false

    wrapper.addSubview(label)
    label.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 8).isActive = true
    label.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 4).isActive = true
    wrapper.trailingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8).isActive = true
    wrapper.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 4).isActive = true
    
    containerView.addSubview(wrapper)
    above.topAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: 8).isActive = true
    
    let center = wrapper.centerXAnchor.constraint(equalTo: above.centerXAnchor)
    center.priority = .defaultHigh
    center.isActive = true
    
    wrapper.leadingAnchor.constraint(greaterThanOrEqualTo: containerView.leadingAnchor).isActive = true
    containerView.trailingAnchor.constraint(greaterThanOrEqualTo: wrapper.trailingAnchor).isActive = true
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
