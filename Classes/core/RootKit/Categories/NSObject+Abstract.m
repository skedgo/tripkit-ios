//
//  NSObject+Abstract.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 17/11/12.
//
//

#import "NSObject+Abstract.h"

@implementation NSObject (Abstract)

+ (void)abstract
{
#ifdef DEBUG
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
#endif
}

- (void)abstract
{
#ifdef DEBUG
  // Objective C has no support for abstract methods, so we're raising an exception instead
  NSException *ex = [NSException exceptionWithName:@"Abstract Method Not Overridden"
                                            reason:@"You MUST override this save method"
                                          userInfo:nil];
  [ex raise];
#endif
}

@end
