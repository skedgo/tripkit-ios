//
//  TGAgendaWidgetInfoView.swift
//  TripGo
//
//  Created by Kuan Lun Huang on 11/09/2016.
//  Copyright © 2016 SkedGo Pty Ltd. All rights reserved.
//

import UIKit

public class TKAgendaWidgetInfoView: UIView {
  
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var subtitleLabel: UILabel!
  
  public static func makeView() -> TKAgendaWidgetInfoView {
    let bundle = Bundle(for: self)
    return bundle.loadNibNamed("TKAgendaWidgetInfoView", owner: self, options: nil)?.first as! TKAgendaWidgetInfoView
  }
  
  // MARK: - 
  
  override public func awakeFromNib() {
    super.awakeFromNib()
    
    imageView.backgroundColor = SGStyleManager.globalTintColor()
    imageView.tintColor = UIColor.white
    imageView.layer.cornerRadius = 30
    imageView.layer.masksToBounds = true
    imageView.contentMode = .center
  }
  
  // MARK: - Configurations
  
  public func configureForNoUpcomingTrip() {
    imageView.image = UIImage(named: "icon-agenda", in: bundle(), compatibleWith: nil)
    titleLabel.text = NSLocalizedString("No planned trips", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Indicating no trips have been planned within 24 hrs")
    subtitleLabel.text = NSLocalizedString("Plan a trip in TripGo and it will show up here.", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
  }
  
  public func configure(for error: NSError) {
    titleLabel.text = error.localizedDescription
    subtitleLabel.text = error.localizedRecoverySuggestion
  }
  
  public func configureForLoading() {
    titleLabel.text = NSLocalizedString("Loading...", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "Title to show while loading/waiting for results")
    subtitleLabel.text = NSLocalizedString("We are busy getting your upcoming trip. Please wait...", tableName: "TripKit", bundle: TKTripKit.bundle(), comment: "")
  }
  
  // MARK: - Utilities
  
  private func bundle() -> Bundle {
    return Bundle(for: TKAgendaWidgetInfoView.self)
  }
  
}
