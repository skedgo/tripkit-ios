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
      Container {
        ToggleListView(viewModel: viewModel)
      }
      .padding(.bottom, 32)
      
      DatePickerView(viewModel: viewModel)
      
      Spacer()
      
      ConfirmButton(viewModel: viewModel)
        .padding(.bottom)
    }
    .padding(.horizontal, 16)
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
    .background(Color(.tkBackgroundGrouped))
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
  
  // TODO: Timezone
  var content: some View {
    VStack(alignment: .leading) {
      if #available(iOSApplicationExtension 14.0, *) {
        DatePicker(viewModel.dateTitle(), selection: $viewModel.selectedDateTime, displayedComponents: [.date])
          .datePickerStyle(GraphicalDatePickerStyle())
          .accentColor(Color(.tkAppTintColor))
          .padding(.horizontal, 16)
      } else {
        DatePicker(viewModel.dateTitle(), selection: $viewModel.selectedDateTime, displayedComponents: [.date])
          .accentColor(Color(.tkAppTintColor))
          .padding(.horizontal, 16)
      }
      
      Divider()
        .padding(.leading, 16)
      
      timePicker
        .padding(.horizontal, 16)
    }
    .padding(.vertical, 12)
  }
  
  var timePicker: some View {
    HStack {
      DatePicker(viewModel.timeTitle(), selection: $viewModel.selectedDateTime, displayedComponents: [.hourAndMinute])
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
    .background(Color(.tkBackgroundGrouped))
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
      
      
        .padding(.horizontal)
    }
    .background(Color(.tkAppTintColor))
    .frame(height: 40)
    .cornerRadius(20)
  }
}

struct TKUIDateTimePickerView_Previews: PreviewProvider {
  static var previews: some View {
    let viewModel = TKUIDateTimePickerViewModel(items: [
      .init(name: "One-way only"),
      .init(name: "Round-trip")
    ])
    
    return Group {
      TKUIDateTimePickerView(viewModel: viewModel)
        .previewDisplayName("Light Mode")
      
      TKUIDateTimePickerView(viewModel: viewModel)
        .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
  }
}
