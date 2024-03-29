//
//  TKAutocompletionResultTest.swift
//  TripKitTests
//
//  Created by Adrian Schönig on 19/10/2022.
//  Copyright © 2022 SkedGo Pty Ltd. All rights reserved.
//

import XCTest

@testable import TripKit

final class TKAutocompletionResultTest: XCTestCase {

  func testAutocompletionPreparation() {
    XCTAssertEqual(TKAutocompletionResult.stringForScoring("  Home!!! "), "home")
  }

  func testHomeAutocompletion()
  {
    let searchTerm = "Home"
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:" Homebush")
    XCTAssertEqual(score.score, 100 - 4)
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"home")
    XCTAssertEqual(score.score, 100)
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Home Thai")
    XCTAssertEqual(score.score, 100 - 5)
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Indian Home Diner")
    XCTAssertEqual(score.score, 48) // penalty for not matching start and excess
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"")
    XCTAssertEqual(score.score, 100)
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"My Home")
    XCTAssertEqual(score.score, 75 - 3*2 - 3) // penalty for not matching start
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Adrian's Home")
    XCTAssertEqual(score.score, 75 - 8*2 - 8) // penalty for not matching start
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"PCHome")
    XCTAssertEqual(score.score, 25 - 2) // penalty for not matching start of word
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"hxoxmxex")
    XCTAssertEqual(score.score, 0)
  }

  func testMultipleSearchTerms()
  {
    let searchTerm = "Max B"
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Max Brenner Chocolate Bar")
    XCTAssertEqual(score.score, 100 - 20)

    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"max  black")
    XCTAssertEqual(score.score, 100 - 4)

    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"The MAX BLACK")
    XCTAssertEqual(score.score, 75 - 4*2 - 8) // penalty for not starting with it
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Max Power Bullets")
    XCTAssertEqual(score.score, 66 - 12) // Right order and all words complete
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Maxwell's Cafe Bar Espresso")
    XCTAssertEqual(score.score, 33 - 21) // Penalty for not having a completed word
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"B Max Property Group")
    XCTAssertEqual(score.score, 0) // Penalty for order mismatch
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"B&N - Max PTY LTD")
    XCTAssertEqual(score.score, 1) // Penalty for order mismatch
  }

  func testTrainStationSearchTerms()
  {
    let searchTerm = "Ashfield S"
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Ashfield Station")
    XCTAssertEqual(score.score, 100 - 6)
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Ashfield (Station)")
    XCTAssertEqual(score.score, 100 - 6)
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Brown St near Ashfield")
    XCTAssertEqual(score.score, 0) // order mismatch
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Ses Fashions")
    XCTAssertEqual(score.score, 0) // missing a word
  }

  func testBadFuzzyMatches()
  {
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm: "Brandon Ave", candidate:"Another Ave")
    XCTAssertEqual(score.score, 0)
    
    // This is debatable. Would be nice if you still scored some points
    score = TKAutocompletionResult.nameScore(searchTerm: "Brandon Ave,Sydney", candidate:"Brandon Avenue")
    XCTAssertEqual(score.score, 0)
  }

  func testDeeWhyAutocompletion5147()
  {
    let searchTerm = "Dee Why"
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Big Red Dee Why")
    XCTAssertEqual(score.score, 75 - 8*2 - 8) // penalty for not matching start
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Dee Why NSW")
    XCTAssertEqual(score.score, 100 - 4)
  }

  func testGeorgeStreet()
  {
    let searchTerm = "george street"
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm:searchTerm, candidate:"Telstra Loading Dock 400 George Street Sydney")
    XCTAssertEqual(score.score, 33)
  }

  func testAbbreviations()
  {
    var score: TKAutocompletionResult.Score
    
    score = TKAutocompletionResult.nameScore(searchTerm: "moma", candidate:"Museum of Modern Art")
    XCTAssertEqual(score.score, 95) // minor penalty for abbreviations

    score = TKAutocompletionResult.nameScore(searchTerm: "moma", candidate:"Museum of Modern Art (MoMA)")
    XCTAssertEqual(score.score, 95) // minor penalty for abbreviations
    
    score = TKAutocompletionResult.nameScore(searchTerm: "museum of modern art", candidate:"MoMA")
    XCTAssertEqual(score.score, 90) // minor penalty for abbreviations
    
    score = TKAutocompletionResult.nameScore(searchTerm: "mcg", candidate:"Melbourne Cricket Ground")
    XCTAssertEqual(score.score, 95) // minor penalty for abbreviations
    
    score = TKAutocompletionResult.nameScore(searchTerm: "m", candidate:"Melbourne")
    XCTAssertEqual(score.score, 92) // abbreviation is too short, but it's valid autocompletion
    
    score = TKAutocompletionResult.nameScore(searchTerm: "mc", candidate:"Melbourne Cricket")
    XCTAssertEqual(score.score, 0) // abbreviation is too short
  }
  
  func testRanges() {
    XCTAssertEqual(
      TKAutocompletionResult.nameScore(searchTerm: "that", candidate:"This & That").ranges.first,
      .init(location: 7, length: 4)
    )
    
    XCTAssertEqual(
      TKAutocompletionResult.nameScore(searchTerm: "this", candidate:"This & That").ranges.first,
      .init(location: 0, length: 4)
    )
    
    XCTAssertEqual(
      TKAutocompletionResult.nameScore(searchTerm: "that", candidate:"This is not that").ranges.first,
      .init(location: 12, length: 4)
    )
  }

}
