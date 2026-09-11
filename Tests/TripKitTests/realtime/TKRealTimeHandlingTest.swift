#if canImport(Testing) && canImport(CoreData)

import Foundation
import CoreData
import Testing

@testable import TripKit

struct TKRealTimeHandlingTest {
  private static let model: NSManagedObjectModel? = TripKit.loadModel()
  
  @Test func capableWithoutRealtimeDisplaysScheduled() throws {
    let context = try makeContext()
    let visit = makeVisit(
      in: context,
      stopCode: "STOP-1",
      serviceCode: "SERVICE-1",
      departure: Date().addingTimeInterval(300)
    )
    visit.service.isRealTimeCapable = true
    visit.service.isRealTime = false
    visit.service.isCanceled = false
    
    #expect(visit.realTimeStatus == .notAvailable)
    #expect(visit.realTimeInformation(withOriginalTime: false) == Loc.Scheduled)
    #expect(visit.realTimeInformation(withOriginalTime: false) != Loc.NoRealTimeAvailable)
  }
  
  @Test func latestParametersIncludeRealtimeCapableVisitOutsideLocalWindow() throws {
    let context = try makeContext()
    let departure = Date().addingTimeInterval(2 * 60 * 60)
    let visit = makeVisit(
      in: context,
      stopCode: "STOP-2",
      serviceCode: "SERVICE-2",
      departure: departure
    )
    visit.service.isRealTimeCapable = true
    visit.service.isRealTime = false
    
    // This visit is more than 45 minutes away, so old filtering excluded it.
    #expect(visit.service.wantsRealTimeUpdates == false)
    
    let latest = TKRealTimeFetcher.latestParameters(for: visit)
    #expect(latest != nil)
    #expect(latest?.parameters["serviceTripID"] as? String == "SERVICE-2")
    #expect(latest?.parameters["startStopCode"] as? String == "STOP-2")
    #expect(latest?.parameters["startTime"] as? TimeInterval == departure.timeIntervalSince1970)
  }
  

  /// Captured from api.tripgo.com on 2026-09-10: `latest.json` for one L3 light-rail service at
  /// Town Hall. Because the request carried a `startStopCode`, the server answers with a top-level
  /// `startTime` and *no* `stops` — `LatestLocationServlet` populates one or the other, never both.
  @Test func visitRefreshAppliesRealTimeDeparture() throws {
    let context = try makeContext()
    let scheduled = Date(timeIntervalSince1970: 1_789_018_870)
    let visit = makeVisit(
      in: context,
      stopCode: "2000459",
      serviceCode: "47197-10470:1000",
      departure: scheduled
    )
    visit.service.isRealTimeCapable = true
    visit.service.isRealTime = false

    let response = try latestResponse(named: "latest-startStopCode")
    TKRealTimeFetcher.update(updateables: TKRealTimeFetcher.updateables(for: [visit]), from: response)

    #expect(visit.departure == Date(timeIntervalSince1970: 1_789_019_118))
    #expect(visit.service.isRealTime == true)
  }

  /// One service can be visible at several stops in the same refresh. The server then returns one
  /// entry per stop, all sharing a `serviceTripID` but each with its own `startStopCode` and
  /// `startTime`, so entries have to be matched on the stop and not just the service.
  @Test func visitRefreshMatchesEachStopOfTheSameService() throws {
    let context = try makeContext()
    let first = makeVisit(in: context, stopCode: "2000459", serviceCode: "47197-10470:1000",
                          departure: Date(timeIntervalSince1970: 1_789_018_870))
    let second = makeVisit(in: context, stopCode: "2000457", serviceCode: "47197-10470:1000",
                           departure: Date(timeIntervalSince1970: 1_789_018_990))
    second.service = first.service
    first.service.isRealTimeCapable = true

    let response = try latestResponse(named: "latest-startStopCode-sharedService")
    TKRealTimeFetcher.update(updateables: TKRealTimeFetcher.updateables(for: [first, second]), from: response)

    #expect(first.departure == Date(timeIntervalSince1970: 1_789_019_107))
    #expect(second.departure == Date(timeIntervalSince1970: 1_789_019_222))
  }

  /// The timetable for a stop pair is fed by an `NSFetchedResultsController` over `DLSEntry`
  /// (`NSManagedObjectContext.rx.fetchObjects`), which re-emits whenever a fetched entry's attributes
  /// change. Uses the captured Town Hall → terminus response: a DLS refresh has to reach that consumer.
  @MainActor @Test func dlsRefreshReachesFetchedResultsConsumers() throws {
    let context = try makeContext()
    let entry = makeDLSEntry(
      in: context,
      stopCode: "2000459",
      endStopCode: "2000450",
      serviceCode: "47197-10470:1000",
      departure: Date(timeIntervalSince1970: 1_789_018_870),
      arrival: Date(timeIntervalSince1970: 1_789_019_400)
    )
    entry.service.isRealTimeCapable = true
    try context.save()

    let request: NSFetchRequest<DLSEntry> = DLSEntry.fetchRequest()
    request.sortDescriptors = StopVisits.defaultSortDescriptors
    let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
    let spy = ContentChangeSpy()
    controller.delegate = spy
    try controller.performFetch()

    let entries: Set<DLSEntry> = [entry]
    TKRealTimeFetcher.update(updateables: TKRealTimeFetcher.updateables(for: entries), from: try latestResponse(named: "latest-startStopCode"))
    context.processPendingChanges()

    #expect(entry.departure == Date(timeIntervalSince1970: 1_789_019_118))
    #expect(entry.arrival == Date(timeIntervalSince1970: 1_789_019_657))
    #expect(entry.service.isRealTime == true)
    #expect(spy.changes == 1)
  }

  @Test func latestParametersSkipRealtimeIncapableVisit() throws {
    let context = try makeContext()
    let visit = makeVisit(
      in: context,
      stopCode: "STOP-3",
      serviceCode: "SERVICE-3",
      departure: Date().addingTimeInterval(60)
    )
    visit.service.isRealTimeCapable = false
    
    #expect(TKRealTimeFetcher.latestParameters(for: visit) == nil)
  }
  
}

private extension TKRealTimeHandlingTest {
  
  enum SetupError: Error {
    case missingModel
  }
  
  func makeContext() throws -> NSManagedObjectContext {
    guard let model = Self.model else { throw SetupError.missingModel }
    
    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)
    
    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    return context
  }
  

  func latestResponse(named name: String) throws -> TKAPI.LatestResponse {
    let url = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()      // realtime/
      .deletingLastPathComponent()      // TripKitTests/
      .appendingPathComponent("Data", isDirectory: true)
      .appendingPathComponent(name).appendingPathExtension("json")
    return try JSONDecoder().decode(TKAPI.LatestResponse.self, from: Data(contentsOf: url))
  }

  func makeDLSEntry(
    in context: NSManagedObjectContext,
    stopCode: String,
    endStopCode: String,
    serviceCode: String,
    departure: Date,
    arrival: Date
  ) -> DLSEntry {
    let stop = NSEntityDescription.insertNewObject(forEntityName: "StopLocation", into: context) as! StopLocation
    stop.stopCode = stopCode
    let endStop = NSEntityDescription.insertNewObject(forEntityName: "StopLocation", into: context) as! StopLocation
    endStop.stopCode = endStopCode

    let service = NSEntityDescription.insertNewObject(forEntityName: "Service", into: context) as! Service
    service.code = serviceCode
    service.setValue(0, forKey: "flags")

    let entry = NSEntityDescription.insertNewObject(forEntityName: "DLSEntry", into: context) as! DLSEntry
    entry.stop = stop
    entry.endStop = endStop
    entry.service = service
    entry.pairIdentifier = "\(stopCode)-\(endStopCode)"
    entry.departure = departure
    entry.originalTime = departure
    entry.arrival = arrival
    entry.setValue(0, forKey: "flags")
    entry.setValue(0, forKey: "index")
    entry.setValue(true, forKey: "isActive")
    return entry
  }

  func makeVisit(
    in context: NSManagedObjectContext,
    stopCode: String,
    serviceCode: String,
    departure: Date
  ) -> StopVisits {
    let stop = NSEntityDescription.insertNewObject(forEntityName: "StopLocation", into: context) as! StopLocation
    stop.stopCode = stopCode
    
    let service = NSEntityDescription.insertNewObject(forEntityName: "Service", into: context) as! Service
    service.code = serviceCode
    
    let visit = NSEntityDescription.insertNewObject(forEntityName: "StopVisits", into: context) as! StopVisits
    visit.stop = stop
    visit.service = service
    visit.departure = departure
    visit.originalTime = departure
    visit.arrival = departure.addingTimeInterval(600)
    return visit
  }
  
}

private final class ContentChangeSpy: NSObject, NSFetchedResultsControllerDelegate {
  private(set) var changes = 0

  func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
    changes += 1
  }
}

#endif
