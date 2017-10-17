//
//  TKUIResulstCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
//

import Foundation

import TGCardViewController
import RxSwift
import RxDataSources

#if TK_NO_MODULE
#else
  import TripKit
#endif

public class TKUIResultsCard: TGTableCard {
  
  fileprivate let dataSource = RxTableViewSectionedAnimatedDataSource<ResultSection>(
    configureCell: { ds, tv, ip, item in
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      let trip = item.trip
      cell.textLabel?.text = trip.debugString()
      cell.imageView?.image = (trip.mainSegment() as STKTripSegment).tripSegmentModeImage
      return cell
    }
  )
  
  fileprivate let cardModel: TKUIResultsCardModel
  fileprivate let disposeBag = DisposeBag()
  
  fileprivate let accessoryView = TKUIResultsAccessoryView.instantiate()

  
  public init(destination: MKAnnotation, initialPosition: TGCardPosition? = nil /* keep same as before (so that user can drop another pin */) {
    cardModel = TKUIResultsCardModel(destination: destination)
    let mapManager = TKUIResultsMapManager(model: cardModel)
    
    let title: String
    if let wrapped = destination.title, let name = wrapped {
      title = Loc.To(location: name)
    } else {
      // TODO: Localise
      title = "Plan Trip"
    }
    
    super.init(
      title: title,
      dataSource: dataSource, accessoryView: accessoryView, mapManager: mapManager,
      initialPosition: initialPosition
    )
  }
  
  
  public init(request: TripRequest, initialPosition: TGCardPosition? = .extended /* show fully as we'll have routes shortly */) {
    cardModel = TKUIResultsCardModel(request: request)
    let mapManager = TKUIResultsMapManager(model: cardModel)
    
    super.init(
      // TODO: Localise
      title: "Routes",
      dataSource: dataSource, accessoryView: accessoryView, mapManager: mapManager,
      initialPosition: initialPosition
    )
  }
  
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard let cardView = cardView as? TGTableCardView else {
      preconditionFailure()
    }
    
    bindViewConfigurations(cardView: cardView)
    
    bindLogic()
    
    bindInteractions(cardView: cardView)
  }
  
  
  override public func didAppear(animated: Bool) {
    super.didAppear(animated: animated)
    
    // FIXME: Move to a delegate
    // SGScreenshotFeedback.sharedInstance.object = cardModel.request
  }
  

  fileprivate func bindViewConfigurations(cardView: TGTableCardView) {

    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    cardView.tableView.dataSource = nil
    
    cardModel.sections
      .bind(to: cardView.tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    cardModel.timeTitle
      .bind(to: accessoryView.timeButton.rx.title(for: .normal))
      .disposed(by: disposeBag)
  }
  
  
  fileprivate func bindLogic() {
    // Monitor progress (note: without this, we won't fetch!)
    cardModel.fetchProgress
      .debug()
      .subscribe(onNext: { progress in
        // TODO: Indicate loading state
      })
      .disposed(by: disposeBag)
    
    cardModel.error
      .subscribe(onNext: { [unowned self] error in
        guard
          let controller = self.controller, self.viewIsVisible
          else { return }
        
        // TODO: Show the nice error again
        //        if (error as NSError).code == 1001 {
        //          self.showRoutingSupportView(with: error)
        //        } else {
        // FIXME: Move to a delegate
        // FeedbackHelper.showAlert(forError: error, withSupportFor: nil, for: controller)
        //        }
      })
      .disposed(by: disposeBag)
    
  }
  
  
  fileprivate func bindInteractions(cardView: TGTableCardView) {
   
    cardView.tableView.rx.itemSelected
      .subscribe(onNext: { [unowned self] in
        self.pushNext(for: self.dataSource[$0])
      })
      .disposed(by: disposeBag)
    
    accessoryView.timeButton.rx.tap.withLatestFrom(cardModel.rx_routeBuilder)
      .subscribe(onNext: { [unowned self] builder in
        self.showTimePicker(time: builder.time, timeZone: builder.timeZone, sender: self.accessoryView.timeButton) { newTime in
          self.cardModel.selected(newTime)
        }
      })
      .disposed(by: disposeBag)
    
    accessoryView.transportButton.rx.tap
      .subscribe(onNext: { [unowned self] in
        // FIXME: Show again
//        self.showTransportOptions(sender: self.accessoryView.transportButton)
      })
      .disposed(by: disposeBag)
    
  }
  
  
  fileprivate func pushNext(for item: ResultItem) {
    
    controller?.push(TGPageCard(overviewsHighlighting: item.trip))
    
  }
}


// MARK: - Picking times

fileprivate extension TKUIResultsCard {
  
  func showTimePicker(time: TKUIResultsCardModel.RouteBuilder.Time, timeZone: TimeZone, sender: UIView, onChange: @escaping (TKUIResultsCardModel.RouteBuilder.Time) -> Void) {
    
    guard let controller = controller else {
      preconditionFailure("Shouldn't be able to show time picker!")
    }
    
    let picker = TKUITimePickerSheet(time: time.date, timeType: time.timeType, timeZone: timeZone)
    picker.selectAction = { timeType, date in
      onChange(TKUIResultsCardModel.RouteBuilder.Time(timeType: timeType, date: date))
    }
    
    if controller.traitCollection.horizontalSizeClass == .regular {
      picker.delegate = self
      
      let pickerController = TKUISheetViewController(sheet: picker)
      pickerController.modalPresentationStyle = .popover
      let presenter = pickerController.popoverPresentationController
      presenter?.sourceView = controller.view
      presenter?.sourceRect = controller.view.convert(sender.bounds, from: sender)
      controller.present(pickerController, animated: true, completion: nil)
      
    } else {
      picker.showWithOverlay(in: controller.view)
    }
  }
  
}

extension TKUIResultsCard: TKUITimePickerSheetDelegate {
  
  public func timePickerRequestsResign(_ pickerSheet: TKUITimePickerSheet) {
    controller?.dismiss(animated: true) {
      let selection = TKUIResultsCardModel.RouteBuilder.Time(timeType: pickerSheet.selectedTimeType(), date: pickerSheet.selectedDate())
      self.cardModel.selected(selection)
    }
  }
  
}

// MARK: - Picking transport modes

// FIXME: Either simplify, or move to delegate

//fileprivate extension ResultsCard {
//
//  func showTransportOptions(sender: UIView) {
//
//    guard let controller = controller else {
//      preconditionFailure("Shouldn't be able to show transport picker!")
//    }
//
//    let modeSelector = TransportModeSelectionViewController(modes: cardModel.applicableModes, for: cardModel.regionForModes)
//    modeSelector.delegate = self
//
//    let navigator = UINavigationController(rootViewController: modeSelector)
//    if controller.traitCollection.horizontalSizeClass == .regular {
//      navigator.modalPresentationStyle = .popover
//      let presenter = navigator.popoverPresentationController
//      presenter?.sourceView = controller.view
//      presenter?.sourceRect = controller.view.convert(sender.bounds, from: sender)
//
//    } else {
//      navigator.modalPresentationStyle = .currentContext
//    }
//    controller.present(navigator, animated: true, completion: nil)
//  }
//
//}
//
//extension ResultsCard: TransportModeSelectionViewControllerDelegate {
//
//  func transportModeSelectorUpdatedSelection(_ modeSelector: TransportModeSelectionViewController) {
//    // TODO: Handle
//  }
//
//  func transportModeSelectorRequestsDismissal(_ modeSelector: TransportModeSelectionViewController) {
//    controller?.dismiss(animated: true, completion: nil)
//  }
//
//  func transportModeSelectorShowsCloseButton(_ modeSelector: TransportModeSelectionViewController) -> Bool {
//    return controller?.traitCollection.horizontalSizeClass == .compact || controller?.traitCollection.verticalSizeClass == .compact
//  }
//
//}

