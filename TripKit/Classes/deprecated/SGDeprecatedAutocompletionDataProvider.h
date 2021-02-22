//
//  SGDeprecatedAutocompletionDataProvider.h
//  TripKit
//
//  Created by Adrian Schoenig on 23/10/2013.
//
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

#import "TKCrossPlatform.h"

NS_ASSUME_NONNULL_BEGIN

@class TKAutocompletionResult;
@protocol SGDeprecatedAutocompletionDataProvider;

typedef void(^SGAutocompletionDataResultBlock)(NSArray <TKAutocompletionResult*> * _Nullable results);

typedef void(^SGAutocompletionDataActionBlock)(BOOL refreshRequired);

@protocol SGDeprecatedAutocompletionDataProvider <NSObject>

@optional

/**
 Called whenever the user types a character. This is called asynchronously on a background to not block the user from typing the next character. This method needs to return as soon as possible and not make any remote requests. Use `autocompleteSlowly:forMapRect:completion` if you need to make remote requests.
 
 @param string text which should get autocompleted
 
 @return Sorted list of `TKAutocompletionResult` objects.
 */
- (NSArray<TKAutocompletionResult *> *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect;


/**
 Called whenever the user types a character. This is called asynchronously on a background to not block the user from typing the next character. This method should return immediately, and execute remote requests in a separate queue and then call the completion block.
 
 @param string text which should get autocompleted
 @param completion Sorted list of `TKAutocompletionResult` objects.
 */
- (void)autocompleteSlowly:(NSString *)string
                forMapRect:(MKMapRect)mapRect
                completion:(SGAutocompletionDataResultBlock)completion;

#if TARGET_OS_IPHONE
/**
 @return Optional text to display as part of the provider rows.
 */
- (nullable NSString *)additionalActionString;

/**
 Called when the provider row is tapped. Do your thing and execute the block when done, indicating if the autocompletion list should update itself.
 
 @param presenter View controller, that you can use to present
 @param actionBlock A block that you should call when you're done.
 */
- (void)additionalActionForPresenter:(UIViewController *)presenter completion:(SGAutocompletionDataActionBlock)actionBlock;
#endif

/**
 @param result The object previously returned from `autocomplete:`.
 @return The annotation for the object that you previously provided.
 */
- (nullable id<MKAnnotation>)annotationForAutocompletionResult:(TKAutocompletionResult *)result;

@end

NS_ASSUME_NONNULL_END
