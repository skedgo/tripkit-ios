//
//  TKUITimePickerViewController.swift
//  TripKitUI-iOS
//
//  Created by Jules Ian Gilos on 8/9/24.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

import TripKit
import RxSwift

public class TKUITimePickerViewController: UIViewController {
  
  public class Item {
    let title: String // This will be the id
    let color: UIColor
    
    public init(title: String, color: UIColor) {
      self.title = title
      self.color = color
    }
  }
  
  private var time: Date
  private var timeZone: TimeZone
  private var items: [Item] = []
  private var config: TKUITimePickerSheet.Configuration
  private var confirmButton: UIButton!
  private var onSelection: ((TKUITimePickerSheet.SelectionStatus) -> Void)?
  
  public init(time: Date,
              timeZone: TimeZone,
              items: [Item] = [],
              config: TKUITimePickerSheet.Configuration,
              onSelection: @escaping (TKUITimePickerSheet.SelectionStatus) -> Void) {
    self.time = time
    self.timeZone = timeZone
    self.items = items
    self.config = config
    self.config.style = .embed
    self.onSelection = onSelection
    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
  
  public override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .tkBackground
    setupNavigationBar()
    setupTimePickerSheet()
    setupConfirmButton()
  }
  
  private func setupNavigationBar() {
    navigationItem.title = Loc.SelectTime
  }
  
  @objc private func didTapBack() {
    navigationController?.popViewController(animated: true)
  }
  
  private func setupTimePickerSheet() {
    var elements: [TKUITimePickerSheet.ToolbarElement] = []
    
    for item in items {
      let toolbarElement: TKUITimePickerSheet.ToolbarElement =
        .button(title: item.title, tint: item.color, isSelector: false) { _ in } // state selection handled in TKUITimePickerSheet.updateSpecialSelectionState
      elements.append(toolbarElement)
    }
    
    let toolbar: TKUITimePickerSheet.ToolbarBuilder? = !elements.isEmpty ?
    TKUITimePickerSheet.ToolbarBuilder(
      elements: elements + [.spacer],
      accessibilityElements: elements + [.picker]
    ) : nil
    
    let picker = TKUITimePickerSheet(
      time: time,
      timeZone: timeZone,
      toolbarBuilder: toolbar,
      config: config
    )
    
    picker.selectionStateDelegate = self
    
    view.addSubview(picker)
    
    picker.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      picker.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      picker.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      picker.centerYAnchor.constraint(equalTo: view.centerYAnchor)
    ])
  }
  
  private func setupConfirmButton() {
    confirmButton = UIButton(type: .system)
    confirmButton.setTitle(Loc.Select, for: .normal)
    confirmButton.backgroundColor = .tkFilledButtonBackgroundColor
    confirmButton.setTitleColor(.tkFilledButtonTextColor, for: .normal)
    confirmButton.layer.cornerRadius = 22
    confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
    
    view.addSubview(confirmButton)
    
    confirmButton.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      confirmButton.heightAnchor.constraint(equalToConstant: 44),
      confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
      confirmButton.heightAnchor.constraint(equalToConstant: 50)
    ])
  }
  
  @objc private func didTapConfirm() {
    navigationController?.popViewController(animated: true)
  }
  
}

extension TKUITimePickerViewController: TKUITimePickerSheetSelectionStateDelegate {
  
  public func timePicker(_ picker: TKUITimePickerSheet, statusChanged status: TKUITimePickerSheet.SelectionStatus) {
    switch status {
    case .valid:
      confirmButton.setTitle(Loc.Select, for: .normal)
      confirmButton.isEnabled = true
    case .special(let title):
      confirmButton.setTitle("Select \(title)", for: .normal)
      confirmButton.isEnabled = true
    case .above:
      confirmButton.setTitle(Loc.DateTimeSelectionAbove, for: .normal)
      confirmButton.isEnabled = false
    case .below:
      confirmButton.setTitle(Loc.DateTimeSelectionBelow, for: .normal)
      confirmButton.isEnabled = false
    }
    
    confirmButton.alpha = confirmButton.isEnabled ? 1.0 : 0.5
    self.onSelection?(status)
  }
  
}
