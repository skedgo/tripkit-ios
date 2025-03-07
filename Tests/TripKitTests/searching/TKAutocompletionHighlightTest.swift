//
//  TKAutocompletionHighlightTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 7/3/2025.
//  Copyright © 2025 SkedGo Pty Ltd. All rights reserved.
//

#if canImport(Testing)

import Testing

@testable import TripKit

struct TKAutocompletionHighlightTest {
  
  @Test func spanishHighlights() async throws {
    
    let highlights = TKAutocompletionResult.nameScore(
      searchTerm: "Hotel España",
      candidate: "Hotel españa"
    )
    
    #expect(highlights.ranges.count == 1)
    #expect(highlights.ranges.first?.location == 0)
    #expect(highlights.ranges.first?.length == 12)
  }
  
}

#endif
