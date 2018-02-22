//
//  TKAccessibilityHelper.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 22/2/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation
import RxSwift

@objc public class TKAccessibilityHelper: NSObject {
  
  let region: SVKRegion
  
  @objc public var isWheelchairAvailable: Bool {
    return rx_wheelchairAvailable.value
  }
  
  private let rx_regionInfo: Variable<API.RegionInfo?> = Variable(nil)
  private let rx_wheelchairAvailable = Variable(false)
  public let rx_wheelchairAvailabilityUpdated = PublishSubject<Bool>()
  
  private let disposeBag = DisposeBag()
  
  // MARK: -
  
  @objc public init(region: SVKRegion) {
    self.region = region
    
    super.init()
    
    rx_regionInfo.asObservable()
      .map { $0?.transitWheelchairAccessibility ?? $0?.streetWheelchairAccessibility ?? false }
      .subscribe(onNext: { [weak self] in
        self?.rx_wheelchairAvailable.value = $0
        self?.rx_wheelchairAvailabilityUpdated.onNext(true)
      })
      .disposed(by: disposeBag)
    
    TKBuzzInfoProvider.fetchRegionInformation(forRegion: region) { [weak self] info in
      self?.rx_regionInfo.value = info
    }
  }
  
}


