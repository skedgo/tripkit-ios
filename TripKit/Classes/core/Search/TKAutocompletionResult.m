//
//  AutocompletionResult.m
//  TripKit
//
//  Created by Adrian Schoenig on 23/10/2013.
//
//

#import "TKAutocompletionResult.h"

#import "TKStyleManager.h"

@implementation NSString (Matches)

- (BOOL)isAlphanumeric
{
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet alphanumericCharacterSet]].length == 0;
}

- (BOOL)isWhitespace
{
  return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0;
}

- (BOOL)isAbbrevationFor:(NSString *)longer
{
  if (self.length <= 2) {
    return NO;
  }
  NSRange range = NSMakeRange(0, 1);
  NSString *letter = [self substringWithRange:range];
  if (! [longer hasPrefix:letter]) {
    return NO;
  }
  
  NSArray *longWords = [longer componentsSeparatedByString:@" "];
  if (longWords.count != self.length) {
    return NO;
  }
  
  for (NSUInteger i = 1; i < self.length; i++) {
    range = NSMakeRange(i, 1);
    letter = [self substringWithRange:range];
    NSString *longWord = longWords[i];
    if (![longWord hasPrefix:letter]) {
      return NO;
    }
  }
  
  return YES;
}

@end

@implementation TKAutocompletionResult

+ (TKImage *)imageForType:(TKAutocompletionSearchIcon)type
{
	switch (type) {
    case TKAutocompletionSearchIconCity:
      return [TKStyleManager imageNamed:@"icon-search-city"];
      
    case TKAutocompletionSearchIconContact:
      return [TKStyleManager imageNamed:@"icon-search-contact"];
      
    case TKAutocompletionSearchIconCurrentLocation:
      return [TKStyleManager imageNamed:@"icon-search-currentlocation"];
      
    case TKAutocompletionSearchIconPin:
      return [TKStyleManager imageNamed:@"icon-search-pin"];
      
    case TKAutocompletionSearchIconCalendar:
      return [TKStyleManager imageNamed:@"icon-search-calendar"];
      
    case TKAutocompletionSearchIconHistory:
      return [TKStyleManager imageNamed:@"icon-search-history"];
      
    case TKAutocompletionSearchIconFavourite:
      return [TKStyleManager imageNamed:@"icon-search-favourite"];
  }
}

+ (NSUInteger)scoreBasedOnDistanceFromCoordinate:(CLLocationCoordinate2D)coordinate
                                        toRegion:(MKCoordinateRegion)coordinateRegion
                                    longDistance:(BOOL)longDistance
{
  MKCoordinateRegion worldRegion = MKCoordinateRegionForMapRect(MKMapRectWorld);
  if (fabs(worldRegion.span.latitudeDelta - coordinateRegion.span.latitudeDelta) < 1
      && fabs(worldRegion.span.longitudeDelta - coordinateRegion.span.longitudeDelta) < 1) {
    return 100;
  }
  
  CLLocation *location = [[CLLocation alloc] initWithLatitude:coordinate.latitude
                                                    longitude:coordinate.longitude];
  CLLocationCoordinate2D center = coordinateRegion.center;
  CLLocation *centerLocation = [[CLLocation alloc] initWithLatitude:center.latitude
                                                          longitude:center.longitude];
  CLLocationDistance meters = [location distanceFromLocation:centerLocation];
  CLLocationDistance zeroScoreDistance = longDistance ? 20000000 : 25000;
  if (meters >= zeroScoreDistance) {
    return 0;
  }
  double match = longDistance ? sqrt(meters) / sqrt(zeroScoreDistance) : meters / zeroScoreDistance;
  double proportion = 1.0 - match;
  NSUInteger max = 100;
  NSUInteger score = (NSUInteger) (proportion * max);
  return score;
}

- (NSComparisonResult)compare:(TKAutocompletionResult *)other
{
  if (self.score > other.score) {
    return NSOrderedAscending;
  } else if (self.score < other.score) {
    return NSOrderedDescending;
  } else {
    return NSOrderedSame;
  }
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    self.score = 0;
  }
  return self;
}

#pragma mark - Score computation

+ (NSUInteger)scoreBasedOnNameMatchBetweenSearchTerm:(NSString *)fullTarget
                                           candidate:(NSString *)fullCandidate
{
  NSString *target = [self stringForScoringOfString:fullTarget];
  NSString *candidate = [self stringForScoringOfString:fullCandidate];

  if (target.length == 0) {
    return candidate.length == 0 ? 100 : 0;
  }
  
  if (candidate.length == 0) {
    return 100; // having typed yet means a perfect match of everything you've typed so far
  }
  
  if ([target isEqualToString:candidate]) {
    return 100;
  }
  
  if ([target isAbbrevationFor:candidate]
      || [target isAbbrevationFor:[self stringForScoringOfString:fullCandidate removeBrackets:YES]]) {
    return 95;
  }

  if ([candidate isAbbrevationFor:target]
      || [candidate isAbbrevationFor:[self stringForScoringOfString:fullTarget removeBrackets:YES]]) {
    return 90;
  }

  NSUInteger excess = candidate.length - target.length;
  NSRange fullMatchRange = [candidate rangeOfString:target];
  if (fullMatchRange.location == 0) {
    // matches right at start
    return [self score:100 penalty:excess min:75];
  } else if (fullMatchRange.location != NSNotFound) {
    NSString *before = [candidate substringWithRange:NSMakeRange(fullMatchRange.location - 1, 1)];
    if ([before isWhitespace]) {
      // matches beginning of word
      return [self score:75
                 penalty:fullMatchRange.location * 2 + excess
                     min:33];
    } else {
      // in-word match
      return [self score:25 penalty:excess min:5];
    }
  }
  
  // non-substring matches
  NSArray *targetWords = [target componentsSeparatedByString:@" "];
  NSUInteger lastIndex = 0;
  for (NSString *targetWord in targetWords) {
    NSUInteger location = [candidate rangeOfString:targetWord].location;
    if (location == NSNotFound) {
      return 0; // missing a word!
    } else if (location >= lastIndex) {
      // still in order, keep going
      lastIndex = location;
    } else {
      // wrong order, abort with penalty
      return [self score:10 penalty:excess min:0];
    }
  }
  
  // contains all target words in order
  // do we have all the finished words
  for (NSUInteger i = 0; i < targetWords.count - 1; i++) {
    NSString *targetWord = targetWords[i];
    NSRange range = [candidate rangeOfString:targetWord];
    NSString *after = (range.location + range.length + 1 < candidate.length) ? [candidate substringWithRange:NSMakeRange(range.location + range.length, 1)] : @"";
    if ([after isWhitespace]) {
      // full word match, continue with next
    } else {
      // candidate doesn't have a completed word
      return [self score:33 penalty:excess min:10];
    }
  }

  return [self score:66 penalty:excess min:40];
}

+ (NSUInteger)rangedScoreForScore:(NSUInteger)score
                   betweenMinimum:(NSUInteger)minimum
                       andMaximum:(NSUInteger)maximum
{
  NSUInteger range = maximum - minimum;
  float percentage = score / 100.f;
  return (NSUInteger) ceil(percentage * range) + minimum;
}

+ (NSUInteger)score:(NSUInteger)maximum
            penalty:(NSUInteger)penalty
                min:(NSUInteger)minimum
{
  if (penalty > maximum - minimum) {
    return minimum;
  } else {
    return maximum - penalty;
  }
}

#pragma mark - Helpers

+ (NSString *)stringForScoringOfString:(NSString *)string
{
  return [self stringForScoringOfString:string removeBrackets:NO];
}

+ (NSString *)stringForScoringOfString:(NSString *)string removeBrackets:(BOOL)removeBrackets
{
  if (removeBrackets) {
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"(.*)\\(.*\\)" options:0 error:nil];
    string = [regex stringByReplacingMatchesInString:string options:0 range:NSMakeRange(0, [string length]) withTemplate:@"$1"];
  }
  
  NSMutableString *mutable = [NSMutableString stringWithCapacity:string.length];
  
  __block BOOL lastWasWhitespace = YES;
  [string enumerateSubstringsInRange:NSMakeRange(0, string.length)
                             options:NSStringEnumerationByComposedCharacterSequences
                          usingBlock:
   ^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
#pragma unused(substringRange, enclosingRange, stop)
     BOOL isAlphanumeric = [substring isAlphanumeric];
     BOOL isWhiteSpace   = [substring isWhitespace];
     if (isWhiteSpace) {
       if (lastWasWhitespace) {
         return; // ignore
       } else {
         [mutable appendString:substring];
         lastWasWhitespace = YES;
       }
     } else if (isAlphanumeric) {
       lastWasWhitespace = NO;
       [mutable appendString:[substring lowercaseString]];
     } else {
       return; // just ignore it
     }
   }];
  return [mutable stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end


