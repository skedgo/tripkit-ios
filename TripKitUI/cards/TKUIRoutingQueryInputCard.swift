//
//  TKUIRoutingQueryInputCard.swift
//  TripKitUI-iOS
//
//  Created by Adrian Schönig on 22.10.19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift
import RxCocoa
import RxDataSources

#if TK_NO_MODULE
#else
  import TripKit
#endif

public class TKUIRoutingQueryInputCard: TGTableCard {
  
  
  private var viewModel: TKUIRoutingQueryInputViewModel!
  let disposeBag = DisposeBag()
  
}
