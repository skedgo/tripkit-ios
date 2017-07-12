//
//  SGTripSummaryCell.swift
//  TripKit
//
//  Created by Adrian Schoenig on 5/7/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation
import UIKit

import RxSwift

extension SGTripSummaryCell {
  
  @objc(configureForTrip:)
  public func objc_configureForTrip(_ trip: STKTrip) {
    self.configure(for: trip)
  }
  
  public func configure(for trip: STKTrip, nano: Bool = false, highlight: STKTripCostType = .count, faded: Bool = false, action: (title: String, handler: (UIControl) -> Void)? = nil) {
    
    _objcDisposeBag = SGObjCDisposeBag()
    
    if let action = action {
      _actionBlock = action.handler
      actionButton?.setTitle(action.title, for: .normal)
      actionButton?.isHidden = false
    } else {
      _actionBlock = nil
      actionButton?.isHidden = true
    }
    
    if let tkTrip = trip as? Trip {
      _tripAccessibilityLabel = tkTrip.accessibilityLabel
    }
    
    self._trip = trip

    // updating colours, adds all the text
    update(for: trip, nano: nano, highlight: highlight)
    
    // segments
    updateSegments(nano: nano)
    
    let alpha: CGFloat = faded ? 0.2 : 0.1
    mainLabel?.alpha = alpha
    segmentView?.alpha = alpha
    costsLabel?.alpha = alpha
    actionButton?.alpha = alpha
    
    guard !nano else { return }
    
    showTickIcon = false
    
    updateAlertStatus()
    
    // subscript to time notifcations
    guard let object = trip as? NSObject else { return }
    let departure = object.rx.observe(Date.self, "departureTime")
    let arrival = object.rx.observe(Date.self, "arrivalTime")
    Observable.merge([departure, arrival])
      .subscribe(onNext: { [weak self] _ in self?.updateForNewTimes(nano: nano) } )
      .addDisposableTo(_objcDisposeBag.disposeBag)
    
    object.rx.observe(Bool.self, "hasReminder")
      .subscribe(onNext: { [weak self] _ in self?.updateAlertStatus() } )
      .addDisposableTo(_objcDisposeBag.disposeBag)
  }
  
  public func update(for trip: STKTrip, nano: Bool = false, highlight: STKTripCostType = .count) {
    guard !nano else {
      if highlight == .time {
        let start = SGStyleManager.timeString(trip.departureTime, for: trip.departureTimeZone)
        let end = SGStyleManager.timeString(trip.arrivalTime, for: trip.arrivalTimeZone)
        mainLabel?.text = Loc.To(from: start, to: end)
      } else {
        mainLabel?.text = trip.costValues[NSNumber(value: highlight.rawValue)]
      }
      return
    }
    
    // time and duration
    
    if showCosts {
      _addCosts(trip.costValues)
    }
  }
  
  private func updateForNewTimes(nano: Bool) {
    updateTimeStrings()
    
    // inefficient, but let's just redraw the images as their real-time and warning status might have changed
    updateSegments(nano: nano)
  }
  
  private func updateSegments(nano: Bool) {
    segmentView?.allowWheelchairIcon = allowWheelchairIcon
    segmentView?.configure(forSegments: _trip.segments(with: .inSummary), allowSubtitles: !nano, allowInfoIcons: !nano)
  }
  
  private func updateTimeStrings() {
    _updateTimeString(forDeparture: _trip.departureTime, arrival: _trip.arrivalTime)
  }
  
  private func updateAlertStatus() {
    showAlertIcon = _trip?.hasReminder ?? false
  }
  
}
