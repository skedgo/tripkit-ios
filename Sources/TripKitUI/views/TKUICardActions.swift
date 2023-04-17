//
//  TKUICardActions.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/4/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI

import TGCardViewController

class TKUICardActionHandlerInfo<C, M> where C: TGCard {
  init(card: C, model: M, container: UIView) {
    self.card = card
    self.model = model
    self.container = container
  }
  
  weak var card: C!
  let model: M
  weak var container: UIView!
}

struct TKUIScrollingCardActions<C, M>: View where C: TGCard {
  let actions: [TKUICardAction<C, M>]
  let info: TKUICardActionHandlerInfo<C, M>
  
  var body: some View {
    ZStack {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          ForEach(actions, id: \.title) { action in
            TKUICardActionButton(action: action, info: info)
          }

          Spacer()
        }
        .padding(.horizontal)
      }
      .layoutPriority(1)
      
      HStack {
        Spacer()
        
        LinearGradient(gradient: Gradient(colors: [.clear, Color(.tkBackground)]), startPoint: .leading, endPoint: .trailing)
          .frame(width: 60)
      }
    }
  }
}

@available(iOS 16.0, *)
struct TKUIAdaptiveCardActions<C, M>: View where C: TGCard {
  let actions: [TKUICardAction<C, M>]
  let info: TKUICardActionHandlerInfo<C, M>
  
  var body: some View {
    ViewThatFits {
      HStack {
        ForEach(actions, id: \.title) { action in
          TKUICardActionButton(action: action, info: info)
        }
        
        Spacer()
      }
      .padding(.horizontal)
      
      TKUIScrollingCardActions(actions: actions, info: info)
    
//      HStack {
//        ForEach(actions, id: \.title) { action in
//          TKUICardActionButton(action: action, info: info, big: false)
//        }
//
//        Spacer()
//      }
//      .padding(.horizontal)
    }
  }
}


struct TKUICardActionButton<C, M>: View where C: TGCard {
  let action: TKUICardAction<C, M>
  let info: TKUICardActionHandlerInfo<C, M>
  var big: Bool = true
  
  @State private var changeCount: Int = 0
  
  var body: some View {
    Button {
      guard let card = info.card, let container = info.container else { return }
      let changed = action.handler(action, card, info.model, container)
      if changed {
        withAnimation {
          changeCount += 1
        }
      }
    } label: {
      HStack(spacing: 4) {
        Image(uiImage: action.icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 18, height: 18)
        
        if big {
          Text(action.title)
            .font(.subheadline.weight(.semibold))
        }
      }
      .id(changeCount) // Force update when action said it wants a redraw
      .accessibility(label: Text(action.accessibilityLabel))
      .padding(.horizontal, big ? 12 : 8)
      .padding(.vertical, 8)
    }
    .foregroundColor(action.style == .bold ? .white : .accentColor)
    .background(action.style == .bold ? Color.accentColor : Color.accentColor.opacity(0.15))
    .clipShape(Capsule())
//    .background(Capsule().stroke(Color.accentColor, lineWidth: 2))
  }
}

#if DEBUG

@MainActor
class PreviewData {
  static let shared = PreviewData()

  init() {
    self.card = TGNoCard(title: "Card", mapManager: TKUIMapManager())
    self.container = UIView()
    self.context = TKUICardActionHandlerInfo(card: card, model: "", container: container)
  }
  
  var isFavorite: Bool = false
  
  let card: TGNoCard
  let container: UIView
  let context: TKUICardActionHandlerInfo<TGNoCard, String>
}

@available(iOS 16.0, *)
struct TKUICardActions_Previews: PreviewProvider {
  
  static var previews: some View {
    Group {
      TKUIScrollingCardActions<TGNoCard, String>(actions: [
        .init(
          title: "Share",
          icon: .iconShare,
          handler: { _, _, _, _ in false }
        ),
      ], info: PreviewData.shared.context)

      TKUIScrollingCardActions<TGNoCard, String>(actions: [
        .init(
          title: "Go",
          icon: .iconCompass,
          style: .bold,
          handler: { _, _, _, _ in false }
        ),
        .init(
          title: { PreviewData.shared.isFavorite ? "Remove Favourite" : "Add Favourite" },
          icon: { UIImage(systemName: PreviewData.shared.isFavorite ? "star.slash.fill" : "star.fill")!.withRenderingMode(.alwaysTemplate) },
          handler: { _, _, _ in PreviewData.shared.isFavorite.toggle() }
        ),
        .init(
          title: "Share",
          icon: .iconShare,
          handler: { _, _, _, _ in false }
        ),
        .init(
          title: "Alternatives",
          icon: UIImage(systemName: "arrow.triangle.branch")!.withRenderingMode(.alwaysTemplate),
          handler: { _, _, _, _ in false }
        ),
      ], info: PreviewData.shared.context)
      
      
      VStack {
        TKUIAdaptiveCardActions<TGNoCard, String>(actions: [
          .init(
            title: "Go",
            icon: .iconCompass,
            style: .bold,
            handler: { _, _, _, _ in false }
          ),
          .init(
            title: { PreviewData.shared.isFavorite ? "Remove Favourite" : "Add Favourite" },
            icon: { UIImage(systemName: PreviewData.shared.isFavorite ? "star.slash.fill" : "star.fill")!.withRenderingMode(.alwaysTemplate) },
            handler: { _, _, _ in PreviewData.shared.isFavorite.toggle() }
          ),
          .init(
            title: "Share",
            icon: .iconShare,
            handler: { _, _, _, _ in false }
          ),
          .init(
            title: "Alternatives",
            icon: UIImage(systemName: "arrow.triangle.branch")!.withRenderingMode(.alwaysTemplate),
            handler: { _, _, _, _ in false }
          ),
        ], info: PreviewData.shared.context)
        
        TKUIAdaptiveCardActions<TGNoCard, String>(actions: [
          .init(
            title: "Go",
            icon: .iconCompass,
            style: .bold,
            handler: { _, _, _, _ in false }
          ),
          .init(
            title: { PreviewData.shared.isFavorite ? "Remove Favourite" : "Add Favourite" },
            icon: { UIImage(systemName: PreviewData.shared.isFavorite ? "star.slash.fill" : "star.fill")!.withRenderingMode(.alwaysTemplate) },
            handler: { _, _, _ in PreviewData.shared.isFavorite.toggle() }
          ),
          .init(
            title: "Share",
            icon: .iconShare,
            handler: { _, _, _, _ in false }
          ),
        ], info: PreviewData.shared.context)
        
        TKUIAdaptiveCardActions<TGNoCard, String>(actions: [
          .init(
            title: "Share",
            icon: .iconShare,
            handler: { _, _, _, _ in false }
          ),
        ], info: PreviewData.shared.context)
      }
      
      Spacer()
    }
    .accentColor(Color(.tkAppTintColor))
    .previewLayout(.fixed(width: 420, height: 200))
  }
}
#endif
