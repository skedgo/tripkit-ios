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

#endif
