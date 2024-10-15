//
//  TKUIDateTimePickerViewController.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 8/25/24.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import RxSwift
import RxCocoa
import SwiftUI

public class TKUIDateTimePickerViewController: UIHostingController<TKUIDateTimePickerView> {
  
  private let disposeBag = DisposeBag()
  var viewModel: TKUIDateTimePickerViewModel
  
  init(rootView: TKUIDateTimePickerView, viewModel: TKUIDateTimePickerViewModel) {
    self.viewModel = viewModel
    super.init(rootView: rootView)
  }
  
  @MainActor required dynamic init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

public extension TKUIDateTimePickerViewController {
  
  static func build(
    selection: TKUIDateTimePickerViewModel.Selection = .dateTime(Date()),
    timeZone: TimeZone = .current,
    items: [TKUIDateTimePickerViewModel.ToggleItem],
    minimumDate: Date? = nil,
    maximumDate: Date? = nil,
    onConfirm: @escaping (TKUIDateTimePickerViewModel.Selection) -> Void
  ) -> TKUIDateTimePickerViewController {
    let viewModel = TKUIDateTimePickerViewModel(
      selection: selection,
      timeZone: timeZone,
      items: items,
      minimumDate: minimumDate,
      maximumDate: maximumDate,
      onConfirm: onConfirm
    )
    
    let rootView = TKUIDateTimePickerView(viewModel: viewModel)
    
    return TKUIDateTimePickerViewController(rootView: rootView, viewModel: viewModel)
  }
}
