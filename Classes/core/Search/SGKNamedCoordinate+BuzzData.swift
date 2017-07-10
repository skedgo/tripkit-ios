//
//  SGKNamedCoordinate+BuzzData.swift
//  SkedGoKit
//
//  Created by Adrian Schoenig on 25/10/16.
//  Copyright © 2016 SkedGo. All rights reserved.
//

import Foundation

public extension SGKNamedCoordinate {
  
  var reviewSummary: [String: Any]? {
    get { return data["reviewSummary"] as? [String: Any] }
    set { data["reviewSummary"] = newValue }
  }
  
  var what3words: String? {
    get { return data["what3words"] as? String }
    set { data["what3words"] = newValue }
  }
  
  var what3wordsInfoURL: String? {
    get { return data["what3wordsInfoURL"] as? String }
    set { data["what3wordsInfoURL"] = newValue }
  }
  
}
