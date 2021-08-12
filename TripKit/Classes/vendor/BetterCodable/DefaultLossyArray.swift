//
//  DefaultLossyArray.swift
//  TripKit
//
//  Created by Adrian Schönig on 9/8/21.
//  Copyright © 2021 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

public struct DefaultLossyArray<T: Codable>: DefaultCodableStrategy {
  public static var defaultValue: LossyArray<T> { .init(wrappedValue: []) }
}

public typealias EmptyLossyArray<T> = DefaultCodable<DefaultLossyArray<T>> where T: Codable
