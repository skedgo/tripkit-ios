#if canImport(Testing) && canImport(CoreData)

import Foundation
import CoreData
import Testing

@testable import TripKit

@MainActor
struct TKLoopServiceParsingTest {
  private static let model = TKTestCase.model

  @Test func serviceDetailsPreserveDistinctVisitsForRepeatedStopCodes() throws {
    let context = try makeContext()
    let departuresData = try dataFromJSON(named: "departures-darwin-loop")
    let departures = try JSONDecoder().decode(TKAPI.Departures.self, from: departuresData)

    let stop = StopLocation.fetchOrInsertStop(
      stopCode: "046",
      inRegion: "AU_NT_Darwin",
      in: context
    )

    #expect(TKDeparturesProvider.addDepartures(departures, to: [stop]) == false)

    let departureVisit = try firstDepartureVisit(in: context)
    let service = try unwrap(departureVisit.service, "Expected a service on the departure visit.")

    #expect(departureVisit.index == -1)
    #expect(Int(departureVisit.departure?.timeIntervalSince1970 ?? 0) == 1_775_711_400)

    let serviceData = try dataFromJSON(named: "service-darwin-loop")
    let serviceResponse = try JSONDecoder().decode(TKAPI.ServiceResponse.self, from: serviceData)

    #expect(TKBuzzInfoProvider.addContent(from: serviceResponse, to: service))

    let repeatedVisits = service.sortedVisits.filter { $0.stop.stopCode == "046" }

    #expect(service.sortedVisits.count == 4)
    #expect(repeatedVisits.count == 2)
    #expect(repeatedVisits.first?.objectID == departureVisit.objectID)
    #expect(repeatedVisits.map(\.index) == [0, 3])
    #expect(
      repeatedVisits.map { Int($0.departure?.timeIntervalSince1970 ?? 0) }
        == [1_775_711_400, 1_775_712_960]
    )
    #expect(departureVisit.index == 0)
    #expect(Int(departureVisit.departure?.timeIntervalSince1970 ?? 0) == 1_775_711_400)
  }

}

private extension TKLoopServiceParsingTest {

  enum SetupError: Error {
    case missingModel
    case missingFixture(String)
    case missingValue(String)
  }

  func makeContext() throws -> NSManagedObjectContext {
    guard let model = Self.model else { throw SetupError.missingModel }

    let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
    try coordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: nil)

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = coordinator
    return context
  }

  func dataFromJSON(named name: String) throws -> Data {
    let thisSourceFile = URL(fileURLWithPath: #filePath)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    let jsonPath = thisDirectory
      .deletingLastPathComponent()
      .appendingPathComponent("Data", isDirectory: true)
      .appendingPathComponent(name)
      .appendingPathExtension("json")

    guard FileManager.default.fileExists(atPath: jsonPath.path) else {
      throw SetupError.missingFixture(jsonPath.path)
    }

    return try Data(contentsOf: jsonPath)
  }

  func firstDepartureVisit(in context: NSManagedObjectContext) throws -> StopVisits {
    let visit = context.fetchObjects(
      StopVisits.self,
      sortDescriptors: [NSSortDescriptor(key: "departure", ascending: true)],
      predicate: NSPredicate(format: "stop.stopCode = %@", "046"),
      relationshipKeyPathsForPrefetching: nil,
      fetchLimit: 1
    ).first

    return try unwrap(visit, "Expected the seeded Darwin departure visit.")
  }

  func unwrap<T>(_ value: T?, _ message: String) throws -> T {
    guard let value else {
      throw SetupError.missingValue(message)
    }
    return value
  }

}

#endif
