//
//  Trip+Shareable.swift
//  TripKit
//
//  Created by Adrian Schoenig on 30/6/17.
//  Copyright © 2017 SkedGo. All rights reserved.
//

import Foundation

#if TK_NO_MODULE
#else
  import TripKit
#endif

extension Trip: TKURLShareable, TKURLSavable {
}
