//
//  TKUIAutocompletionResultView.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 27/3/2024.
//  Copyright © 2024 SkedGo Pty Ltd. All rights reserved.
//

import SwiftUI

import TripKit

struct TKUIAutocompletionResultView: View {
  typealias Item = TKUIAutocompletionViewModel.Item
  
  let item: Item
  var onAccessoryTapped: ((Item) -> Void)? = nil
  
  var body: some View {
    switch item {
    case .autocompletion(let autocompletionItem):
      let result = autocompletionItem.completion

      HStack {
        Image(uiImage: result.image)
          .resizable()
          .scaledToFit()
          .frame(width: 19)
          .foregroundStyle(Color(uiColor: .tkLabelTertiary))
          .accessibilityHidden(true)
        
        VStack(alignment: .leading) {
          Text.build(result.title, highlightRanges: result.titleHighlightRanges, textColor: .tkLabelPrimary)
          
          if let subtitle = result.subtitle, !subtitle.isEmpty {
            Text.build(subtitle, highlightRanges: result.subtitleHighlightRanges, textColor: .tkLabelSecondary)
          }
        }
        .accessibilityElement()
        .accessibilityLabel("\(result.title), \(result.subtitle ?? "")")
        .accessibilityHint(Loc.TapToSelectAddress)
        .accessibilityAddTraits(.isButton)
        
        Spacer(minLength: 0)
        
        if let accessory = autocompletionItem.accessoryImage, let onAccessoryTapped {
          Button {
            onAccessoryTapped(item)
            
          } label: {
            Image(uiImage: accessory)
              .resizable()
              .scaledToFit()
              .frame(width: 24)
              .foregroundStyle(Color(uiColor: .tkLabelTertiary))
              .accessibilityLabel(Loc.MoreLocationInfo(result.title))
              .accessibilityHint(Loc.TapToLearnLocationInfo)
          }
        }
      }
      .opacity(autocompletionItem.showFaded ? 0.33 : 1)

    case .action(let action):
      HStack {
        Image(uiImage: TKAutocompletionResult.image(for: .currentLocation))
          .resizable()
          .scaledToFit()
          .frame(width: 19)
          .opacity(0) // just for consistent sizing
        
        Text(verbatim: action.title)
          .bold()
      }
      
    case .currentLocation:
      HStack {
        Image(uiImage: TKAutocompletionResult.image(for: .currentLocation))
          .resizable()
          .scaledToFit()
          .frame(width: 19)
          .foregroundStyle(Color(uiColor: .tkLabelTertiary))
        
        Text(verbatim: Loc.CurrentLocation)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel(Loc.CurrentLocation)
      .accessibilityHint(Loc.TapToSelectCurrentLocation)
      .accessibilityAddTraits(.isButton)
      
    }
  }
}

extension Text {
  @ViewBuilder
  static func build(_ text: String, highlightRanges: [NSRange], textColor: UIColor) -> some View {
    if highlightRanges.isEmpty {
      Text(verbatim: text)
        .foregroundStyle(Color(uiColor: textColor))
    } else {
      let attributed: NSAttributedString = {
        let attributed = NSMutableAttributedString(string: text, attributes: [
          .foregroundColor: textColor,
          .font: TKStyleManager.customFont(forTextStyle: .body),
        ])
        for range in highlightRanges {
          attributed.addAttribute(.font, value: TKStyleManager.boldCustomFont(forTextStyle: .body), range: range)
        }
        return attributed
      }()
      
      Text(AttributedString(attributed))
    }
  }
}

#Preview {
  TKUIAutocompletionResultView(
    item: .autocompletion(.init(
      index: 0,
      completion: TKAutocompletionResult(
        object: "",
        title: "Alfred Deaking High School",
        titleHighlightRanges: [
          .init(location: 0, length: 3)
        ],
        subtitle: "Near some street in Canberra",
        image: TKStyleManager.image(systemName: "graduationcap.fill")!
      ),
      includeAccessory: true
    )),
    onAccessoryTapped: { _ in }
  )
}
