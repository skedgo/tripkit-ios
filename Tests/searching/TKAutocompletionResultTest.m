//
//  TKAutocompletionResultTest.m
//  SkedGoKit
//
//  Created by Adrian Schoenig on 16/07/2016.
//  Copyright © 2016 SkedGo. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "TKAutocompletionResult.h"

@interface TKAutocompletionResultTest : XCTestCase

@end

@implementation TKAutocompletionResultTest

- (void)testAutocompletionPreparation
{
  XCTAssertEqualObjects([TKAutocompletionResult stringForScoringOfString:@"  Home!!! "], @"home");
}

- (void)testHomeAutocompletion
{
  NSString *searchTerm = @"Home";
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@" Homebush"];
  XCTAssertEqual(score, 100 - 4);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"home"];
  XCTAssertEqual(score, 100);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Home Thai"];
  XCTAssertEqual(score, 100 - 5);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Indian Home Diner"];
  XCTAssertEqual(score, 48); // penalty for not matching start and excess
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@""];
  XCTAssertEqual(score, 100);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"My Home"];
  XCTAssertEqual(score, 75 - 3*2 - 3); // penalty for not matching start
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Adrian's Home"];
  XCTAssertEqual(score, 75 - 8*2 - 8); // penalty for not matching start
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"PCHome"];
  XCTAssertEqual(score, 23 - 2); // penalty for not matching start of word
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"hxoxmxex"];
  XCTAssertEqual(score, 0);
}

- (void)testMultipleSearchTerms
{
  NSString *searchTerm = @"Max B";
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Max Brenner Chocolate Bar"];
  XCTAssertEqual(score, 100 - 20);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"max  black"];
  XCTAssertEqual(score, 100 - 4);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"The MAX BLACK"];
  XCTAssertEqual(score, 75 - 4*2 - 8); // penalty for not starting with it
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Max Power Bullets"];
  XCTAssertEqual(score, 66 - 12); // Right order and all words complete
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Maxwell's Cafe Bar Espresso"];
  XCTAssertEqual(score, 33 - 21); // Penalty for not having a completed word
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"B Max Property Group"];
  XCTAssertEqual(score, 0); // Penalty for order mismatch
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"B&N - Max PTY LTD"];
  XCTAssertEqual(score, 1); // Penalty for order mismatch
}

- (void)testTrainStationSearchTerms
{
  NSString *searchTerm = @"Ashfield S";
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Ashfield Station"];
  XCTAssertEqual(score, 100 - 6);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Ashfield (Station)"];
  XCTAssertEqual(score, 100 - 6);
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Brown St near Ashfield"];
  XCTAssertEqual(score, 0); // order mismatch
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Ses Fashions"];
  XCTAssertEqual(score, 0); // missing a word
}

- (void)testBadFuzzyMatches
{
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"Brandon Ave" candidate:@"Another Ave"];
  XCTAssertEqual(score, 0);
  
  // This is debatable. Would be nice if you still scored some points
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"Brandon Ave, Sydney" candidate:@"Brandon Avenue"];
  XCTAssertEqual(score, 0);
}

- (void)testDeeWhyAutocompletion5147
{
  NSString *searchTerm = @"Dee Why";
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Big Red Dee Why"];
  XCTAssertEqual(score, 75 - 8*2 - 8); // penalty for not matching start
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Dee Why NSW"];
  XCTAssertEqual(score, 100 - 4);
}

- (void)testGeorgeStreet
{
  NSString *searchTerm = @"george street";
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:searchTerm candidate:@"Telstra Loading Dock 400 George Street Sydney"];
  XCTAssertEqual(score, 33);
}

- (void)testAbbreviations
{
  NSInteger score;
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"moma" candidate:@"Museum of Modern Art"];
  XCTAssertEqual(score, 95); // minor penalty for abbreviations

  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"moma" candidate:@"Museum of Modern Art (MoMA)"];
  XCTAssertEqual(score, 95); // minor penalty for abbreviations
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"museum of modern art" candidate:@"MoMA"];
  XCTAssertEqual(score, 90); // minor penalty for abbreviations
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"mcg" candidate:@"Melbourne Cricket Ground"];
  XCTAssertEqual(score, 95); // minor penalty for abbreviations
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"m" candidate:@"Melbourne"];
  XCTAssertEqual(score, 92); // abbreviation is too short, but it's valid autocompletion
  
  score = [TKAutocompletionResult scoreBasedOnNameMatchBetweenSearchTerm:@"mc" candidate:@"Melbourne Cricket"];
  XCTAssertEqual(score, 0); // abbreviation is too short
}

@end

