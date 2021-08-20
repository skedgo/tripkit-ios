//
//  TKMacro.h
//  TripKitObjc
//
//  Created by Adrian Schönig on 13/8/21.
//

#ifndef TKMacro
#define TKMacro

#pragma mark -
#pragma mark Useful macro methods

// Debugging log and assertion functions
#ifdef DEBUG
#define ALog(...) [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:__VA_ARGS__]
#else // DEBUG
#define ALog(...) do {} while (0)
#ifndef NS_BLOCK_ASSERTIONS
#define NS_BLOCK_ASSERTIONS
#endif // end NS_BLOCK_ASSERTIONS
#endif // end else DEBUG
#define ZAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while (0)


#endif /* TKMacro */
