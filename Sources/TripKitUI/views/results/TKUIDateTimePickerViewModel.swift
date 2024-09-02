//
//  TKUIDateTimePickerViewModel.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 8/22/24.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TripKit

public class TKUIDateTimePickerViewModel: ObservableObject {
  
  enum Constants {
    static let maxDateRange = 3
  }
  
  public struct ToggleItem: Identifiable {
    public let id: String
    let name: String
    var isSelected: Bool = false
    
    public init(name: String, isSelected: Bool = false) {
      self.id = name // Let the name be the id
      self.name = name
      self.isSelected = isSelected
    }
  }
  
  public enum Selection {
    case dateTime(Date)
    case special(String)
  }
  
  @Published var toggleItems: [ToggleItem]
  @Published var showDatePicker: Bool = true
  @Published var selectedDateTime: Date
  
  var timeZone: TimeZone
  var minimumDate: Date?
  var maximumDate: Date?
  var onConfirm: ((Selection) -> Void)?
  
  init(selection: Selection = .dateTime(Date()),
       timeZone: TimeZone = TimeZone.current,
       items: [ToggleItem] = [],
       minimumDate: Date? = nil,
       maximumDate: Date? = nil,
       onConfirm: ((Selection) -> Void)? = nil) {
    self.selectedDateTime = minimumDate ?? Date()
    self.timeZone = timeZone
    self.toggleItems = items
    self.minimumDate = minimumDate
    self.maximumDate = maximumDate
    self.onConfirm = onConfirm
    
    switch selection {
    case .dateTime(let date):
      self.selectedDateTime = date
    case .special(let id):
      for item in self.toggleItems where item.id == id {
        selectToggle(item)
      }
    }
    
    updateDatePickerVisibility()
  }
  
  func selectToggle(_ toggle: ToggleItem) {
    for index in toggleItems.indices {
      if toggleItems[index].id == toggle.id {
        toggleItems[index].isSelected = !toggleItems[index].isSelected
      } else if !toggle.isSelected {
        toggleItems[index].isSelected = false
      }
    }
    updateDatePickerVisibility()
  }
  
  func didTapConfirm() {
    if let selectedToggle = toggleItems.first(where: { $0.isSelected }) {
      onConfirm?(.special(selectedToggle.name))
    } else {
      onConfirm?(.dateTime(selectedDateTime))
    }
  }
  
  func allowedDateRange() -> ClosedRange<Date> {
    let minimum: Date
    let maximum: Date
    
    if let min = minimumDate {
      minimum = min
    } else {
      minimum = Calendar.current.date(byAdding: .month, value: -Constants.maxDateRange, to: Date()) ?? Date()
    }
    
    if let max = maximumDate {
      maximum = max
    } else {
      maximum = Calendar.current.date(byAdding: .month, value: Constants.maxDateRange, to: Date()) ?? Date()
    }
    
    return minimum...maximum
  }
  
  private func updateDatePickerVisibility() {
    showDatePicker = !toggleItems.contains { $0.isSelected }
  }
}


// MARK: - Strings

extension TKUIDateTimePickerViewModel {
  
  func navigationTitle() -> String {
    return Loc.SelectTime
  }
  
  func dateTitle() -> String {
    return Loc.PickerDateTitle
  }
  
  func timeTitle() -> String {
    return Loc.PickerTimeTitle
  }
  
  func returnDateTimeHeaderTitle() -> String {
    return Loc.SelectReturnDate.uppercased()
  }
  
  func confirmTitle() -> String {
    return Loc.Confirm
  }
  
}
