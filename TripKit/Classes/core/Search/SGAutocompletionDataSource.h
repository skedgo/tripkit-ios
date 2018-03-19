//
//  AutocompletionDataSource.h
//  TripKit
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "SGSearchDataSource.h"

typedef enum {
	SGAutocompletionResultCurrentLocation, // => nil
	SGAutocompletionResultDropPin, // => nil
	SGAutocompletionResultObject,
	SGAutocompletionResultRefresh, // => nil, please refresh the view
	SGAutocompletionResultSearchForMore, // => nil
} SGAutocompletionResultType;

@class SGAutocompletionResult;
@class SGAutocompletionDataSourceSwiftStorage;

NS_ASSUME_NONNULL_BEGIN

typedef void(^SGSearchAutocompletionResultBlock)(SGAutocompletionResultType resultType, SGAutocompletionResult * _Nullable result);

@interface SGAutocompletionDataSource : NSObject
#if TARGET_OS_IPHONE
  <SGSearchDataSource>
#endif

- (instancetype)initWithStorage:(SGAutocompletionDataSourceSwiftStorage *)storage;

@property (nonatomic, strong) SGAutocompletionDataSourceSwiftStorage *storage;

@property (nonatomic, assign) BOOL showAccessoryButtons;

/**
 * Main method required to configure the autocompleter for a new search.
 */
- (void)prepareForNewSearchShowStickyForCurrentLocation:(BOOL)stickyForGPS
                                   showStickyForDropPin:(BOOL)stickyForDropped
                                      showSearchOptions:(BOOL)showSearchOptions;

/**
 * Call this when the user picks an index path. It'll then tell you what to do.
 */
- (void)processSelectionOfIndexPath:(NSIndexPath *)indexPath
                             result:(SGSearchAutocompletionResultBlock)resultBlock;


@end

NS_ASSUME_NONNULL_END
