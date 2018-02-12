//
//  SGAutocompletionDataProvider.h
//  TripKit
//
//  Created by Adrian Schoenig on 23/10/2013.
//
//

#import <Foundation/Foundation.h>

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

@class SGAutocompletionResult;
@protocol SGAutocompletionDataProvider;

typedef void(^SGAutocompletionDataResultBlock)(NSArray <SGAutocompletionResult*> * _Nullable results);
typedef void(^SGAutocompletionDataActionBlock)(BOOL refreshRequired);

typedef NS_ENUM(NSInteger, SGAutocompletionDataProviderResultType) {
  SGAutocompletionDataProviderResultTypeLocation = 1,
  SGAutocompletionDataProviderResultTypeRegion   = 2,
};

@protocol SGAutocompletionDataProvider <NSObject>

@property (nonatomic, assign, readonly) SGAutocompletionDataProviderResultType resultType;

@optional

/**
 Called whenever the user types a character. This is called asynchronously on a background to not block the user from typing the next character. This method needs to return as soon as possible and not make any remote requests. Use `autocompleteSlowly:forMapRect:completion` if you need to make remote requests.
 
 @param string text which should get autocompleted
 
 @return Sorted list of `SGAutocompletionResult` objects.
 */
- (NSArray<SGAutocompletionResult *> *)autocompleteFast:(NSString *)string forMapRect:(MKMapRect)mapRect;


/**
 Called whenever the user types a character. This is called asynchronously on a background to not block the user from typing the next character. This method should return immediately, and execute remote requests in a separate queue and then call the completion block.
 
 @param string text which should get autocompleted
 @param completion Sorted list of `SGAutocompletionResult` objects.
 */
- (void)autocompleteSlowly:(NSString *)string
                forMapRect:(MKMapRect)mapRect
                completion:(SGAutocompletionDataResultBlock)completion;

/**
 @return Optional text to display as part of the provider rows.
 */
- (nullable NSString *)additionalActionString;

/**
 Called when the provider row is tapped. Do your thing and execute the block when done, indicating if the autocompletion list should update itself.
 
 @param actionBlock A block that you should call when you're done.
 */
- (void)additionalAction:(SGAutocompletionDataActionBlock)actionBlock;

/**
 @param result The object previously returned from `autocomplete:`.
 @return The annotation for the object that you previously provided.
 */
- (nullable id<MKAnnotation>)annotationForAutocompletionResult:(SGAutocompletionResult *)result;

- (void)setMapView:(MKMapView *)mapView;

@end

NS_ASSUME_NONNULL_END
