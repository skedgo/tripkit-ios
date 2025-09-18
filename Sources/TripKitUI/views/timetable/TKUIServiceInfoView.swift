//
//  TKUIServiceInfoView.swift
//  TripKit
//
//  Created by Adrian Schönig on 25/8/2025.
//

import SwiftUI

import TripKit

struct TKUIServiceInfoView: View {
  struct Alert: Hashable {
    let isCritical: Bool
    let title: String
    var body: String? = nil
  }
  
  struct Content: Hashable {
    var wheelchairAccessibility: TKWheelchairAccessibility = .unknown
    var bicycleAccessibility: TKBicycleAccessibility = .unknown
    var alerts: [Alert] = []
    var vehicleComponents: [[TKAPI.VehicleComponents]] = [[]]
    var timestamp: Date? = nil
    
    var isEmpty: Bool {
      wheelchairAccessibility == .unknown
      && bicycleAccessibility == .unknown
      && alerts.isEmpty
      && (vehicleComponents.isEmpty || vehicleComponents.first?.isEmpty ?? true)
      && timestamp == nil
    }
  }
  
  let content: Content
  
  var body: some View {
    VStack(alignment: .leading) {
      if content.wheelchairAccessibility != .unknown {
        HStack {
          Image(uiImage: content.wheelchairAccessibility.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 20)
          Text(verbatim: content.wheelchairAccessibility.title)
            .font(.subheadline)
        }
      }

      if content.bicycleAccessibility != .unknown {
        HStack {
          if let icon = content.bicycleAccessibility.icon {
            Image(uiImage: icon)
              .resizable()
              .scaledToFit()
              .frame(width: 20)
          }
          if let title = content.bicycleAccessibility.title {
            Text(verbatim: title)
              .font(.subheadline)
          }
        }
      }
      
      if content.vehicleComponents.count > 1 || (content.vehicleComponents.first?.count ?? 0) > 1 {
        // Little trains
        TKUIVehicleOccupancyTrain(
          occupancies: content.vehicleComponents
            .map { $0.compactMap(\.occupancy) }
        )
        
      } else if let component = content.vehicleComponents.first?.first, let occupancy = component.occupancy, occupancy != .unknown {
        // Standing people
        HStack {
          if let image = occupancy.standingPeople() {
            Image(uiImage: image)
              .resizable()
              .scaledToFit()
              .frame(width: 20)
          }
          Text(verbatim: component.occupancyText ?? occupancy.localizedTitle)
            .font(.subheadline)

        }
      }
      
      if let updated = content.timestamp {
        Text("Updated \(updated, style: .relative) ago", tableName: "TripKit", bundle: .tripKit)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
      
      if !content.alerts.isEmpty, let sample = content.alerts.first {
        HStack {
          Image("icon-alert", bundle: .tripKitUI)
            .resizable()
            .scaledToFit()
            .frame(width: 20)
            .foregroundStyle(Color(uiColor: sample.isCritical ? .tkStateError : .tkStateWarning))
          VStack(alignment: .leading) {
            Text(verbatim: content.alerts.count > 1 ? Loc.Alerts(content.alerts.count) : sample.title)
              .font(.body)
            if let body = content.alerts.count > 1 ? sample.title: sample.body {
              Text(verbatim: body)
                .font(.footnote)
            }
          }
          Spacer()
          Image(systemName: "chevron.forward")
        }
        
//        Text(verbatim: alert.title)
      }
      
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .listRowBackground(content.alerts.isEmpty ? nil : Color(uiColor: .tkStateWarning).opacity(0.12))
  }
}

struct TKUIVehicleOccupancyTrain: View {
  var occupancies: [[TKAPI.VehicleOccupancy]]
  
  private func imageName(index: Int, count: Int) -> String {
    switch index {
    case 0: "icon-train-last-carriage"
    case count-1: "icon-train-head"
    default: "icon-train-carriage"
    }
  }
  
  var body: some View {
    HStack(spacing: 2) {
      ForEach(Array(occupancies.enumerated()), id: \.offset) { _, outer in
        ForEach(Array(outer.enumerated()), id: \.offset) { index, inner in
          Image(imageName(index: index, count: outer.count), bundle: .tripKitUI)
            .foregroundStyle(Color(uiColor: inner.color ?? .tkLabelTertiary))
        }
      }
    }
  }
}

#Preview("Wheelchair + Occupancy") {
  List {
    TKUIServiceInfoView(content: .init(
      wheelchairAccessibility: .accessible,
      vehicleComponents: [[.init(occupancy: .manySeatsAvailable)]],
      timestamp: Date()
    ))
  }
}

#Preview("Train w/ alert") {
  List {
    TKUIServiceInfoView(content: .init(
      wheelchairAccessibility: .accessible,
      bicycleAccessibility: .accessible,
      vehicleComponents: [[
        .init(occupancy: .manySeatsAvailable),
        .init(occupancy: .empty),
        .init(occupancy: .fewSeatsAvailable),
        .init(occupancy: .full),
      ], [
        .init(occupancy: .unknown),
        .init(occupancy: .empty),
        .init(occupancy: .standingRoomOnly),
        .init(occupancy: .full),
      ]],
      timestamp: Date()
    ))
    
    TKUIServiceInfoView(content: .init(
      alerts: [.init(isCritical: true, title: "Bus cancelled", body: "This bus has been cancelled and is not running today.")]
    ))
  }
}
