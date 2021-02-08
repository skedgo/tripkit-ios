//
//  TKBetaHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 28/01/2015.
//
//

#import "TKBetaHelper.h"

@implementation TKBetaHelper

+ (BOOL)isBeta
{
#if defined(DEBUG) || defined(BETA) || TARGET_OS_MACCATALYST
  return YES;
#else
  return NO;
#endif
}

@end
