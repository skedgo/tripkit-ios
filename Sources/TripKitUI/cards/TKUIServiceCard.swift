//
//  TKUIServiceCard.swift
//  TripKitUI
//
//  Created by Adrian Schönig on 18.07.18.
//  Copyright © 2018 SkedGo Pty Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import Combine

import TGCardViewController

import TripKit

/// A card that lists the route of an individual public transport
/// service. Starts at the provided embarkation and optionally
/// highlights where to get off.
public class TKUIServiceCard: TGHostingCard<TKUIServiceContent> {
  
  public static var config = Configuration.empty
  
  private var dataInput: TKUIServiceViewModel.DataInput
  private let viewModel: TKUIServiceViewModel
  private let serviceMapManager: TKUIServiceMapManager
  private var cancellables = Set<AnyCancellable>()

  private let titleView: TKUIServiceTitleView?
  private weak var scrollView: UIScrollView?
  private let rectStorage: RectStorage
  
  /// Configures a new instance that will fetch the service details
  /// and the show them in the list and on the map.
  ///
  /// - Parameters:
  ///   - embarkation: Where to get onto the service
  ///   - disembarkation: Where to get off the service (optional)
  public convenience init(titleView: (UIView, UIButton)? = nil, embarkation: StopVisits, disembarkation: StopVisits? = nil, reusing: TKUITripMapManager? = nil) {
    self.init(titleView: titleView, dataInput: .visits(embarkation: embarkation, disembarkation: disembarkation), reusing: reusing)
  }
  
  /// Configures a new instance that will fetch the service details for the provided public transport segment
  /// and the show them in the list and on the map.
  ///
  /// - Note: When initialised this `config.serviceActionsFactory` is not used.
  ///
  /// - Parameters:
  ///   - segment: A public transport segment. Will not work when provided with a different type of segment.
  public convenience init(titleView: (UIView, UIButton)? = nil, publicTransportSegment segment: TKSegment, reusing: TKUITripMapManager? = nil) {
    assert(segment.isPublicTransport)
    self.init(titleView: titleView, dataInput: .segment(segment), reusing: reusing)
  }
  
  private init(titleView: (UIView, UIButton)? = nil, dataInput: TKUIServiceViewModel.DataInput, reusing: TKUITripMapManager? = nil) {
    self.dataInput = dataInput
    
    let title: CardTitle
    if let view = titleView {
      title = .custom(view.0, dismissButton: view.1)
      self.titleView = nil
    } else {
      let header = TKUIServiceTitleView.newInstance()
      title = .custom(header, dismissButton: header.dismissButton)
      self.titleView = header
    }
    
    let serviceMapManager = TKUIServiceMapManager()
    let mapManager: TGMapManager
    if let trip = reusing {
      mapManager = TKUIComposingMapManager(composing: serviceMapManager, onTopOf: trip)
    } else {
      mapManager = serviceMapManager
    }
    self.serviceMapManager = serviceMapManager
    
    let viewModel = TKUIServiceViewModel(dataInput: dataInput)
    serviceMapManager.viewModel = viewModel
    self.viewModel = viewModel
    
    let wrapper = RectStorage()
    self.rectStorage = wrapper
    
    super.init(
      title: title,
      rootView: TKUIServiceContent(model: viewModel, rectWrapper: wrapper),
      mapManager: mapManager,
      initialPosition: .peaking
    )
    
    if case .custom(_, .some(let dismissButton)) = title {
      TGCard.configureCloseButton(dismissButton, style: style)
    }

    if let knownMapManager = mapManager as? TKUIMapManager {
      knownMapManager.attributionDisplayer = { [weak self] sources, sender in
        let displayer = TKUIAttributionTableViewController(attributions: sources)
        self?.controller?.present(displayer, inNavigator: true, preferredStyle: .popover, sender: sender)
      }
    }
  }
  
  // MARK: - Card life cycle

  public override func didBuild(scrollView: UIScrollView) {
    super.didBuild(scrollView: scrollView)
    
    self.scrollView = scrollView
    
    if #unavailable(iOS 26.0) {
      scrollView.backgroundColor = .tkBackgroundGrouped
    }
    
    if let titleView = self.titleView, let factory = Self.config.serviceActionsFactory, case let .visits(embarkation, disembarkation) = dataInput {
      let pair: TKUIServiceCard.EmbarkationPair = (embarkation, disembarkation)
      let actions = factory(pair)

      let actionsView = TKUICardActionsViewFactory.build(
        actions: actions, card: self, model: pair, container: scrollView
      )
      actionsView.backgroundColor = .clear
      titleView.accessoryStack.addArrangedSubview(actionsView)
    }
    
    if let titleView {
      viewModel.$header
        .compactMap { $0 }
        .sink { [weak titleView] in titleView?.configure(with: $0) }
        .store(in: &cancellables)
    }
    
    viewModel.$next
      .compactMap(\.self)
      .sink { [weak self] in self?.handle($0) }
      .store(in: &cancellables)

    if rectStorage.infoFrame != nil {
      scrollToEmbarkation(animated: false)
    } else {
      rectStorage.didSetInitialFrame = { [weak self] in
        self?.scrollToEmbarkation(animated: false)
      }
    }
    
    scrollView.delegate = self
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
  
  private func handle(_ next: TKUIServiceViewModel.Next) {
    switch next {
    case .showAlerts(let alerts):
      let alertController = TKUIAlertViewController(style: .plain)
      alertController.alerts = alerts
      self.controller?.present(alertController, inNavigator: true)
    }
  }
  
  private func scrollToEmbarkation(animated: Bool) {
    guard let scrollView, let rect = rectStorage.infoFrame else { return }
    scrollView.setContentOffset(rect.origin, animated: animated)
  }
  
}

private class RectStorage {
  var infoFrame: CGRect? {
    didSet {
      if oldValue == nil, infoFrame != nil {
        didSetInitialFrame()
      }
    }
  }
  
  var didSetInitialFrame: () -> Void = { }
}

// MARK: - UIScrollViewDelegate

extension TKUIServiceCard: UIScrollViewDelegate {

  public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
    guard scrollView == self.scrollView else {
      return true
    }
    
    scrollToEmbarkation(animated: true)
    return false
  }
  
}

// MARK: - Content

public struct TKUIServiceContent: View {
  @ObservedObject var model: TKUIServiceViewModel
  fileprivate weak var rectWrapper: RectStorage?
  
  public var body: some View {
    VStack(alignment: .leading) {
      if let sections = model.sections {
        ForEach(sections) { section in
          VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(section.items.enumerated()), id: \.element) { index, item in
              switch item {
              case .info(let content):
                TKUIServiceInfoView(content: content)
                  .padding()
                  .onTapGesture {
                    try? model.selected(item)
                  }
                  .background(GeometryReader { proxy in
                    Color.clear.preference(
                      key: RectPreferenceKey.self,
                      value: proxy.frame(in: .named("content-stack"))
                    )
                  })

              case .timing(let content):
                TKUIServiceItemView(item: content)
                  .onTapGesture {
                    try? model.selected(item)
                  }
                
                if index < section.items.count - 1 {
                  Divider()
                }
              }
              
            }
          }
          .background(Color(.tkBackgroundNotClear))
          .cornerRadius(22)
        }
      } else {
        HStack {
          ProgressView()
          Text(verbatim: Loc.LoadingDotDotDot)
          Spacer()
        }
      }
    }
    .padding()
    .coordinateSpace(name: "content-stack")
    .onPreferenceChange(RectPreferenceKey.self) { rect in
      rectWrapper?.infoFrame = rect
    }
    .modify { view in
      if #available(iOS 26.0, *) {
        view
          .background(.clear)
      } else {
        view
          .background(Color(.tkBackgroundGrouped))
      }
    }
    .task {
      try? await model.populate()
    }
  }
}

struct RectPreferenceKey: PreferenceKey {
  static var defaultValue: CGRect? = nil
  static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
    value = nextValue() ?? value
  }
}

private struct TKUIServiceItemView: View {
  let item: TKUIServiceViewModel.TimingItem
  
  @ViewBuilder
  var timingContent: some View {
    let textColor = item.isVisited ? item.realTimeStatus.color : .tkLabelTertiary
    
    switch item.timing {
    case .timetabled(let arrival, let departure):
      let arrivalText = arrival.map { TKStyleManager.timeString($0, for: item.timeZone) }
      let departureText = departure.map { TKStyleManager.timeString($0, for: item.timeZone) }
      if let arrivalText, arrivalText != departureText {
        Text(verbatim: arrivalText)
          .accessibilityLabel(Text(verbatim: Loc.Arrives(atTime: arrivalText)))
          .foregroundStyle(Color(textColor))
      }
      
      if let departureText {
        Text(verbatim: departureText)
          .accessibilityLabel(Text(verbatim: Loc.Departs(atTime: departureText)))
          .foregroundStyle(Color(textColor))
      }

    case .frequencyBased:
      // LATER: Could show the travel time here, but that should show not at
      //        the stop but in between stops.
      EmptyView()
      
    @unknown default:
      let _ = assertionFailure("Please update TripKit dependency.")
      EmptyView()
    }
  }
  
  var body: some View {
    HStack(spacing: 12) {
      VStack {
        timingContent
      }
      .font(.footnote.weight(.semibold))
      .frame(width: 68, alignment: .center)

      VStack(spacing: 0) {
        Rectangle()
          .fill(Color(item.topConnection ?? .clear))
          .frame(width: 16)
          .padding(.bottom, -8)

        Circle()
          .fill(Color(item.bottomConnection ?? item.topConnection ?? .clear))
          .frame(width: 16, height: 16)
          .modify { view in
            // Only draw appropriate part of the circle to not draw some
            // alpha over another which isn't pretty.
            if item.bottomConnection == item.topConnection {
              view
                .opacity(0)
            } else if item.topConnection == nil {
              view
                .mask(alignment: .top) { Rectangle().frame(width: 16, height: 8) }
            } else if item.bottomConnection == nil {
              view
                .mask(alignment: .bottom) { Rectangle().frame(width: 16, height: 8) }
            } else {
              view
            }
          }
          .overlay {
            Circle()
              .fill(.white)
              .padding(4)
          }
          .zIndex(2)

        Rectangle()
          .fill(Color(item.bottomConnection ?? .clear))
          .frame(width: 16)
          .padding(.top, -8)
      }
      
      VStack(alignment: .leading, spacing: 4) {
        Text(verbatim: item.title)
          .foregroundStyle(item.isVisited ? .primary : .tertiary)
        
        if item.stopAccessibility.showInUI(), item.stopAccessibility == .notAccessible {
          HStack(spacing: 8) {
            Image(uiImage: item.stopAccessibility.icon)
              .frame(width: 16, height: 16)
              .opacity(item.isVisited ? 1 : 0.3)
            Text(verbatim: item.stopAccessibility.title)
              .font(.footnote)
              .foregroundStyle(item.isVisited ? .secondary : .tertiary)
              
          }
        }
      }
      .padding(.vertical, 12)
      
      Spacer(minLength: 0)
    }
    .frame(minHeight: 52)
  }
}

#if DEBUG
@available(iOS 18.0, *)
#Preview {
  @Previewable @State var visit: StopVisits?
  
  ZStack {
    if let visit {
      ScrollView {
        TKUIServiceContent(model: .init(dataInput: .visits(embarkation: visit, disembarkation: nil)))
      }
      .background(Color.gray.opacity(0.05))

    } else {
      ProgressView()
        .task {
          let rawService = """
            {"shapes":[{"travelled":true,"encodedWaypoints":"x~xmEuq{y[gCwC]S]K_A]_@Ke@Gw@SaASm@Ie@Oc@KmCe@eASsAO_@EuD[aANkA^eEnCm@l@{BzCw@l@g@N{AD{AQqA]gCMqDSyLdC_BRyMv@qA@qBQkDVmCRaB^kHf@cCOgAc@cA{@yAgC[mAO_B?aBd@uLl@mNPmBNeAN{@Xq@Tc@Z]^[b@Ud@Qt@Ev@Dd@Fd@N~ChCbClCzAlB|@f@n@Tz@L`VtBpBRjJ`AnGdAhEvAvAl@tCvAXNdClAf@Jj@HdBFjAPt@Pv@Vn@L`CV`@DrARfARdGbApB\\\\^HrAb@|Af@r@v@hFtDUM|I|JxMbQtEtDxHjInH`MvDbLvKtb@~AdD`GlHhInEjEtAbWbFdDdBpBdBtDnFxKpi@bDrHf\\\\bh@","stops":[{"lat":-33.88412,"lng":151.20683,"code":"2000337","name":"Central Station","bearing":0,"wheelchairAccessible":true,"pickUpOnly":true,"dropOffOnly":false,"departure":1758774751},{"lat":-33.87368,"lng":151.20679,"code":"2000396","name":"Town Hall Station","bearing":354,"wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758774918,"departure":1758774978},{"lat":-33.86591,"lng":151.20584,"code":"2000406","name":"Wynyard Station","bearing":44,"wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758775080,"departure":1758775140},{"lat":-33.86126,"lng":151.21029,"code":"2000352","name":"Circular Quay Station","bearing":170,"wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758775260,"departure":1758775290},{"lat":-33.87072,"lng":151.21193,"code":"2000382","name":"St James Station","bearing":199,"wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758775458,"departure":1758775488},{"lat":-33.87619,"lng":151.20998,"code":"2000372","name":"Museum Station","bearing":198,"wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758775572,"departure":1758775602},{"lat":-33.88434,"lng":151.20723,"code":"2000342","name":"Central Station","bearing":227,"wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758775740,"departure":1758775980},{"lat":-33.89207,"lng":151.19889,"code":"2015138","name":"Redfern Station","bearing":238,"wheelchairAccessible":false,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758776130,"departure":1758776190},{"lat":-33.90032,"lng":151.18543,"code":"204332","name":"Erskineville Station","bearing":215,"wheelchairAccessible":false,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758776340,"departure":1758776400},{"lat":-33.9073,"lng":151.1805,"code":"204462","name":"St Peters Station","bearing":242,"wheelchairAccessible":false,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758776490,"departure":1758776550},{"lat":-33.91423,"lng":151.16702,"code":"204474","name":"Sydenham Station","wheelchairAccessible":true,"pickUpOnly":false,"dropOffOnly":false,"arrival":1758776700}],"operator":"Sydney Trains","operatorID":"au-nsw-sydney-trains-SydneyTrains","serviceTripID":"18-P.817.150.116.B.8.86595248_XxX_INTERCHANGE_XxX_1_pos_2_3","serviceName":"T8 Airport & South Line","serviceNumber":"T8","serviceShortName":"","serviceDirection":"Sydenham","routeID":"APS_1e","serviceColor":{"red":0,"green":149,"blue":76},"bicycleAccessible":true,"wheelchairAccessible":true}],"type":"train","modeInfo":{"identifier":"pt_pub_train","alt":"train","localIcon":"train","color":{"red":222,"green":118,"blue":0}},"realtimeVehicle":{"lastUpdate":1758775157,"id":"18-P.817.116","label":"14:32 Central Station to Sydenham Station ","location":{"lat":-33.86379,"lng":151.20547,"bearing":351},"occupancy":"MANY_SEATS_AVAILABLE","components":[[{"occupancy":"MANY_SEATS_AVAILABLE","occupancyText":"Space available"}]]}}
            """
          
          let response = try! JSONDecoder().decode(TKAPI.ServiceResponse.self, from: Data(rawService.utf8))
          
          let context = TripKit.shared.tripKitContext
          let service = Service.fetchOrInsert(code: response.shapes!.first!.serviceTripID!, in: context)
          TKBuzzInfoProvider.addContent(from: response, to: service)
          visit = service.sortedVisits[3]
        }
    }
  }
}
#endif
