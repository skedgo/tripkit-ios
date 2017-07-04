//
//  AutocompletionDataSource.h
//  TripGo
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "SGSearchDataSource.h"
#import "SGAutocompletionDataProvider.h"

typedef enum {
	SGAutocompletionResultCurrentLocation, // => nil
	SGAutocompletionResultDropPin, // => nil
	SGAutocompletionResultObject,
	SGAutocompletionResultRefresh, // => nil, please refresh the view
	SGAutocompletionResultSearchForMore, // => nil
} SGAutocompletionResultType;

@class SGAutocompletionResult;

typedef void(^SGSearchAutocompletionActionBlock)(BOOL refreshRequired);
typedef void(^SGSearchAutocompletionResultBlock)(SGAutocompletionResultType resultType, SGAutocompletionResult *result);

@interface SGAutocompletionDataSource : NSObject <SGSearchDataSource>

- (instancetype)initWithDataProviders:(NSArray<id<SGAutocompletionDataProvider>> *)dataProviders;

@property (nonatomic, assign) BOOL showAccessoryButtons;

@property (nonatomic, assign, readonly) SGAutocompletionDataProviderResultType granularity;

/**
 * Main method required to configure the autocompleter for a new search.
 */
- (void)prepareForNewSearchShowStickyForCurrentLocation:(BOOL)stickyForGPS
                                   showStickyForDropPin:(BOOL)stickyForDropped
                                      showSearchOptions:(BOOL)showSearchOptions;

/**
 * Main method required to configure the autocompleter for a new scope search.
 */
- (void)prepareForNewScopeSearchShowStickyForCurrentLocation:(BOOL)stickyForGPS;

/**
 * Method that kicks of autocompletion. If it found something interesting
 * it'll call the completion/action block which tells the caller to trigger
 * a refresh of whatever thingy this data source provides data for.
 */
- (void)autocomplete:(NSString *)string
          forMapRect:(MKMapRect)mapRect
          completion:(SGSearchAutocompletionActionBlock)completion;

/**
 * Call this when the user picks an index path. It'll then tell you what to do.
 */
- (void)processSelectionOfIndexPath:(NSIndexPath *)indexPath
                             result:(SGSearchAutocompletionResultBlock)resultBlock;


@end
