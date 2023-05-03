//
//  TKUICardActions.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 17/4/2023.
//  Copyright © 2023 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI
import Combine

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
    }
  }
}


struct TKUICardActionButton<C, M>: View where C: TGCard {
  init(action: TKUICardAction<C, M>, info: TKUICardActionHandlerInfo<C, M>, big: Bool = true) {
    self.action = action
    self.info = info
    self.big = big
  }
  
  @ObservedObject var action: TKUICardAction<C, M>
  let info: TKUICardActionHandlerInfo<C, M>
  var big: Bool = true
  
  var body: some View {
    Button {
      guard let card = info.card, let container = info.container else { return }
      withAnimation {
        let _ = action.handler(action, card, info.model, container)
      }
    } label: {
      HStack(spacing: 4) {
        Image(uiImage: action.content.icon)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 18, height: 18)
        
        if big {
          Text(action.content.title)
            .font(.subheadline.weight(.semibold))
        }
      }
      .accessibility(label: Text(action.content.accessibilityLabel ?? action.content.title))
      .padding(.horizontal, big ? 12 : 8)
      .padding(.vertical, 8)
    }
    .foregroundColor(action.content.style == .bold ? .white : .accentColor)
    .background(action.content.style == .bold ? Color.accentColor : Color.accentColor.opacity(0.15))
    .clipShape(Capsule())
//    .background(Capsule().stroke(Color.accentColor, lineWidth: 2))
  }
}

#if DEBUG

@MainActor
class PreviewData: ObservableObject {
  static let shared = PreviewData()

  init() {
    self.card = TGNoCard(title: "Card", mapManager: TKUIMapManager())
    self.container = UIView()
    self.context = TKUICardActionHandlerInfo(card: card, model: "", container: container)
  }
  
  @Published var isFavorite: Bool = false
  
  let card: TGNoCard
  let container: UIView
  let context: TKUICardActionHandlerInfo<TGNoCard, String>
  
  var content: AnyPublisher<TKUICardActionContent, Never> {
    _isFavorite.projectedValue
      .map { newValue in
        TKUICardActionContent(
          title: newValue ? "Remove Favourite" : "Add Favourite",
          icon: UIImage(systemName: newValue ? "star.slash.fill" : "star.fill")!.withRenderingMode(.alwaysTemplate) ,
          style: .normal
        )
      }
      .eraseToAnyPublisher()
  }
}

@available(iOS 16.0, *)
struct TKUICardActions_Previews: PreviewProvider {
  
  static var previews: some View {
    Group {
      VStack {
        TKUIAdaptiveCardActions<TGNoCard, String>(actions: [
          .init(
            title: "Go",
            icon: .iconCompass,
            style: .bold,
            handler: { _, _, _, _ in false }
          ),
          .init(content: PreviewData.shared.content) { _, _, _, _ in
            PreviewData.shared.isFavorite.toggle()
          },
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
          .init(content: PreviewData.shared.content) { _, _, _, _ in
            PreviewData.shared.isFavorite.toggle()
          },
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
        .init(content: PreviewData.shared.content) { _, _, _, _ in
          PreviewData.shared.isFavorite.toggle()
        },
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
      
      
    }
    .accentColor(Color(.tkAppTintColor))
    .previewLayout(.fixed(width: 420, height: 200))
  }
}
#endif
