//
//  TKUITimePicker.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/2025.
//

import SwiftUI

import TripKit

@available(iOS 26.0, *)
public struct TKUITimePicker: View {
  public init(time: Date = Date(), timeType: TKTimeType, timeZone: TimeZone = .current, configuration: TKUITimePickerConfiguration = .default, onCompletion: @escaping (TKTimeType, Date) -> Void) {
    self.configuration = configuration
    self.datePickerComponents = [.date, .hourAndMinute]
    self.timeZone = timeZone
    self.onCompletion = onCompletion
    self.selectedDate = time
    self.timeType = timeType
    self.showTimeTypePicker = true
  }
  
  public init(time: Date = Date(), timeZone: TimeZone = .current, configuration: TKUITimePickerConfiguration = .default, onCompletion: @escaping (Date) -> Void) {
    self.configuration = configuration
    self.datePickerComponents = [.date, .hourAndMinute]
    self.timeZone = timeZone
    self.onCompletion = { _, date in onCompletion(date) }
    self.selectedDate = time
    self.timeType = .leaveASAP // Doesn't matter; won't be shown
    self.showTimeTypePicker = false
  }
  
  public init(date: Date, timeZone: TimeZone = .current, configuration: TKUITimePickerConfiguration = .default, onCompletion: @escaping (Date) -> Void) {
    self.configuration = configuration
    self.datePickerComponents = [.date]
    self.timeZone = timeZone
    self.onCompletion = { _, date in onCompletion(date) }
    self.selectedDate = date
    self.timeType = .leaveASAP // Doesn't matter; won't be shown
    self.showTimeTypePicker = false
  }
  
  let configuration: TKUITimePickerConfiguration
  let showTimeTypePicker: Bool
  let datePickerComponents: DatePickerComponents
  let timeZone: TimeZone
  let onCompletion: (TKTimeType, Date) -> Void
  
  @State var timeType: TKTimeType
  @State var selectedDate: Date
  
  @Environment(\.dismiss) var dismiss
  
  private var range: ClosedRange<Date>? {
    if let minimumDate = configuration.minimumDate,
       let maximumDate = configuration.maximumDate
    {
      return minimumDate...maximumDate
    } else if configuration.removeDateLimits {
      return nil
    } else {
      let oneMonthAgo = Date(timeIntervalSinceNow: 60 * 60 * 24 * -31)
      let inOneMonth = Date(timeIntervalSinceNow: 60 * 60 * 24 * 31)
      return oneMonthAgo...inOneMonth
    }
  }
  
  public var body: some View {
    VStack(alignment: .center) {
      if showTimeTypePicker {
        Picker(selection: $timeType) {
          if configuration.allowsASAP {
            Text(verbatim: Loc.Now)
              .tag(TKTimeType.leaveASAP)
          }
          Text(verbatim: configuration.leaveAtLabel)
            .tag(TKTimeType.leaveAfter)
          Text(verbatim: configuration.arriveByLabel)
            .tag(TKTimeType.arriveBefore)
        } label: {
          EmptyView()
        }
        .pickerStyle(.segmented)
        .padding()
      }

      Group {
        if let range {
          DatePicker(selection: $selectedDate, in: range, displayedComponents: datePickerComponents) {
            EmptyView()
          }
        } else {
          DatePicker(selection: $selectedDate, displayedComponents: datePickerComponents) {
            EmptyView()
          }
        }
      }
      .datePickerStyle(.wheel)
      .frame(maxWidth: 200) // Sticks to the trailing edge otherwise somehow

      Spacer()
    }
    .environment(\.timeZone, timeZone)
    .onChange(of: selectedDate) { _, newValue in
      if abs(newValue.timeIntervalSinceNow) > 60, timeType == .leaveASAP {
        timeType = .leaveAfter
      }
    }
    .onChange(of: timeType) { oldValue, newValue in
      if oldValue != .leaveASAP, newValue == .leaveASAP {
        onCompletion(newValue, Date())
        dismiss()
      }
    }
    .navigationTitle(Text(verbatim: configuration.title))
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      if !showTimeTypePicker, configuration.allowsASAP {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            onCompletion(.leaveASAP, Date())
            dismiss()
          } label: {
            Text(verbatim: Loc.Now)
          }
        }
      }
      
      ToolbarItem(placement: .confirmationAction) {
        Button {
          onCompletion(timeType, selectedDate)
          dismiss()
        } label: {
          Label {
            Text(verbatim: Loc.Done)
          } icon: {
            Image(systemName: "checkmark")
          }
        }
      }
    }
  }
}

@available(iOS 26.0, *)
#Preview("Default") {
  @Previewable @State var isPresented: Bool = true

  Color.teal
    .ignoresSafeArea()
    .sheet(isPresented: $isPresented) {
      NavigationStack {
        TKUITimePicker(time: Date(), timeType: .leaveASAP) { _, _ in }
      }
      .presentationDetents([.medium])
    }
}

@available(iOS 26.0, *)
#Preview("Config 1") {
  @Previewable var configuration: TKUITimePickerConfiguration = {
    var config = TKUITimePickerSheet.Configuration.default
    config.allowsASAP = false
    config.leaveAtLabel = "Leave after"
    config.arriveByLabel = "Arrive before"
    return config
  }()
  @Previewable @State var isPresented: Bool = true
  
  Color.teal
    .ignoresSafeArea()
    .sheet(isPresented: $isPresented) {
      NavigationStack {
        TKUITimePicker(timeType: .leaveAfter, configuration: configuration) { _, _ in }
      }
      .presentationDetents([.medium])
    }
}
