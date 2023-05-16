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

public enum TKUICardActionNormalStyle {
  /// Uses the `.tkAppTintColor` as the foreground colour, and also as the background colour with a opacity of 0.15
  case fadedTint
  
  /// Uses `.tkLabelPrimary` as the foreground colour, `.clear` as the background colour and adds
  /// an outline around the button of `.tkLabelPrimary` with 0.1 opacity
  case outline
}

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
  let normalStyle: TKUICardActionNormalStyle

  var body: some View {
    ZStack {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          ForEach(actions, id: \.title) { action in
            TKUICardActionButton(action: action, info: info, normalStyle: normalStyle)
          }

          Spacer()
        }
        .padding(.horizontal)
      }
      .layoutPriority(1)
      .background(Color(.tkBackground))

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
  let normalStyle: TKUICardActionNormalStyle
  
  var body: some View {
    ViewThatFits {
      HStack {
        ForEach(actions, id: \.title) { action in
          TKUICardActionButton(action: action, info: info, normalStyle: normalStyle)
        }
        
        Spacer()
      }
      .padding(.horizontal)
      .background(Color(.tkBackground))
      
      TKUIScrollingCardActions(actions: actions, info: info, normalStyle: normalStyle)
    }
  }
}


struct TKUICardActionButton<C, M>: View where C: TGCard {
  init(action: TKUICardAction<C, M>, info: TKUICardActionHandlerInfo<C, M>, big: Bool = true, normalStyle: TKUICardActionNormalStyle) {
    self.action = action
    self.info = info
    self.big = big
    self.normalStyle = normalStyle
  }
  
  @ObservedObject var action: TKUICardAction<C, M>
  let info: TKUICardActionHandlerInfo<C, M>
  var big: Bool = true
  let normalStyle: TKUICardActionNormalStyle
  
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
    .foregroundColor(action.content.style == .bold
                     ? .white
                     : (normalStyle == .fadedTint ? .accentColor : Color(.tkLabelPrimary)))
    .background(action.content.style == .bold
                ? Color.accentColor
                : (normalStyle == .fadedTint ? Color.accentColor.opacity(0.15) : .clear))
    .clipShape(Capsule())
    .background(
      Capsule().stroke(
        Color(.tkLabelPrimary).opacity(0.1),
        lineWidth: action.content.style == .normal && normalStyle == .outline ? 2 : 0
      )
    )
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
        ], info: PreviewData.shared.context, normalStyle: .fadedTint)
        
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
        ], info: PreviewData.shared.context, normalStyle: .outline)
        
        TKUIAdaptiveCardActions<TGNoCard, String>(actions: [
          .init(
            title: "Share",
            icon: .iconShare,
            handler: { _, _, _, _ in false }
          ),
        ], info: PreviewData.shared.context, normalStyle: .fadedTint)
      }
      
      TKUIScrollingCardActions<TGNoCard, String>(actions: [
        .init(
          title: "Share",
          icon: .iconShare,
          handler: { _, _, _, _ in false }
        ),
      ], info: PreviewData.shared.context, normalStyle: .outline)

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
      ], info: PreviewData.shared.context, normalStyle: .fadedTint)
      
      
    }
    .accentColor(Color(.tkAppTintColor))
    .previewLayout(.fixed(width: 420, height: 200))
  }
}
#endif
