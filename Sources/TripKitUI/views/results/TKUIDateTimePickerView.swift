//
//  TKUIDateTimePickerView.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 8/22/24.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI

public struct TKUIDateTimePickerView: View {
  @ObservedObject var viewModel: TKUIDateTimePickerViewModel
  
  public var body: some View {
    VStack {
      VStack {
        Container {
          ToggleListView(viewModel: viewModel)
        }
        .padding(.bottom, 32)
        
        DatePickerView(viewModel: viewModel)
        
        Spacer()
        
        ConfirmButton(viewModel: viewModel)
          .padding(.bottom)
      }
      .padding(.top, 16)
      .padding(.horizontal, 16)

    }
    .background(Color(.tkBackgroundGrouped))
    .navigationBarTitle(Text(viewModel.navigationTitle()), displayMode: .inline)
  }
}

private struct ToggleListView: View {
  @ObservedObject var viewModel: TKUIDateTimePickerViewModel
  
  var body: some View {
    Container {
      content
    }
  }
  
  var content: some View {
    VStack(alignment: .leading) {
      ForEach(viewModel.toggleItems.indices, id: \.self) { index in
        VStack(alignment: .leading) {
          Toggle(viewModel.toggleItems[index].name, isOn: Binding<Bool>(
            get: { viewModel.toggleItems[index].isSelected },
            set: { newValue in
              viewModel.selectToggle(viewModel.toggleItems[index])
            }
          ))
          .padding(.horizontal, 16)
          
          if index < viewModel.toggleItems.count - 1 {
            Divider()
              .padding(.leading, 16)
          }
        }
      }
    }
    .padding(.vertical, 12)
    .background(Color(.tkBackground))
  }
}

private struct DatePickerView: View {
  @ObservedObject var viewModel: TKUIDateTimePickerViewModel
  
  var body: some View {
    if viewModel.showDatePicker {
      header
      Container {
        content
      }
    }
  }
  
  var header: some View {
    HStack {
      Text(viewModel.returnDateTimeHeaderTitle())
        .font(.caption)
        .foregroundColor(.gray)
      Spacer()
    }
    .padding(.leading, 16)
  }
  
  var content: some View {
    VStack(alignment: .leading) {
      DatePicker(viewModel.dateTitle(),
                 selection: $viewModel.selectedDateTime,
                 in: viewModel.allowedDateRange(),
                 displayedComponents: [.date])
        .environment(\.timeZone, viewModel.timeZone)
        .datePickerStyle(GraphicalDatePickerStyle())
        .accentColor(Color(.tkAppTintColor))
        .padding(.horizontal, 16)
      
      Divider()
        .padding(.leading, 16)
      
      timePicker
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 12)
  }
  
  var timePicker: some View {
    HStack {
      DatePicker(viewModel.timeTitle(), 
                 selection: $viewModel.selectedDateTime,
                 in: viewModel.allowedDateRange(),
                 displayedComponents: [.hourAndMinute])
        .environment(\.timeZone, viewModel.timeZone)
        .accentColor(Color(.tkAppTintColor))
    }
  }
}

private struct Container<Content: View>: View {
  let content: () -> Content
  
  init(@ViewBuilder content: @escaping () -> Content) {
    self.content = content
  }
  
  var body: some View {
    VStack {
      content()
    }
    .background(Color(.tkBackground))
    .cornerRadius(8)
  }
}

struct ConfirmButton: View {
  @ObservedObject var viewModel: TKUIDateTimePickerViewModel
  
  var body: some View {
    Button(action: {
      viewModel.didTapConfirm()
    }) {
      Text(viewModel.confirmTitle())
        .font(.headline)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .padding()
    }
    .background(Color(.tkAppTintColor))
    .frame(height: 40)
    .cornerRadius(20)
  }
}

struct TKUIDateTimePickerView_Previews: PreviewProvider {
  static var previews: some View {
    let min = Calendar.current.date(byAdding: .day, value: -15, to: Date())
    let viewModel = TKUIDateTimePickerViewModel(
      selection: .special("One-way only"),
      items: [.init(name: "One-way only"),
              .init(name: "Round-trip")],
      minimumDate: min)
    
    return Group {
      TKUIDateTimePickerView(viewModel: viewModel)
        .previewDisplayName("Light Mode")
      
      TKUIDateTimePickerView(viewModel: viewModel)
        .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
  }
}
