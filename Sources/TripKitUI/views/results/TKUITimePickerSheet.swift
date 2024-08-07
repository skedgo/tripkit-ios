//
//  TKUITimePickerSheet.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit
import RxSwift

public protocol TKUITimePickerSheetDelegate: AnyObject {

  func timePicker(_ picker: TKUITimePickerSheet, pickedDate: Date, for type: TKTimeType)

  func timePickerRequestsResign(_ picker: TKUITimePickerSheet)

}

public class TKUITimePickerSheet: TKUISheet {
  
  public struct ToolbarBuilder {
    /// Builder for custom toolbar elements
    /// - Parameters:
    ///   - elements: Closure that returns the elements to go into the toolbar, i.e., above the time picker.
    ///   - accessibilityElements: List of accessible elements in the order that they should be selected. Must include `.picker`!
    public init(elements: [TKUITimePickerSheet.ToolbarElement], accessibilityElements: [TKUITimePickerSheet.ToolbarElement]) {
      self.elements = elements
      self.accessibilityElements = accessibilityElements
    }
    
    var elements: [ToolbarElement]
    var accessibilityElements: [ToolbarElement]
  }
  
  public enum ToolbarElement {
    case button(title: String, tint: UIColor? = nil, isSelector: Bool = true, handler: (Date) -> Void)
    case spacer
    case picker
  }
  
  fileprivate enum Mode {
    case date
    case time
    case timeWithType(TKTimeType)
  }
  
  public var selectAction: (TKTimeType, Date) -> Void = { _, _ in }
  
  public weak var delegate: TKUITimePickerSheetDelegate?
  
  public var selectedDate: Date {
    get {
      timePicker.date
    }
    set {
      timePicker.date = newValue
    }
  }
  
  public var selectedTimeType: TKTimeType {
    get {
      guard case .timeWithType = mode else { return .none }
      
      switch (timeTypeSelector?.selectedSegmentIndex, config.allowsASAP) {
      case (0, true):   return .leaveASAP
      case (1, true),
           (0, false):  return .leaveAfter
      case (2, true),
           (1, false):  return .arriveBefore
      default:          return .none
      }
    }
    set {
      switch (newValue, config.allowsASAP) {
      case (.leaveASAP, true):
        timeTypeSelector?.selectedSegmentIndex = 0
        timePicker.setDate(.init(), animated: true)
      
      case (.leaveAfter, true):
        timeTypeSelector?.selectedSegmentIndex = 1
      case (.leaveAfter, false):
        timeTypeSelector?.selectedSegmentIndex = 0
      
      case (.arriveBefore, true):
        timeTypeSelector?.selectedSegmentIndex = 2
      case (.arriveBefore, false):
        timeTypeSelector?.selectedSegmentIndex = 1
      
      default:
        break
      }
      
      didSetTime = true
      delegate?.timePicker(self, pickedDate: selectedDate, for: newValue)
    }
  }
  
  private let config: Configuration
  private let mode: Mode
  private var didSetTime: Bool
  private let disposeBag = DisposeBag()
  private weak var timePicker: UIDatePicker!
  private weak var timeTypeSelector: UISegmentedControl!
  private weak var doneSelector: UISegmentedControl!

  public convenience init(date: Date, timeZone: TimeZone, toolbarBuilder: ToolbarBuilder? = nil, config: Configuration = .default) {
    self.init(date: date, showTime: false, mode: .date, timeZone: timeZone, toolbarBuilder: toolbarBuilder, config: config)
  }
  
  public convenience init(time: Date, timeType: TKTimeType = .none, timeZone: TimeZone, toolbarBuilder: ToolbarBuilder? = nil, config: Configuration = .default) {
    self.init(date: time, showTime: true, mode: timeType == .none ? .time : .timeWithType(timeType), timeZone: timeZone, toolbarBuilder: toolbarBuilder, config: config)
  }
  
  private init(date: Date, showTime: Bool, mode: Mode, timeZone: TimeZone, toolbarBuilder: ToolbarBuilder?, config: Configuration) {
    didSetTime = false
    self.mode = mode
    self.config = config

    super.init(frame: .zero)
    
    overlayColor = .tkSheetOverlay
    backgroundColor = .tkBackground
    
    let timePicker = UIDatePicker()
    timePicker.datePickerMode = showTime ? .dateAndTime : .date
    timePicker.date = date
    timePicker.timeZone = timeZone
    timePicker.minuteInterval = config.incrementInterval
    
    if #available(iOS 13.4, *) {
      timePicker.preferredDatePickerStyle = .wheels
      timePicker.sizeToFit()
    }
    
    if let earliest = config.minimumDate, !config.allowsOutOfRangeSelection {
      timePicker.minimumDate = earliest
    } else if config.removeDateLimits {
      timePicker.minimumDate = nil
    } else if showTime {
      // A month ago
      timePicker.minimumDate = .init(timeIntervalSinceNow: 60 * 60 * 24 * -31)
    }
    
    if let latest = config.maximumDate, !config.allowsOutOfRangeSelection {
      timePicker.maximumDate = latest
    } else if config.removeDateLimits {
      timePicker.maximumDate = nil
    } else if showTime {
      // A month from now
      timePicker.maximumDate = .init(timeIntervalSinceNow: 60 * 60 * 24 * 31)
    }
    
    timePicker.locale = .current // set 24h setting
    timePicker.translatesAutoresizingMaskIntoConstraints = false
    timePicker.addTarget(self, action: #selector(timePickerChanged(sender:)), for: .valueChanged)
    self.addSubview(timePicker)
    self.timePicker = timePicker
    
    NSLayoutConstraint.activate([
      timePicker.leadingAnchor.constraint(equalTo: leadingAnchor),
      timePicker.bottomAnchor.constraint(equalTo: bottomAnchor),
      timePicker.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
    
    let toolbar = UIToolbar(frame: .zero)
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.setBackgroundImage(.init(), forToolbarPosition: .any, barMetrics: .default)
    toolbar.backgroundColor = self.backgroundColor
    addSubview(toolbar)
    
    NSLayoutConstraint.activate([
      toolbar.leadingAnchor.constraint(equalTo: leadingAnchor),
      toolbar.topAnchor.constraint(equalTo: topAnchor),
      toolbar.trailingAnchor.constraint(equalTo: trailingAnchor),
      toolbar.heightAnchor.constraint(equalToConstant: 44),
      toolbar.bottomAnchor.constraint(equalTo: timePicker.topAnchor)
    ])
    
    // Use default time selector if no custom tool bar items are provided.
    if let builder = toolbarBuilder {
      toolbar.items = builder.elements.compactMap { element -> UIBarButtonItem? in
        switch element {
        case let .button(title, tint, isSelector, handler):
          let selector = UISegmentedControl(items: [title])
          selector.tintColor = tint
          selector.rx.controlEvent(.valueChanged)
            .subscribe(onNext: { [weak self] _ in
              guard let self else { return }
              self.removeOverlay(animated: true)
              handler(self.timePicker.date)
            })
            .disposed(by: disposeBag)
          
          if isSelector {
            self.doneSelector = selector
          }
          
          return .init(customView: selector)
        
        case .spacer:
          return .init(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
          
        case .picker:
          return nil
        }
      }
      
      self.accessibilityElements = builder.accessibilityElements.compactMap { element in
        switch element {
        case let .button(title, _, _, _):
          return toolbar.items?
            .compactMap { $0.customView as? UISegmentedControl }
            .first { $0.titleForSegment(at: 0) == title }
          
        case .picker:
          return timePicker
          
        case .spacer:
          return nil
        }
      }
      
    } else {
      let selector: UISegmentedControl! // as `timeTypeSelector` is weak
      switch mode {
      case .timeWithType(let timeType):
        assert(timeType != .none)
        if config.allowsASAP {
          selector = UISegmentedControl(items: [Loc.Now, config.leaveAtLabel, config.arriveByLabel])
        } else {
          selector = UISegmentedControl(items: [config.leaveAtLabel, config.arriveByLabel])
        }
        selector.addTarget(self, action: #selector(timeSelectorChanged(sender:)), for: .valueChanged)
        
        // this sets the selected section index
        self.timeTypeSelector = selector
        self.selectedTimeType = timeType

      case .time, .date:
        selector = UISegmentedControl(items: [Loc.Now])
        selector.addTarget(self, action: #selector(timeSelectorChanged(sender:)), for: .valueChanged)
      }
      
      // Yes, a segmented control with one element. This is for consistent styling.
      let doneSelector = UISegmentedControl(items: [Loc.Done])
      doneSelector.addTarget(self, action: #selector(doneButtonPressed(sender:)), for: .valueChanged)
      
      toolbar.items = [
        selector.map(UIBarButtonItem.init(customView:)),
        UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
        UIBarButtonItem(customView: doneSelector)
      ].compactMap { $0 }
      
      self.timeTypeSelector = selector
      self.doneSelector = doneSelector
      self.accessibilityElements = [selector, timePicker, doneSelector].compactMap { $0 }
    }
    
    self.frame = .init(x: 0, y: 0, width: timePicker.frame.width, height: systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func tappedOverlay(_ sender: Any) {
    if didSetTime {
      selectAction(selectedTimeType, selectedDate)
      selectAction = { _, _ in }
    }
    
    super.tappedOverlay(sender)
  }
  
  // MARK: Actions
  
  @objc
  func timePickerChanged(sender: Any) {
    didSetTime = true
    
    if selectedTimeType == .leaveASAP {
      selectedTimeType = .leaveAfter
    }
    
    updateDoneButtonState(selector: doneSelector, handler: { _ in })
  }
  
  @objc
  func timeSelectorChanged(sender: Any) {
    switch mode {
    case .date, .time:
      nowButtonPressed(sender: sender)
    case .timeWithType where selectedTimeType == .leaveASAP:
      nowButtonPressed(sender: sender)
    case .timeWithType:
      break // do nothing
    }
  }

  @objc
  func nowButtonPressed(sender: Any) {
    selectAction(.leaveASAP, .init())
    selectAction = { _, _ in }
    
    // be consistent in case these are accessed by the owner or delegate
    timeTypeSelector?.selectedSegmentIndex = 0
    timePicker.setDate(.init(), animated: true)
    
    if isBeingOverlaid {
      tappedOverlay(sender)
    } else if let delegate = delegate {
      delegate.timePickerRequestsResign(self)
    } else {
      // We updated the time picker above
    }
  }

  @objc
  func doneButtonPressed(sender: Any) {
    guard doneSelector.isEnabled 
    else {
      return
    }
    
    doneSelector.selectedSegmentIndex = -1
    
    if isBeingOverlaid {
      tappedOverlay(sender)
    } else if let delegate {
      delegate.timePickerRequestsResign(self)
    } else {
      assertionFailure("Done pressed, but don't know what to do. Set a delegate?")
    }
  }
  
  private func updateDoneButtonState(selector: UISegmentedControl?,
                                     handler: @escaping (Date) -> Void) {
    guard let selector else { return }
    
    let selectedDate = timePicker.date
    
    var title = Loc.Done
    var isEnabled = true
    
    if let earliestDate = config.minimumDate, selectedDate < earliestDate {
      title = Loc.DateTimeSelectionBelow
      isEnabled = false
    } else if let latestDate = config.maximumDate, selectedDate > latestDate {
      title = Loc.DateTimeSelectionAbove
    }
    
    selector.setTitle(title, forSegmentAt: 0)
    selector.isEnabled = isEnabled
    selector.invalidateIntrinsicContentSize()
    selector.sizeToFit()
  }
  
}
