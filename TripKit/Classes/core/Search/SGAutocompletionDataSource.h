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

@class SGAutocompletionResult;
@class SGAutocompletionDataSourceSwiftStorage;

typedef NS_CLOSED_ENUM(NSInteger, SGSearchSection) {
  SGSearchSectionSticky,
  SGSearchSectionAutocompletion,
  SGSearchSectionMore,
};

typedef NS_CLOSED_ENUM(NSInteger, SGSearchSticky) {
  SGSearchStickyUnknown = 0,
  SGSearchStickyCurrentLocation,
  SGSearchStickyDroppedPin,
  SGSearchStickyNextEvent,
};

typedef NS_CLOSED_ENUM(NSInteger, SGSearchExtraRow) {
  SGSearchExtraRowSearchForMore = 0,
  SGSearchExtraRowProvider,
};


NS_ASSUME_NONNULL_BEGIN

@interface SGAutocompletionDataSource : NSObject
#if TARGET_OS_IPHONE
  <SGSearchDataSource>
#endif

- (instancetype)initWithStorage:(SGAutocompletionDataSourceSwiftStorage *)storage;

@property (nonatomic, strong) SGAutocompletionDataSourceSwiftStorage *storage;

@property (nonatomic, assign) BOOL showAccessoryButtons;

#if TARGET_OS_IPHONE
@property (nonatomic, weak, nullable) UIViewController *presenter;
#endif

/**
 * Main method required to configure the autocompleter for a new search.
 */
- (void)prepareForNewSearchForMapRect:(MKMapRect)mapRect
         showStickyForCurrentLocation:(BOOL)stickyForGPS
                 showStickyForDropPin:(BOOL)stickyForDropped
                    showSearchOptions:(BOOL)showSearchOptions;

- (SGSearchSection)typeOfSection:(NSInteger)section;

- (SGSearchExtraRow)extraRowAtIndexPath:(NSIndexPath *)indexPath;

- (SGSearchSticky)stickyOptionAtIndexPath:(NSIndexPath *)indexPath;

@end

NS_ASSUME_NONNULL_END
