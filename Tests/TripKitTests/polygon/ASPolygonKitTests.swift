//
//  ASPolygonKitTests.swift
//  ASPolygonKitExampleTests
//
//  Created by Adrian Schoenig on 18/2/17.
//  Copyright © 2017 Adrian Schönig. All rights reserved.
//

import XCTest

import MapKit

@testable import TripKit

class ASPolygonKitTests: XCTestCase {
    
  func testAll() throws {
    let polygons = try polygonsFromJSON(named: "polygons-tripgo-170217")
    XCTAssertEqual(154, polygons.count)
  }

  func testCH() throws {
    let polygons = try polygonsFromJSON(named: "polygons-ch-170224")
    XCTAssertEqual(5, polygons.count)
    
    let merged = try Polygon.union(polygons)
    XCTAssertEqual(1, merged.count)
    
    XCTAssertEqual(merged.first?.encodeCoordinates(), """
      iobcHyvps@j~cAoquEhgj@jWA{AxzAnCzgD~A@hDlpb@`w@_JehAjVoheDb{xCucAjqlBtpmHo`^`zyBtrAlvzA~|IfwsArvX?{iv@htlIuj`ChvB?~P{MqPcaRpP?saVk`aDyn~DeiXoy{D`gC?mtg@s}xC
      """)
  }
  
  func testUK() throws {
    let polygons = try polygonsFromJSON(named: "polygons-uk-170217")
    XCTAssertEqual(19, polygons.count)
    
    let merged = try Polygon.union(polygons)
    XCTAssertEqual(1, merged.count)
    
    XCTAssertEqual(merged.first?.encodeCoordinates(), """
      _aisJ~nyo@?_oyo@~nh\\??`f{@nyo@lblH~tAboL~|bKs_kN?nh\\npxD??ovmHnxtI??~s`BnnqC??~m|Qn}}B??~hsXoezG??_ry@_ulL??_ulLo{vA??~dtBoljB??~{|FkkmCrkt@zoJz|x@i_@vaAxzbCgjiAnfrB??~qy@ntfG??ppHnaoA|z`BnpxDnl{U?~hbE_c{X??cro[_msCznqH?fdS_oh\\?
      """)
  }

  func testScandinavia() throws {
    let polygons = try polygonsFromJSON(named: "polygons-scandinavia-170217")
    XCTAssertEqual(16, polygons.count)
    
    let merged = try Polygon.union(polygons)
    XCTAssertEqual(1, merged.count)
    
    XCTAssertEqual(merged.first?.encodeCoordinates(), """
      {musLul~eCzizB}w|z@lxrGr|uD|diB~_uJd~zF{{_F|lq[cngJn`wFncpJyPvl@xdiGvtyK~yxA~olG||]l`nW`I`DiA~}DhA~y@aBi@w~E`k|P`{x@ubiA`z_G??j`mArwrFz|H?vqvE`bgClhtGnkuCnsqHnyo@~tiP_t`Boh\\odkA~wq@_{m@~tu@qrqB|juA?|ypAwapFzcn@hFf~|@_osCkF_}BcoDj|Ll_dEbiSnkkBfv{Ct~MlbLlxx\\{ftK_mEwdvD|x{@?tEcG_Cq_Cti@?}hBcv{Fsj{BempDyloH|VmfDanw^_jug@bRcxB}tuRshjv@
      """)
  }
  
  func testStaya() throws {
    let polygons = try polygonsFromJSON(named: "polygons-au-211102")
    XCTAssertEqual(7, polygons.count)
    
    let merged = try Polygon.union(polygons)
    XCTAssertEqual(1, merged.count)
    
    XCTAssertEqual(merged.first?.encodeCoordinates(), """
      ~ghgCai|h[ykhBmhuOprjAecdOfjpc@nbq@w@yBxd@w|C|fkB}hRxwzLzbyAx`bF~j{AjBjcMnrzQ??vtyK`udMhq`Bw{DbbNh`_IjqqGyKns|Mwr~BfgaFbcMpsY}~t@`ym@~{xBfl~A`J~`gRovq]?`qd@eeqBctKww\\eMkb_AlpPq~j@rn^o_d@z_k@q|H~ab@_bOaoh@iyYbMirVpeTapJlrGwvn@vcVqpo@|vc@hhCj~d@apJd~@}re@daYewB`zi@mhtAzil@wr{@xkZghNttc@yn}@w_m@mu[{oJ}oU?inX{@?ym@wkcAzzXuyiArbMykx@sbM_`~@~aW}xeA}yJcyd@c}Ij}Hw|zHswg@do@mcxLuu~K?j}@reeGeunRg`]kButH_sug@wqK
      """)
  }
  
  func testInvariantToShuffling() throws {
    let polygons = try polygonsFromJSON(named: "polygons-uk-170217")
    XCTAssertEqual(19, polygons.count)
    
    let _ = try (1...100).map { _ in
      let shuffled = polygons.shuffled()
      let merged = try Polygon.union(shuffled)
      XCTAssertEqual(1, merged.count)
      
      XCTAssertEqual(merged.first?.encodeCoordinates(), """
          _aisJ~nyo@?_oyo@~nh\\??`f{@nyo@lblH~tAboL~|bKs_kN?nh\\npxD??ovmHnxtI??~s`BnnqC??~m|Qn}}B??~hsXoezG??_ry@_ulL??_ulLo{vA??~dtBoljB??~{|FkkmCrkt@zoJz|x@i_@vaAxzbCgjiAnfrB??~qy@ntfG??ppHnaoA|z`BnpxDnl{U?~hbE_c{X??cro[_msCznqH?fdS_oh\\?
          """)
    }
  }

  func testOCFailure() throws {
    var grower = Polygon(pairs: [ (4,0), (4,3), (1,3), (1,0) ])
    let addition = Polygon(pairs: [ (5,1), (5,4), (3,4), (3,2), (2,2), (2,4), (0,4), (0,1) ])
    let merged = try grower.union(addition)
    XCTAssertTrue(merged)
    XCTAssertEqual(13, grower.points.count)
  }
  
  func testSinglePointFailure() throws {
    var grower = Polygon(pairs: [ (53.5,-7.77), (52.15,-6.25), (51.2,-10) ])
    let addition = Polygon(pairs: [ (53.4600,-7.77), (54,-10), (55,-7.77) ])
    
    try _ = grower.union(addition)
    XCTAssert(grower.points.count > 1)
  }
  
  func testPolygonContains() {
    let addition = Polygon(pairs: [ (53.4600,-7.77), (54,-10), (55,-7.77) ])
    
    XCTAssert( addition.contains(Point(latitude: 53.5, longitude: -7.77), onLine: true))
    XCTAssert(!addition.contains(Point(latitude: 53.5, longitude: -7.77), onLine: false))
  }

  func testUnsuccessfulUnion() throws {
    var grower = Polygon(pairs: [ (60.0000,-5.0000), (60.0000,0.0000), (56.2000,0.0000), (56.2000,-5.0000) ] )
    let addition = Polygon(pairs: [ (56.2500,-5.0000), (56.2500,0.0000), (55.9500,-1.8500), (55.1700,-5.7700) ] )
    
    try _ = grower.union(addition)
    XCTAssert(grower.points.count > 1)
  }

}


extension ASPolygonKitTests {
  
  func polygonsFromJSON(named name: String) throws -> [TKPolygon] {
    guard
      let dict = try contentFromJSON(named: name) as? [String: Any],
      let encodedPolygons = dict ["polygons"] as? [String]
      else { preconditionFailure() }
    
    return encodedPolygons.map { Polygon(encoded: $0) }
  }
  
  func contentFromJSON(named name: String) throws -> Any {
    let jsonPath: URL
    #if SWIFT_PACKAGE
    let thisSourceFile = URL(fileURLWithPath: #file)
    let thisDirectory = thisSourceFile.deletingLastPathComponent()
    jsonPath = thisDirectory
      .appendingPathComponent("data", isDirectory: true)
      .appendingPathComponent(name).appendingPathExtension("json")
    
    #else
    let bundle = Bundle(for: ASPolygonKitTests.self)
    let filePath = bundle.path(forResource: name, ofType: "json")
    jsonPath = URL(fileURLWithPath: filePath!)
    #endif

    let data = try Data(contentsOf: jsonPath)
    return try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions(rawValue: 0))
  }
  
}

extension Collection {
  /// Return a copy of `self` with its elements shuffled
  func shuffle() -> [Iterator.Element] {
    var list = Array(self)
    list.shuffleInPlace()
    return list
  }
}

extension MutableCollection where Index == Int {
  /// Shuffle the elements of `self` in-place.
  mutating func shuffleInPlace() {

    // empty and single-element collections don't shuffle
    if count < 2 { return }
    
    for i in 0..<count - 1 {
      let j = Int(arc4random_uniform(UInt32(count - i))) + i
      guard i != j else { continue }
      swapAt(i, j)
    }
  }
}

extension TKPolygon {
  init(encoded: String) {
    let points = Point.decodePolyline(encoded)
    self.init(points: points)
  }
}

#if os(iOS)

extension MKPolygon : CustomPlaygroundDisplayConvertible {
  public var playgroundDescription: Any {
    return quickLookImage ?? description
  }
  
  fileprivate var quickLookImage: UIImage? {
    let options = MKMapSnapshotter.Options()
    options.mapRect = self.boundingMapRect
    
    let snapshotter = MKMapSnapshotter(options: options)
    var image: UIImage?
    
    let semaphore = DispatchSemaphore(value: 1)
    snapshotter.start() { snapshot, error in
      
      image = snapshot?.image
      semaphore.signal()
      
    }
    
    semaphore.wait()

    return image
  }
  
  public var debugQuickLookObject: Any {
    return quickLookImage ?? description
  }

}

#endif
