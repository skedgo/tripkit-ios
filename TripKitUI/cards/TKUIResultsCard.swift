//
//  TKUIResultsCard.swift
//  TripKit
//
//  Created by Adrian Schoenig on 10/4/17.
//  Copyright © 2017 SkedGo Pty Ltd. All rights reserved.
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

public protocol TKUIResultsCardDelegate: class {
  func resultsCard(_ card: TKUIResultsCard, requestsModePickerWithModes modes: [String], for region: SVKRegion, sender: Any?)
}

public class TKUIResultsCard: TGTableCard {
  public weak var resultsDelegate: TKUIResultsCardDelegate?
  
  private let destination: MKAnnotation?
  private let request: TripRequest?
  
  private var viewModel: TKUIResultsViewModel!
  private let disposeBag = DisposeBag()
  
  private let accessoryView = TKUIResultsAccessoryView.instantiate()
  
  private lazy var footerButton = { () -> UIButton in
    let button = UIButton(type: .custom)
    button.titleLabel?.font = SGStyleManager.systemFont(withTextStyle: UIFontTextStyle.caption1.rawValue)
    button.setTitleColor(SGStyleManager.globalTintColor(), for: .normal)
    return button
  }()
  
  private let dataSource = RxTableViewSectionedAnimatedDataSource<TKUIResultsViewModel.Section>(
    configureCell: TKUIResultsCard.cell
  )
  
  private let changedTime = PublishSubject<TKUIResultsViewModel.RouteBuilder.Time>()
  private let changedModes = PublishSubject<Void>()
  
  public init(destination: MKAnnotation) {
    self.destination = destination
    self.request = nil
    
    let title = "Plan Trip" // TODO: Localise
    let mapManager = TKUIResultsMapManager()
    super.init(
      title: title, style: .grouped,
      accessoryView: accessoryView, mapManager: mapManager,
      initialPosition: nil // keep same as before (so that user can drop another pin)
    )
  }
  
  
  public init(request: TripRequest) {
    self.destination = nil
    self.request = request
    
    let title = "Routes" // TODO: Localise
    let mapManager = TKUIResultsMapManager()
    super.init(
      title: title, style: .grouped,
      accessoryView: accessoryView, mapManager: mapManager,
      initialPosition: .extended // show fully as we'll have routes shortly
    )
  }
  
  
  override public func didBuild(cardView: TGCardView, headerView: TGHeaderView?) {
    guard
      let tableView = (cardView as? TGScrollCardView)?.tableView,
      let mapManager = mapManager as? TKUIResultsMapManager
      else {
        preconditionFailure()
    }
    
    accessoryView.transportButton.isHidden = (resultsDelegate == nil)
    footerButton.isEnabled = (resultsDelegate != nil)
    
    // Build the view model

    let tappedModes = Driver.merge(accessoryView.transportButton.rx.tap.asDriver(), footerButton.rx.tap.asDriver())

    let inputs: TKUIResultsViewModel.UIInput = (
      selected: tableView.rx.modelSelected(TKUIResultsViewModel.Item.self).asDriver(),
      tappedDate: accessoryView.timeButton.rx.tap.asDriver(),
      tappedShowModes: tappedModes,
      tappedMapRoute: mapManager.selectedMapRoute,
      changedDate: changedTime.asDriver(onErrorDriveWith: Driver.empty()),
      changedModes: changedModes.asDriver(onErrorDriveWith: Driver.empty()),
      changedSortOrder: Driver.empty(), // TODO
      droppedPin: mapManager.droppedPin
    )
    
    let viewModel: TKUIResultsViewModel
    if let destination = self.destination {
      viewModel = TKUIResultsViewModel(destination: destination, inputs: inputs)
    } else if let request = self.request {
      viewModel = TKUIResultsViewModel(request: request, inputs: inputs)
    } else {
      preconditionFailure()
    }
    self.viewModel = viewModel
    mapManager.viewModel = viewModel
    
    // Table view configuration
    
    tableView.register(TKUITripCell.nib, forCellReuseIdentifier: TKUITripCell.reuseIdentifier)
    tableView.register(TKUIResultsSectionFooterView.nib, forHeaderFooterViewReuseIdentifier: TKUIResultsSectionFooterView.reuseIdentifier)
    tableView.tableFooterView = footerButton
    
    // Overriding the data source with our Rx one
    // Note: explicitly reset to say we know that we'll override this with Rx
    tableView.dataSource = nil
    
    // Bind outputs
    
    viewModel.sections
      .drive(tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)
    
    viewModel.selectedItem
      .drive(onNext: { [weak self] in
        let indexPath = self?.dataSource.indexPath(of: $0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .top)
      })
      .disposed(by: disposeBag)

    viewModel.titles
      .drive(cardView.rx.titles)
      .disposed(by: disposeBag)

    viewModel.timeTitle
      .drive(accessoryView.timeButton.rx.title())
      .disposed(by: disposeBag)
    
    viewModel.includedTransportModes
      .drive(onNext: { title in
        if let title = title {
          self.footerButton.isHidden = false
          self.footerButton.setTitle(title, for: .normal)
          self.footerButton.sizeToFit()
        } else {
          self.footerButton.isHidden = true
        }
      })
      .disposed(by: disposeBag)

    // Monitor progress (note: without this, we won't fetch!)
    viewModel.fetchProgress
      .drive(onNext: { progress in
        // TODO: Indicate loading state
      })
      .disposed(by: disposeBag)
    
    viewModel.request
      .drive(onNext: TKUICustomization.shared.feedbackActiveItemHandler)
      .disposed(by: disposeBag)

    viewModel.error
      .drive(onNext: { [unowned self] error in
        guard
          let controller = self.controller, self.viewIsVisible
          else { return }
        
        // TODO: Restore feedback
        // TODO: Show the nice error again
        //        if (error as NSError).code == 1001 {
        //          self.showRoutingSupportView(with: error)
        //        } else {
        TKUICustomization.shared.alertHandler?(error, controller)
        //          
        //        }
      })
      .disposed(by: disposeBag)
    
    viewModel.next
      .drive(onNext: { [weak self] in self?.navigate(to: $0) })
      .disposed(by: disposeBag)
    
    tableView.rx.setDelegate(self)
      .disposed(by: disposeBag)
  }
  
}

// MARK: - Cell configuration

extension TKUIResultsCard {
  
  static func cell(dataSource: RxDataSources.TableViewSectionedDataSource<TKUIResultsViewModel.Section>, tableView: UITableView, indexPath: IndexPath, item: TKUIResultsViewModel.Item) -> UITableViewCell {
    
    if let trip = item.trip {
      let tripCell = tableView.dequeueReusableCell(withIdentifier: TKUITripCell.reuseIdentifier, for: indexPath) as! TKUITripCell
      tripCell.configure(TKUITripCell.Model(trip))
      return tripCell
      
    } else {
      let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
      switch item {
      case .lessIndicator: cell.textLabel?.text = "Less"
      case .moreIndicator: cell.textLabel?.text = "More"
      case .nano, .trip: preconditionFailure()
      }
      return cell
    }
  }
  
}

extension TKUITripCell.Model {

  init(_ trip: Trip) {
    self.init(
      departure: trip.departureTime, arrival: trip.arrivalTime,
      departureTimeZone: trip.departureTimeZone, arrivalTimeZone: trip.arrivalTimeZone ?? trip.departureTimeZone,
      focusOnDuration: !trip.departureTimeIsFixed, isArriveBefore: trip.isArriveBefore,
      showFaded: trip.showFaded,
      segments: trip.segments(with: .inSummary)
    )
  }

}

extension TKMetricClassifier.Classification {
  fileprivate var footerContent: (UIImage?, String, UIColor) {
    return (icon, text, color)
  }
}

extension TKUIResultsCard: UITableViewDelegate {
  
  public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
    guard let footerView = tableView.dequeueReusableHeaderFooterView(withIdentifier: TKUIResultsSectionFooterView.reuseIdentifier) as? TKUIResultsSectionFooterView else {
      assertionFailure()
      return nil
    }

    let formatter = TKUITripCell.Formatter()
    formatter.costColor = footerView.costLabel.textColor

    let section = dataSource.sectionModels[section]
    footerView.badge = section.badge?.footerContent
    footerView.attributedCost = formatter.costString(costs: section.costs)
    return footerView
  }
  
}

// MARK: - Navigation

private extension TKUIResultsCard {
  func navigate(to next: TKUIResultsViewModel.Next) {
    switch next {
    case .showTrip(let trip):
      controller?.push(TGPageCard(overviewsHighlighting: trip))
      
    case .presentModes(let modes, let region):
      showTransportOptions(modes: modes, for: region)
      
    case .presentDatePicker(let time, let timeZone):
      showTimePicker(time: time, timeZone: timeZone)
    }
  }
}

// MARK: - Picking times

private extension TKUIResultsCard {
  
  func showTimePicker(time: TKUIResultsViewModel.RouteBuilder.Time, timeZone: TimeZone) {
    
    guard let controller = controller else {
      preconditionFailure("Shouldn't be able to show time picker!")
    }
    let sender: UIButton = accessoryView.timeButton
    
    let picker = TKUITimePickerSheet(time: time.date, timeType: time.timeType, timeZone: timeZone)
    picker.selectAction = { [weak self] timeType, date in
      self?.changedTime.onNext(TKUIResultsViewModel.RouteBuilder.Time(timeType: timeType, date: date))
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
    func onDismissal() {
      let selection = TKUIResultsViewModel.RouteBuilder.Time(timeType: pickerSheet.selectedTimeType(), date: pickerSheet.selectedDate())
      self.changedTime.onNext(selection)
    }
    
    if controller?.presentedViewController != nil {
      controller?.dismiss(animated: true, completion: onDismissal)
    } else {
      // e.g., on iPad where it's displayed as a popover
      onDismissal()
    }
  }
  
}

// MARK: - Picking transport modes

extension TKUIResultsCard {
  
  private func showTransportOptions(modes: [String], for region: SVKRegion) {
    resultsDelegate?.resultsCard(self, requestsModePickerWithModes: modes, for: region, sender: accessoryView.transportButton)
  }
  
  public func refreshForUpdatedModes() {
    changedModes.onNext(())
  }
  
}
