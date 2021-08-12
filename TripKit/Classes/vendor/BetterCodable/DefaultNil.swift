//
//  UnknownNil.swift
//  TripKit
//
//  Created by Adrian Schönig on 9/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct UnknownNilStrategy<T: Codable>: DefaultCodableStrategy {
  public static var defaultValue: T? { nil }
}

public typealias UnknownNil<T> = DefaultCodable<UnknownNilStrategy<T>> where T: Codable
