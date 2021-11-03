//
//  TKUITimePickerSheet.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 31/1/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit

public protocol TKUITimePickerSheetDelegate: AnyObject {

  func timePicker(_ picker: TKUITimePickerSheet, pickedDate: Date, for type: TKTimeType)

  func timePickerRequestsResign(_ picker: TKUITimePickerSheet)

}

public class TKUITimePickerSheet: TKUISheet {
  
  fileprivate enum Mode {
    case date
    case time
    case timeWithType(TKTimeType)
  }
  
  public static var config = Configuration.empty
  
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
      
      switch timeTypeSelector?.selectedSegmentIndex {
      case 0: return .leaveASAP
      case 1: return .leaveAfter
      case 2: return .arriveBefore
      default: return .none
      }
    }
    set {
      switch newValue {
      case .leaveASAP:
        timeTypeSelector?.selectedSegmentIndex = 0
        timePicker.setDate(.init(), animated: true)
      case .leaveAfter:
        timeTypeSelector?.selectedSegmentIndex = 1
      case .arriveBefore:
        timeTypeSelector?.selectedSegmentIndex = 2
      case .none:
        break
      }
      
      didSetTime = true
      delegate?.timePicker(self, pickedDate: selectedDate, for: newValue)
    }
  }
  
  private let mode: Mode
  private var didSetTime: Bool
  private weak var timePicker: UIDatePicker!
  private weak var timeTypeSelector: UISegmentedControl!
  private weak var doneSelector: UISegmentedControl!

  public convenience init(date: Date, timeZone: TimeZone) {
    self.init(date: date, showTime: false, mode: .date, timeZone: timeZone)
  }
  
  public convenience init(time: Date, timeType: TKTimeType = .none, timeZone: TimeZone) {
    self.init(date: time, showTime: true, mode: timeType == .none ? .time : .timeWithType(timeType), timeZone: timeZone)
  }
  
  private init(date: Date, showTime: Bool, mode: Mode, timeZone: TimeZone) {
    didSetTime = false
    self.mode = mode

    super.init(frame: .init(origin: .zero, size: .init(width: 320, height: 116)))
    
    overlayColor = .tkSheetOverlay
    backgroundColor = .tkBackground
    
    let timePicker = UIDatePicker()
    timePicker.datePickerMode = showTime ? .dateAndTime : .date
    timePicker.date = date
    timePicker.timeZone = timeZone
    timePicker.minuteInterval = Self.config.incrementInterval
    
    if #available(iOS 13.4, *) {
      timePicker.preferredDatePickerStyle = .wheels
      timePicker.sizeToFit()
    }

    if showTime {
      // Limit to a month ago until one month from now
      timePicker.minimumDate = .init(timeIntervalSinceNow: 60 * 60 * 24 * -31)
      timePicker.maximumDate = .init(timeIntervalSinceNow: 60 * 60 * 24 * 31)
    }
    
    timePicker.locale = .current // set 24h setting
    timePicker.autoresizingMask = .flexibleWidth
    timePicker.addTarget(self, action: #selector(timePickerChanged(sender:)), for: .valueChanged)
    self.addSubview(timePicker)
    self.timePicker = timePicker
    
    let selector: UISegmentedControl! // as `timeTypeSelector` is weak
    switch mode {
    case .timeWithType(let timeType):
      assert(timeType != .none)
      if Self.config.allowsASAP {
        selector = UISegmentedControl(items: [Loc.Now, Loc.LeaveAt, Loc.ArriveBy])
      } else {
//        assert(timeType != .none && timeType != .leaveASAP)
        selector = UISegmentedControl(items: [Loc.LeaveAt, Loc.ArriveBy])
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
    
    let toolbar = UIToolbar(frame: .init(x: 0, y: 0, width: timePicker.frame.width, height: 44))
    toolbar.autoresizingMask = .flexibleWidth
    toolbar.items = [
      selector.map(UIBarButtonItem.init(customView:)),
      UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
      UIBarButtonItem(customView: doneSelector)
    ].compactMap { $0 }
    toolbar.setBackgroundImage(.init(), forToolbarPosition: .any, barMetrics: .default)
    toolbar.backgroundColor = self.backgroundColor
    addSubview(toolbar)
    
    self.timeTypeSelector = selector
    self.doneSelector = doneSelector

    self.frame = .init(x: 0, y: 0, width: timePicker.frame.width, height: timePicker.frame.height + toolbar.frame.height)
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
    
    if isBeingOverlaid {
      tappedOverlay(sender)
    } else if let delegate = delegate {
      delegate.timePickerRequestsResign(self)
    } else {
      timePicker.setDate(.init(), animated: true)
    }
  }

  @objc
  func doneButtonPressed(sender: Any) {
    doneSelector.selectedSegmentIndex = -1
    
    if isBeingOverlaid {
      tappedOverlay(sender)
    } else if let delegate = delegate {
      delegate.timePickerRequestsResign(self)
    } else {
      assertionFailure("Done pressed, but don't know what to do. Set a delegate?")
    }
  }
  
}
