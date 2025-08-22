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
  /// Uses the `tkLabelPrimary` as the foreground colour, and `.tertiarySystemFill` as the background colour
  case monochrome
  
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

@MainActor
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
@MainActor
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

@MainActor
struct TKUICardActionButton<C, M>: View where C: TGCard {
  init(action: TKUICardAction<C, M>, info: TKUICardActionHandlerInfo<C, M>, includeText: Bool = true, normalStyle: TKUICardActionNormalStyle) {
    self.action = action
    self.info = info
    self.includeText = includeText
    self.normalStyle = normalStyle
  }
  
  @ObservedObject var action: TKUICardAction<C, M>
  let info: TKUICardActionHandlerInfo<C, M>
  var includeText: Bool = true
  let normalStyle: TKUICardActionNormalStyle
  
  var body: some View {
    Button {
      guard let card = info.card, let container = info.container else { return }
      withAnimation {
        let _ = action.handler(action, card, info.model, container)
      }
    } label: {
      HStack(spacing: 4) {
        if action.content.isInProgress {
          ProgressView()
            .frame(width: 20, height: 20)
        } else {
          Image(uiImage: action.content.icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
        }
        
        if includeText {
          Text(action.content.title)
            .font(.subheadline.weight(.semibold))
        }
      }
      .accessibility(label: Text(action.content.accessibilityLabel ?? action.content.title))
      .padding(.horizontal, includeText ? 14 : 7)
      .padding(.vertical, 7)
      .frame(minHeight: 40)
    }
    .disabled(action.content.isInProgress)
    .foregroundColor(
      action.content.style == .bold
        ? (UIColor.tkAppTintColor.isDark ? .white : .black)
        : Color(uiColor: .tkLabelPrimary)
    )
    .background(
      action.content.style == .bold
        ? Color.accentColor
        : (normalStyle == .monochrome ? Color(uiColor: .tertiarySystemFill) : .clear)
    )
    .clipShape(Capsule())
    .background(
      Capsule().stroke(
        Color(.tkLabelPrimary).opacity(0.1),
        lineWidth: action.content.style == .normal && normalStyle == .outline ? 2 : 0
      )
    )
    .opacity(action.content.isInProgress ? 0.3 : 1)
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
          icon: UIImage(systemName: newValue ? "star.slash.fill" : "star.fill")!.withRenderingMode(.alwaysTemplate)
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
        ], info: PreviewData.shared.context, normalStyle: .monochrome)
        
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
        ], info: PreviewData.shared.context, normalStyle: .monochrome)
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
      ], info: PreviewData.shared.context, normalStyle: .monochrome)
      
      
    }
    .accentColor(Color(.tkAppTintColor))
    .previewLayout(.fixed(width: 420, height: 200))
    .preferredColorScheme(.dark)
  }
}
#endif
