//
//  SGBetaHelper.m
//  TripKit
//
//  Created by Adrian Schoenig on 28/01/2015.
//
//

#import "SGKBetaHelper.h"

@implementation SGKBetaHelper

+ (BOOL)isBeta
{
#ifdef DEBUG
  return YES;
#else
#ifdef BETA
  return YES;
#else
  return NO;
#endif
#endif
}

+ (BOOL)isDev
{
#ifdef DEBUG
  return YES;
#else
  return NO;
#endif
}


@end
