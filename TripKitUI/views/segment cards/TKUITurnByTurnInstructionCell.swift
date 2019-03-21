//
//  TKUITurnByTurnInstructionCell.swift
//  TripKitUI-iOS
//
//  Created by Kuan Lun Huang on 21/3/19.
//  Copyright © 2019 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKUITurnByTurnInstructionCell: UITableViewCell {
  
  public struct ContentModel {
    public let mainInstruction: String
    public let supplementalInfo: String?
    public let directionImage: UIImage?
    
    public init(mainInstruction: String, supplementalInfo: String? = nil, directionImage: UIImage? = nil) {
      self.mainInstruction = mainInstruction
      self.supplementalInfo = supplementalInfo
      self.directionImage = directionImage
    }
  }
  
  @IBOutlet private weak var instructionLabelStack: UIStackView!
  
  @IBOutlet weak var directionImageView: UIImageView!
  @IBOutlet weak var mainInstructionLabel: UILabel!
  @IBOutlet weak var supplementalInfoLabel: UILabel!
  
  static let reuseIdentifier = "TurnByTurnInstructionCell"
  static var nib = UINib(nibName: "TKUITurnByTurnInstructionCell", bundle: .tripKitUI)
  
  var content: ContentModel? {
    didSet {
      updateCellContent()
    }
  }
  
  public override func awakeFromNib() {
    super.awakeFromNib()
    
    mainInstructionLabel.font = TKStyleManager.semiboldCustomFont(forTextStyle: .body)
    supplementalInfoLabel.font = TKStyleManager.customFont(forTextStyle: .footnote)
  }

  public override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
  }
  
  private func updateCellContent() {
    guard let content = content else { return }
    
    mainInstructionLabel.text = content.mainInstruction
    supplementalInfoLabel.text = content.supplementalInfo
    directionImageView.image = content.directionImage
    
    instructionLabelStack.spacing = content.supplementalInfo == nil ? 0 : 4
  }
    
}
