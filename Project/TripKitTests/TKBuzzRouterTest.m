//
//  TKBuzzRouterTest.m
//  TripKit
//
//  Created by Adrian Schoenig on 15/07/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#import <XCTest/XCTest.h>

@import TripKit;

@interface TKBuzzRouterTest : XCTestCase

// environment
@property (nonatomic, strong) NSManagedObjectModel *model;
@property (nonatomic, strong) NSPersistentStoreCoordinator *coordinator;
@property (nonatomic, strong) NSPersistentStore *store;
@property (nonatomic, strong) NSManagedObjectContext *context;

// parsing data
@property (nonatomic, strong) id json;

@end

@implementation TKBuzzRouterTest

- (void)setUp
{
  // environment
  NSBundle *bundle = [NSBundle bundleForClass:[self class]];
  self.model = [TKTripKit tripKitModel];
  
  self.coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.model];
  self.store = [self.coordinator addPersistentStoreWithType:NSInMemoryStoreType
                                              configuration:nil
                                                        URL:nil
                                                    options:nil
                                                      error:NULL];
  self.context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
  self.context.persistentStoreCoordinator = self.coordinator;
  
  // data
  NSString *filePath = [bundle pathForResource:@"routing" ofType:@"json"];
  NSData* data = [NSData dataWithContentsOfFile:filePath];
  __autoreleasing NSError* error = nil;
  self.json = [NSJSONSerialization JSONObjectWithData:data
                                              options:kNilOptions error:&error];
}

- (void)tearDown {
  NSError *error = nil;
  XCTAssertTrue([self.coordinator removePersistentStore:self.store
                                                  error:&error],
                @"couldn't remove persistent store: %@", error);
}

- (void)testThatEnvironmentWorks {
  XCTAssertNotNil(self.model, @"no managed object model");
  XCTAssertNotNil(self.coordinator, @"no persistent store coordinator");
  XCTAssertNotNil(self.store, @"no persistent store");
  XCTAssertNotNil(self.context, @"no managed object context");
}

/*
 * Tests parsing the JSON files and creation of the resulting
 * CoreData objects (routes, segments & waypoints).
 */
- (void)testParsingResult
{
  TKRoutingParser* parser = [[TKRoutingParser alloc] initWithTripKitContext:self.context];
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"parsing results"];
  
  [parser parseAndAddResult:self.json
                 completion:
   ^(TripRequest *request) {
     XCTAssertTrue(request, @"Parser didn't succeed");
     
     // accessing the results through the request object
     NSSet *groups = [request tripGroups];
     XCTAssertEqual((int)groups.count, 3, @"Parser didn't get all trip groups");
     
     NSSet *trips = [request trips];
     XCTAssertEqual((int)trips.count, 4 + 4 + 4, @"Parser didn't get all trips");
     
     for (Trip* trip in trips) {
       XCTAssertGreaterThan((int)trip.segments.count, 0, @"Parser returned some routes without segments");
     }
     
     // accessing the results through the MOC
     NSSet *allGroups = [self.context fetchObjectsForEntityClass:[TripGroup class] withPredicate:nil];
     XCTAssertEqual((int)allGroups.count, 3, @"Not all groups written to context.");
     
     NSSet *allTrips = [self.context fetchObjectsForEntityClass:[Trip class] withPredicate:nil];
     XCTAssertEqual((int)allTrips.count, 4 + 4 + 4, @"Not all trips written to context.");
     
     NSSet *allTemplates = [self.context fetchObjectsForEntityName:@"SegmentTemplate" withPredicate:nil];
     XCTAssertEqual((int)allTemplates.count, 20, @"Each segment that's not hidden should be parsed and added just once.");
     
     [expectation fulfill];
   }];
  
  [self waitForExpectationsWithTimeout:10
                               handler:
   ^(NSError *error) {
     XCTAssertNil(error, @"Error while parsing");
   }];
}

- (void)testParsingPerformance
{
  TKRoutingParser* parser = [[TKRoutingParser alloc] initWithTripKitContext:self.context];
  
  [self measureBlock:^{
    TripRequest *request = [parser parseAndAddResultBlocking:self.json];
    XCTAssertNotNil(request, @"No result returned");
  }];
}

- (void)testTripCache
{
  NSString *identifier = @"Test";
  TKJSONCacheDirectory directory = TKJSONCacheDirectoryDocuments; // This is where TKBuzzRouter is keeping its trips
  
  // 0. Clear
  [TKJSONCache remove:identifier directory:directory];
  XCTAssertNil([TKJSONCache read:identifier directory:directory]);

  // 1. Save the trip to the cache
  [TKJSONCache save:identifier dictionary:self.json directory:directory];
  XCTAssertNotNil([TKJSONCache read:identifier directory:directory]);
  
  // 2. Retrieve it form the cache
  
  XCTestExpectation *expectation = [self expectationWithDescription:@"trip cache"];
  
  TKBuzzRouter *router = [[TKBuzzRouter alloc] init];
  [router downloadTrip:[NSURL URLWithString:@"http://www.example.com/"]
            identifier:identifier
    intoTripKitContext:self.context
            completion:
   ^(Trip * __nullable trip) {
     XCTAssertNotNil(trip);
     
     [expectation fulfill];
   }];
  
  [self waitForExpectationsWithTimeout:10
                               handler:
   ^(NSError * _Nullable error) {
     XCTAssertNil(error, @"Error while fetching trip from cache");
   }];
  
}

@end
