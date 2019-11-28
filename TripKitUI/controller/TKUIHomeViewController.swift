//
//  TKUIHomeViewController.swift
//  TripKit-iOS
//
//  Created by Kuan Lun Huang on 28/11/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController

public class TKUIHomeViewController: TGCardViewController {
  
  public init() {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
  }
  
  required init?(coder: NSCoder) {
    super.init(nibName: "TGCardViewController", bundle: Bundle(for: TGCardViewController.self))
  }
  
  public override func viewDidLoad() {
    rootCard = TKUIHomeCard()
    super.viewDidLoad()
  }
  
}




