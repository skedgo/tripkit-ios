//
//  TKAccessibilityHelper.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 22/2/18.
//  Copyright © 2018 SkedGo. All rights reserved.
//

import Foundation
import RxSwift

/// This class provides information about what accessibility features we support.
/// in a given region. It currently only supports wheelchair. You can ask whether
/// wheelchair information is available, for instance.
@objc public class TKAccessibilityHelper: NSObject {
  
  let region: SVKRegion
  
  @objc public var isWheelchairInfoAvailable = false {
    didSet {
      rx_wheelchairInformationUpdated.onNext(())
    }
  }
  
  public let rx_wheelchairInformationUpdated = PublishSubject<Void>()
  
  private let disposeBag = DisposeBag()
  
  // MARK: -
  
  @objc public init(region: SVKRegion) {
    self.region = region
    super.init()
  }
  
  @objc public func fetchWheelchairSupportInformation() {
    
    TKBuzzInfoProvider.fetchRegionInformation(forRegion: region) { [weak self] info in
      let isAvailable = info?.transitWheelchairAccessibility ?? info?.streetWheelchairAccessibility ?? false
      self?.isWheelchairInfoAvailable = isAvailable
    }
    
  }
  
}


