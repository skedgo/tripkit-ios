//
//  NearbyModeSelector.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 22/5/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import RxCocoa
import RxSwift
import TripKit

public struct TKUIModePickerItem {
  let rawData: Any
  let identifier: String?
  let imageURL: URL?
  let image: TKImage?
  let imageTextRepresentation: String
}

extension TKUIModePickerItem {
  public init(from modeInfo: TKModeInfo) {
    rawData = modeInfo
    identifier = modeInfo.identifier
    imageURL = modeInfo.imageURL
    image = modeInfo.image
    imageTextRepresentation = modeInfo.alt
  }
  
  public var modeInfo: TKModeInfo? {
    return rawData as? TKModeInfo
  }
}

extension TKUIModePickerItem: Comparable {
  public static func < (lhs: TKUIModePickerItem, rhs: TKUIModePickerItem) -> Bool {
    if let leftId = lhs.identifier, let rightId = rhs.identifier {
      return leftId < rightId
    } else {
      return lhs.identifier != nil
    }
  }
}

extension TKUIModePickerItem: Equatable {
  public static func == (lhs: TKUIModePickerItem, rhs: TKUIModePickerItem) -> Bool {
    return lhs.identifier == rhs.identifier
  }
}

// MARK: -
public class TKUINearbyModePicker: UIView {
  
  private enum Constants {
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
  
  /// These are all the available/visible modes
  var modes: [TKUIModePickerItem] = [] {
    didSet {
      let maximisedModes = TKUserProfileHelper.maximizedModeIdentifiers(modes.compactMap { $0.identifier })

      // Whenever we encounter a new mode, default the visibility to whether it
      // is maximised or not.
      modes
        .filter { !seenModes.contains($0) }
        .map { seenModes.append($0); return $0 } // like Rx's `doOn`
        .filter { maximisedModes.contains($0.identifier ?? "") }
        .forEach { toggledModes.append($0) }
      
      // Must be called after `pickedModes` is set, so mode icon can be dimmed
      // properly.
      updateUI()
      
      if let container = superview {
        self.frame.size.width = container.frame.width
        container.frame.size.height = self.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      }
    }
  }
  
  private let disposeBag = DisposeBag()
  
  // MARK: - Configuration
  
  private func updateUI() {
    guard modes.count > 0 else { return }
    
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

    for (index, mode) in modes.sorted().enumerated() {
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
  
  private func modeButton(for mode: TKUIModePickerItem) -> UIButton {
    let button = templateModeButton()
    button.accessibilityLabel = mode.imageTextRepresentation
    button.layer.cornerRadius = Constants.modeButtonWidth * 0.5
    
    // Use remote icon if available
    button.setImage(with: mode.imageURL, for: .normal, placeholder: mode.image)
    
    button.rx.tap
      .subscribe(onNext: { [unowned self] in
        let newSelected = self.toggleMode(mode)
        TKUINearbyModePicker.styleModeButton(button, selected: newSelected)
      })
      .disposed(by: disposeBag)
    
    TKUINearbyModePicker.styleModeButton(button, selected: pickedModes.contains(mode))
    
    return button
  }
  
  // MARK: - Handling tap on mode icons
  
  func toggleMode(_ mode: TKUIModePickerItem) -> Bool {
    let selected = toggledModes.contains(mode)
    setMode(mode, selected: !selected)
    return !selected
  }
  
  func setMode(_ mode: TKUIModePickerItem, selected: Bool) {
    if selected {
      guard !toggledModes.contains(mode) else { return }
      toggledModes.append(mode)
    } else {
      guard let position = toggledModes.firstIndex(of: mode) else { return }
      toggledModes.remove(at: position)
    }
  }
  
  /// For keeping track of what modes we've encountered before, i.e., if a mode
  /// disappears and then re-appears, we'll remember its toggled state.
  private var seenModes: [TKUIModePickerItem] = []

  /// For keeping track of what modes a user has toggled on/off before. This is
  /// all the enabled modes, even though they might not currently be visible,
  /// i.e., they are not in `modes`.
  private let rx_toggledModes = BehaviorRelay<[TKUIModePickerItem]>(value: [])

  private var toggledModes: [TKUIModePickerItem] {
    get {
      return rx_toggledModes.value
    }
    set {
      rx_toggledModes.accept(newValue)
    }
  }

  fileprivate var rx_pickedModes: Driver<[TKUIModePickerItem]> {
    return rx_toggledModes
      .asDriver()
      .map { $0.filter(self.modes.contains) }
  }
  
  /// Visible modes that are currently enabled
  var pickedModes: [TKUIModePickerItem] {
    get {
      return rx_toggledModes.value.filter(modes.contains)
    }
  }
  
}

extension TKUINearbyModePicker {
  public func addAsHeader(to tableView: UITableView) {
    // constrain the picker to the width of the table view
    frame.size.width = tableView.frame.width
    
    // ask the layout system for the minimum height required to
    // display the picker in full.
    let requiredHeight = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
    
    // create a wrapper that is big enough to contain the picker
    let wrapper = UIView(frame: CGRect(x: 0, y: 0, width: frame.width, height: requiredHeight))
    wrapper.addSubview(self)
    
    // connect up constraints
    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        topAnchor.constraint(equalTo: wrapper.topAnchor),
        bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        leadingAnchor.constraint(equalTo: wrapper.leadingAnchor),
        trailingAnchor.constraint(equalTo: wrapper.trailingAnchor)
      ])
    
    // attach the wrapper to the table view as table view header
    tableView.tableHeaderView = wrapper
  }
}

extension TKUINearbyModePicker {
  private static func styleModeButton(_ button: UIButton, selected: Bool) {
    button.backgroundColor = selected ? #colorLiteral(red: 0.3696880937, green: 0.6858631968, blue: 0.2820466757, alpha: 1) : .lightGray
    button.tintColor = selected ? .white : #colorLiteral(red: 0.9601849914, green: 0.9601849914, blue: 0.9601849914, alpha: 1)
  }
}

extension TKModeInfo: Comparable {
  public static func < (lhs: TKModeInfo, rhs: TKModeInfo) -> Bool {
    if let leftId = lhs.identifier, let rightId = rhs.identifier {
      return leftId < rightId
    } else {
      return lhs.identifier != nil
    }
  }
}

extension Reactive where Base: TKUINearbyModePicker {
  public var availableModes: Binder<[TKUIModePickerItem]> {
    return Binder(self.base) { view, modes in
      view.modes = modes
    }
  }
  
  public var pickedModes: Driver<[TKUIModePickerItem]> {
    return base.rx_pickedModes
  }
}
