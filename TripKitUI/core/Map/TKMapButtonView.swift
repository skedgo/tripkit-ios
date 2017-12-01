//
//  TKMapButtonView.swift
//  TripKitUI
//
//  Created by Kuan Lun Huang on 7/11/17.
//

import UIKit

@objc public class TKMapButtonView: UIView {
  
  public enum Alignment {
    case leading
    case trailing
  }
  
  private weak var stackView: UIStackView!
  
  public var singleItemAlignment = Alignment.trailing {
    didSet {
      guard items.count == 1 else { return }
      
      cleanUp()
      
      switch singleItemAlignment {
      case .leading:
        stackView.addArrangedSubview(items[0])
        stackView.addArrangedSubview(stretchingView())
      case .trailing:
        stackView.addArrangedSubview(stretchingView())
        stackView.addArrangedSubview(items[0])
      }
    }
  }
  
  @objc public var items: [UIView] = [] {
    didSet {
      guard stackView != nil else { preconditionFailure() }
      
      cleanUp()
      
      items.forEach {
        $0.setContentHuggingPriority(.required, for: .horizontal)
        $0.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview($0)
      }

      if items.count == 1 {
        switch singleItemAlignment {
        case .leading:
          stackView.insertArrangedSubview(stretchingView(), at: 1)
        case .trailing:
          stackView.insertArrangedSubview(stretchingView(), at: 0)
        }
      }
    }
  }
  
  private func stretchingView() -> UIView {
    let stretchingView = UIView()
    stretchingView.setContentHuggingPriority(.defaultLow, for: .horizontal)
    stretchingView.backgroundColor = .blue
    stretchingView.translatesAutoresizingMaskIntoConstraints = false
    return stretchingView
  }
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    prepareWrapper()
  }
  
  public required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    prepareWrapper()
  }
  
  private func prepareWrapper() {
    let wrapper = UIStackView()
    wrapper.axis = .horizontal
    wrapper.alignment = .center
    wrapper.distribution = .equalSpacing
    addSubview(wrapper)
    stackView = wrapper
    
    wrapper.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        wrapper.topAnchor.constraint(equalTo: topAnchor),
        wrapper.leadingAnchor.constraint(equalTo: leadingAnchor),
        bottomAnchor.constraint(equalTo: wrapper.bottomAnchor),
        trailingAnchor.constraint(equalTo: wrapper.trailingAnchor)
      ])
  }
  
  private func cleanUp() {
    stackView.arrangedSubviews.forEach {
      stackView.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
  }

}
