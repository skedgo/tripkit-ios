//
//  TKUITimePicker.swift
//  TripKit
//
//  Created by Adrian Schönig on 6/8/2025.
//

import SwiftUI

import TripKit

// TODO:
// - [ ] Pass in selected type and time
// - [ ] Immediately dismiss on selecting "Now", if something else was selcted previously
// - [ ] Fix crash in landscape
// - [ ] Deprecate old picker
struct TKUITimePicker: View {
  init(configuration: TKUITimePickerSheet.Configuration = .default, onCompletion: @escaping (TKTimeType, Date) -> Void) {
    self.configuration = configuration
    self.onCompletion = onCompletion
    self.timeType = timeType
    self.selectedDate = selectedDate
  }
  
  var configuration: TKUITimePickerSheet.Configuration = .default

  var onCompletion: (TKTimeType, Date) -> Void
  
  @State var timeType: TKTimeType = .leaveASAP
  @State var selectedDate: Date = Date()
  
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
  
  var body: some View {
    VStack {
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

      if let range {
        DatePicker(selection: $selectedDate, in: range) {
          EmptyView()
        }
        .datePickerStyle(.wheel)
        .frame(maxWidth: .infinity)
      } else {
        DatePicker(selection: $selectedDate) {
          EmptyView()
        }
        .datePickerStyle(.wheel)
        .frame(maxWidth: .infinity)
      }
      
      Spacer()
    }
    .navigationTitle("Date & Time")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
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
  Color.teal
    .ignoresSafeArea()
    .sheet(isPresented: .constant(true)) {
      NavigationStack {
        TKUITimePicker() { _, _ in }
      }
      .presentationDetents([.medium])
    }
}

@available(iOS 26.0, *)
#Preview("Config 1") {
  @Previewable var configuration: TKUITimePickerSheet.Configuration = {
    var config = TKUITimePickerSheet.Configuration.default
    config.allowsASAP = false
    config.leaveAtLabel = "Leave after"
    config.arriveByLabel = "Arrive before"
    return config
  }()
  
  Color.teal
    .ignoresSafeArea()
    .sheet(isPresented: .constant(true)) {
      NavigationStack {
        TKUITimePicker(configuration: configuration) { _, _ in }
      }
      .presentationDetents([.medium])
    }
}
