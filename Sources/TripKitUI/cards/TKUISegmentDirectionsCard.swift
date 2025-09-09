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

public class TKUISegmentDirectionsCard: TGTableCard {
  
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
    
    super.init(title: .custom(titleView, dismissButton: titleView.dismissButton), mapManager: mapManager)
    
    titleView.applyStyleToCloseButton(style)
  }
  
  override public func didBuild(tableView: UITableView) {
    super.didBuild(tableView: tableView)

    viewModel = TKUISegmentDirectionsViewModel(segment: segment)
    
    tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Default")
    
    let dataSource = RxTableViewSectionedAnimatedDataSource<TKUISegmentDirectionsViewModel.Section>(configureCell: TKUISegmentDirectionsCard.configureCell)
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    if let factory = Self.config.actionFactory {
      let actions = factory(segment)
      let actionsView = TKUICardActionsViewFactory.build(actions: actions, card: self, model: segment, container: tableView)
      actionsView.frame.size.height = actionsView.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
      tableView.tableHeaderView = actionsView
    } else {
      tableView.tableHeaderView = nil
    }
  }
  
  private func setup(_ tableView: UITableView) {
    tableView.tableFooterView = UIView()
  }
  
  public override func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    TKUIEventCallback.handler(.cardAppeared(self))
  }
  
}

// MARK: Configuring cells

extension TKUISegmentDirectionsCard {
  
  static func configureCell(dataSource: TableViewSectionedDataSource<TKUISegmentDirectionsViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUISegmentDirectionsViewModel.Item) -> UITableViewCell {

    let cell = tableView.dequeueReusableCell(withIdentifier: "Default", for: indexPath)
    cell.contentConfiguration = UIHostingConfiguration {
      TKUISegmentDirectionView(item: item)
    }
    cell.backgroundColor = .tkBackground
    return cell
  }
  
}

@MainActor
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
    }.background(Color(.tkBackground))
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
