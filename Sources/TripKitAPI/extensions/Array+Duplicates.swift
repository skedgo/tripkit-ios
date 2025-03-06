//
//  Array+Duplicates.swift
//  TripKit
//
//  Created by Adrian Schönig on 01.11.20.
//  Copyright © 2020 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

extension Array {
  
  public func tk_filterDuplicates(includeElement: @escaping (_ lhs: Element, _ rhs: Element) -> Bool) -> [Element] {
    return reduce(into: []) { acc, element in
      if nil == acc.first(where: { includeElement(element, $0) }) {
        acc.append(element)
      }
    }
  }
}
