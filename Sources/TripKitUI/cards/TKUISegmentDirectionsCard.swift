//
//  TKUISegmentDirectionsCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 06.03.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import class MapKit.MKDistanceFormatter
import UIKit
import SwiftUI

import TGCardViewController

import RxSwift
import RxCocoa

import TripKit

public class TKUISegmentDirectionsCard: TGHostingCard<TKUISegmentDirectionsContent> {
  
  public static func canShowInstructions(for segment: TKSegment) -> Bool {
    return TKUISegmentDirectionsViewModel.canShowInstructions(for: segment)
  }
  
  public static var config = Configuration.empty
  
  let segment: TKSegment
  
  let titleView: TKUISegmentTitleView
  
  private var viewModel: TKUISegmentDirectionsViewModel!
  
  private let disposeBag = DisposeBag()
  
  var tripMapManager: TKUITripMapManager {
    guard let tripper = mapManager as? TKUITripMapManager else { preconditionFailure() }
    return tripper
  }
  
  init(for segment: TKSegment, mapManager: TKUITripMapManager) {
    self.segment = segment
    
    titleView = TKUISegmentTitleView.newInstance()
    titleView.configure(for: segment)
    
    let wrapper = CardHolder()
    
    super.init(
      title: .custom(titleView, dismissButton: titleView.dismissButton),
      rootView: TKUISegmentDirectionsContent(model: .init(segment: segment), wrapper: wrapper),
      mapManager: mapManager
    )
    
    wrapper.card = self
    
    titleView.applyStyleToCloseButton(style)
  }
  
  public override func didBuild(scrollView: UIScrollView) {
    super.didBuild(scrollView: scrollView)
    
    if #unavailable(iOS 26.0) {
      scrollView.backgroundColor = .tkBackgroundGrouped
    }
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
  
}

fileprivate class CardHolder {
  weak var card: TKUISegmentDirectionsCard?
}

public struct TKUISegmentDirectionsContent: View {
  @ObservedObject var model: TKUISegmentDirectionsViewModel
  fileprivate let wrapper: CardHolder
  
  public var body: some View {
    VStack(alignment: .leading) {
      if let factory = TKUISegmentDirectionsCard.config.actionFactory {
        TKUICardActionsViewFactory.build(actions: factory(model.segment)) { action in
          guard let card = wrapper.card else { return }
          _ = action.handler(action, card, model.segment, nil)
        }
        .background(.clear)
      }
      
      LazyVStack(alignment: .leading) {
        ForEach(model.items) { item in
          if item.index != 0 {
            Divider()
          }
          TKUISegmentDirectionView(item: item)
        }
      }
      .padding()
      .background(Color(.tkBackgroundNotClear))
      .cornerRadius(22)
    }
    .padding()
    .modify { view in
      if #available(iOS 26.0, *) {
        view
          .background(.clear)
      } else {
        view
          .background(Color(.tkBackgroundGrouped))
      }
    }
  }
}

struct TKUISegmentDirectionView: View {
  let item: TKUISegmentDirectionsViewModel.Item
  
  var distance: String? {
    guard let distance = item.distance else { return nil }
    let distanceFormatter = MKDistanceFormatter()
    distanceFormatter.unitStyle = .abbreviated
    return distanceFormatter.string(fromDistance: distance)
  }
  
  var body: some View {
    HStack(spacing: 8) {
      if let image = item.image {
        Image(uiImage: image)
          .resizable()
          .scaledToFit()
          .frame(width: 32)
          .foregroundColor(Color(.tkAppTintColor))
      } else {
        Color.clear
          .frame(width: 32)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        if let distance {
          Text(distance)
            .foregroundColor(Color(.tkLabelPrimary))
            .font(Font(TKStyleManager.boldCustomFont(forTextStyle: .body)))
        }
        
        Text(item.streetInstruction)
          .foregroundColor(Color(.tkLabelSecondary))
          .font(Font(TKStyleManager.customFont(forTextStyle: .body)))
        
        FlowLayout(alignment: .leading, spacing: 4) {
          ForEach(Array(item.bubbles.enumerated()), id: \.offset) { _, item in
            Text(item.0)
              .font(Font(TKStyleManager.customFont(forTextStyle: .caption1)))
              .padding(.horizontal, 8)
              .foregroundColor(item.1.isDark ? .white : .black)
              .background(Capsule().foregroundColor(Color(item.1)))
          }
        }
      }
    }
  }
}

extension View {
  func modify<T: View>(@ViewBuilder _ modifier: (Self) -> T) -> some View {
    return modifier(self)
  }
}

struct TKUISegmentDirectionView_Previews: PreviewProvider {
  static var previews: some View {
    List {
      TKUISegmentDirectionView(item: .init(
        index: 0, streetName: "Along Southwest 5th Avenue", image: Shape.Instruction.turnSlightyLeft.image, distance: 1_000, bubbles: [
          ("Cycle Lane", .systemBlue), ("Designated for Cyclists", .systemBlue), ("Main Road", .systemOrange)
        ]
      ))

      TKUISegmentDirectionView(item: .init(
        index: 0, streetName: "Along Southwest 5th Avenue", image: Shape.Instruction.headTowards.image, distance: 600, bubbles: [
          ("Cycle Lane", .systemBlue), ("Designated for Cyclists", .systemBlue)
        ]
      ))
    }.listStyle(.plain)
  }
}
