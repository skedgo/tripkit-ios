//
//  AutocompletionDataSource.m
//  TripGo
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import "SGAutocompletionDataSource.h"

#ifdef TK_NO_FRAMEWORKS
#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"
#else
@import TripKit;
#endif

#import "SGAutocompletionDataProvider.h"
#import "SGAutocompletionResult.h"

typedef enum {
	SGSearchSectionSticky,
	SGSearchSectionAutocompletion,
	SGSearchSectionMore,
} SGSearchSection;

typedef enum {
	SGSearchStickyUnknown = 0,
	SGSearchStickyCurrentLocation,
	SGSearchStickyDroppedPin,
	SGSearchStickyNextEvent,
} SGSearchSticky;

typedef enum {
	SGSearchExtraRowSearchForMore = 0,
	SGSearchExtraRowProvider,
} SGSearchExtraRow;


@interface SGAutocompletionDataSource ()

@property (nonatomic, strong) NSArray *fastDataProviders;
@property (nonatomic, strong) NSArray *slowDataProviders;

@property (nonatomic, strong) NSArray *filteredPreviousResults; // cache
@property (nonatomic, strong) NSArray *fastResults;
@property (nonatomic, strong) NSArray *slowResults;
@property (nonatomic, strong) NSOperationQueue *fastQueue;
@property (nonatomic, strong) NSOperationQueue *slowQueue;

@property (nonatomic, strong) NSArray *additionalProviderRows;
@property (nonatomic, assign, getter = isFiltering) BOOL filtering;

@property (nonatomic, strong) NSTimer *slowTimer;
@property (nonatomic, copy) NSString *lastSearch;

@property (nonatomic, assign) BOOL showStickyForCurrentLocation;
@property (nonatomic, assign) BOOL showTextForCurrentCity;
@property (nonatomic, assign) BOOL showStickyForDropPin;
@property (nonatomic, assign) BOOL showSearchOptions;
@property (nonatomic, assign) BOOL startedTyping;

@end

@implementation SGAutocompletionDataSource

#pragma mark - Public methods

- (instancetype)initWithDataProviders:(NSArray *)dataProviders
{
	self = [super init];
	if (self) {
    NSMutableArray *fastProviders = [NSMutableArray arrayWithCapacity:dataProviders.count];
    NSMutableArray *slowProviders = [NSMutableArray arrayWithCapacity:dataProviders.count];
    SGAutocompletionDataProviderResultType granularity = SGAutocompletionDataProviderResultTypeRegion;
    for (id<SGAutocompletionDataProvider> provider in dataProviders) {
      BOOL canBeFast = [provider respondsToSelector:@selector(autocompleteFast:forMapRect:)];
      BOOL canBeSlow = [provider respondsToSelector:@selector(autocompleteSlowly:forMapRect:completion:)];
      if (canBeFast) {
        [fastProviders addObject:provider];
      }
      if (canBeSlow) {
        [slowProviders addObject:provider];
      }
      ZAssert(canBeSlow || canBeFast, @"Provider is neither slow nor fast: %@", provider);

      SGAutocompletionDataProviderResultType providerType = provider.resultType;
      if (providerType < granularity) {
        granularity = providerType;
      }
    }
    self->_granularity = granularity;
    if (fastProviders.count > 0) {
      self.fastDataProviders = fastProviders;
    }
    if (slowProviders.count > 0) {
      self.slowDataProviders = slowProviders;
    }
	}
	return self;
}

- (void)prepareForNewSearchShowStickyForCurrentLocation:(BOOL)stickyForGPS
                                   showStickyForDropPin:(BOOL)stickyForDropped
                                      showSearchOptions:(BOOL)showSearchOptions
{
  // config for what to include in autocompletion
  self.showStickyForCurrentLocation = stickyForGPS;
  self.showStickyForDropPin = stickyForDropped;
  self.showSearchOptions = showSearchOptions;
 
  // local variable set-up
  self.lastSearch = nil;
	self.filteredPreviousResults = nil;
  self.additionalProviderRows = nil;
  self.fastResults = @[];
  self.slowResults = @[];
  self.startedTyping = NO;
}

- (void)prepareForNewScopeSearchShowStickyForCurrentLocation:(BOOL)stickyForGPS
{
  // config for what to include in autocompletion
  self.showStickyForCurrentLocation = stickyForGPS;
  self.showTextForCurrentCity = YES;
  self.showStickyForDropPin = NO;
  self.showSearchOptions = NO;
  
  // local variable set-up
  self.lastSearch = nil;
  self.filteredPreviousResults = nil;
  self.additionalProviderRows = nil;
  self.fastResults = @[];
  self.slowResults = @[];
  self.startedTyping = NO;
}

- (void)autocomplete:(NSString *)string
          forMapRect:(MKMapRect)mapRect
          completion:(SGSearchAutocompletionActionBlock)completion
{
  if (! self.lastSearch) {
    self.lastSearch = string;
  }
  if (! [self.lastSearch isEqualToString:string]) {
    self.startedTyping = string.length > 0; // must have typed something!
  }
  
  [self filterContentForSearchText:string
                        forMapRect:mapRect
                        completion:
   ^(BOOL refreshRequired) {
     dispatch_async(dispatch_get_main_queue(), ^{
       completion(refreshRequired);
     });
   }];
}

- (void)processSelectionOfIndexPath:(NSIndexPath *)indexPath
                             result:(SGSearchAutocompletionResultBlock)resultBlock
{
  SGSearchSection sectionType = [self typeOfSection:indexPath.section];
  switch (sectionType) {
    case SGSearchSectionSticky: {
      SGSearchSticky stickyOption = [self stickyOptionAtIndexPath:indexPath];
      switch (stickyOption) {
        case SGSearchStickyCurrentLocation:
          resultBlock(SGAutocompletionResultCurrentLocation, nil);
          break;
          
        case SGSearchStickyDroppedPin:
          resultBlock(SGAutocompletionResultDropPin, nil);
          break;
          
        default:
          [SGKLog warn:@"SGAutocompletionDataSource" format:@"Unexpected sticky: %d", stickyOption];
          break;
      }
      break;
    }
      
    case SGSearchSectionAutocompletion: {
      if (indexPath.row < (NSInteger)self.filteredPreviousResults.count) {
        SGAutocompletionResult *result = [self.filteredPreviousResults objectAtIndex:indexPath.row];
        resultBlock(SGAutocompletionResultObject, result);
      } else {
        [SGKLog warn:@"SGAutocompletionDataSource" format:@"Invalid index path: %@", indexPath];
      }
      break;
    }
      
    case SGSearchSectionMore: {
      SGSearchExtraRow extraRow = [self extraRowAtIndexPath:indexPath];
      switch (extraRow) {
        case SGSearchExtraRowSearchForMore: {
          resultBlock(SGAutocompletionResultSearchForMore, nil);
          break;
        }
          
        case SGSearchExtraRowProvider: {
          NSInteger additionRowIndex = indexPath.row - 1; // substract 'press search for more row'
          if (additionRowIndex < 0 || additionRowIndex >= (NSInteger)self.additionalProviderRows.count) {
            ZAssert(false, @"Selected %@ but there's not enough content: %@", indexPath, self.additionalProviderRows);
            return;
          }
          id<SGAutocompletionDataProvider> provider = self.additionalProviderRows[additionRowIndex];
          [provider additionalAction:^(BOOL refreshRequired) {
            if (refreshRequired) {
              resultBlock(SGAutocompletionResultRefresh, nil);
            }
          }];
          break;
        }
      }
    }
  }
}

#pragma mark - SGSearchDataSource / UITableViewDataSource

- (BOOL)searchShouldShowAccessoryButtons
{
  return self.showAccessoryButtons;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#pragma unused(tableView)
  NSInteger sections = 0;
  if ([self showStickyOptions]) {
    sections++;
  }
  if (self.filteredPreviousResults.count > 0) {
    sections++;
  }
  if ([self numberOfExtraRows] > 0) {
    sections++;
  }
  return sections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#pragma unused(tableView)
  SGSearchSection sectionType = [self typeOfSection:section];
  switch (sectionType) {
    case SGSearchSectionSticky:
      return [self numberOfStickyOptions];
      
    case SGSearchSectionAutocompletion:
      return [self.filteredPreviousResults count];
      
    case SGSearchSectionMore:
      return [self numberOfExtraRows];
  }
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	static NSString *kCellID = @"LocationPickerResultsTableCell";
	
	UITableViewCell *cell = [tv dequeueReusableCellWithIdentifier:kCellID];
  if (cell == nil) {
    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:kCellID];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
  
    BOOL autoShrinkText = NO;
    if (autoShrinkText) {
      cell.textLabel.minimumScaleFactor = 0.5f;
      cell.detailTextLabel.minimumScaleFactor = 0.5f;
    } else {
      // Forcng the minimum scale factor here, otherwise, texts would still
      // get shrunk in some cases.
      cell.textLabel.minimumScaleFactor = 1.0f;
      cell.detailTextLabel.minimumScaleFactor = 1.0f;
    }
	}
  
  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.accessoryView = nil;
	
  SGSearchSection sectionType = [self typeOfSection:indexPath.section];
  switch (sectionType) {
    case SGSearchSectionSticky: {
      SGSearchSticky stickyOption = [self stickyOptionAtIndexPath:indexPath];
      [self configureCell:cell forStickyOption:stickyOption];
      break;
    }
      
    case SGSearchSectionAutocompletion: {
      NSUInteger row = indexPath.row;
      if (row >= self.filteredPreviousResults.count) {
        [SGKLog warn:@"SGAutocompletionDataSource" format:@"Unexpected index path in autocompletion results: %@", indexPath];
        row = (NSUInteger) MAX(0, (NSInteger)self.filteredPreviousResults.count - 1);
      }
      
      SGAutocompletionResult *result = [self.filteredPreviousResults objectAtIndex:row];
      [self configureCell:cell forResult:result];
      break;
    }
      
    case SGSearchSectionMore: {
      [self configureCell:cell forExtraRowAtIndexPath:indexPath];
      break;
    }
  }
  
  cell.backgroundColor = [UIColor clearColor];
	return cell;
}

- (void)configureCell:(UITableViewCell *)cell forStickyOption:(SGSearchSticky)stickyOption
{
  if (stickyOption == SGSearchStickyCurrentLocation) {
    if (self.showTextForCurrentCity) {
      cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Current City", @"Shared", [SGStyleManager bundle], "Current city");
    } else {
      cell.textLabel.text = Loc.CurrentLocation;
    }
    cell.textLabel.textColor  = [SGStyleManager darkTextColor];
		cell.detailTextLabel.text = @"";
		cell.imageView.image = [[self class] imageForSticky:stickyOption];
		
	} else if (stickyOption == SGSearchStickyDroppedPin) {
    cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Drop new pin", @"Shared", [SGStyleManager bundle], "Drop new pin");
    cell.textLabel.textColor  = [SGStyleManager darkTextColor];
		cell.detailTextLabel.text = @"";
		cell.imageView.image = [[self class] imageForSticky:stickyOption];
  }
}

- (void)configureCell:(UITableViewCell *)cell forResult:(SGAutocompletionResult *)result
{
  cell.imageView.image      = result.image;
  cell.imageView.tintColor  = [UIColor colorWithWhite:216/255.f alpha:1]; // From SkedGo default icons
  cell.textLabel.text       = result.title;
  cell.textLabel.textColor  = [SGStyleManager darkTextColor];
  cell.detailTextLabel.text = ! [result.subtitle isEqualToString:result.title] ? result.subtitle : nil;
  cell.detailTextLabel.textColor  = [SGStyleManager lightTextColor];
  if (self.showAccessoryButtons && result.accessoryButtonImage) {
    cell.accessoryView = [SGStyleManager cellAccessoryButtonWithImage:result.accessoryButtonImage
                                                               target:self
                                                               action:@selector(accessoryButtonTapped:withEvent:)];
    }
}

- (void)configureCell:(UITableViewCell *)cell forExtraRowAtIndexPath:(NSIndexPath *)indexPath
{
  cell.textLabel.textColor = [SGStyleManager lightTextColor];
  cell.detailTextLabel.text = @"";
  cell.imageView.image = nil;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;
  
  SGSearchExtraRow extraRow = [self extraRowAtIndexPath:indexPath];
  switch (extraRow) {
    case SGSearchExtraRowSearchForMore:
      cell.textLabel.text = NSLocalizedStringFromTableInBundle(@"Press 'search' for more...", @"Shared", [SGStyleManager bundle], @"Location picker 'no autocompletion results' text. Needs to match text on keyboard.");
      break;
      
    case SGSearchExtraRowProvider: {
      NSInteger index = indexPath.row - 1;
      if (index >= 0 && index < (NSInteger)self.additionalProviderRows.count) {
        id<SGAutocompletionDataProvider> provider = self.additionalProviderRows[index];
        cell.textLabel.text = [provider additionalActionString];
      } else {
        [SGKLog warn:@"SGAutocompletionDataSource" text:@"Bad row!"];
        cell.textLabel.text = @"";
      }
    }
  }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
#pragma unused(tableView)
  SGSearchSection sectionType = [self typeOfSection:section];
  switch (sectionType) {
    case SGSearchSectionAutocompletion:
      return [self showStickyOptions] ? NSLocalizedStringFromTableInBundle(@"Instant results", @"Shared", [SGStyleManager bundle], "Instant results proposal") : nil;
      
    case SGSearchSectionMore:
      return NSLocalizedStringFromTableInBundle(@"More results", @"Shared", [SGStyleManager bundle], "More results proposal");
      
    case SGSearchSectionSticky:
      return nil;
  }
}


#pragma mark - Helpers

- (BOOL)showStickyOptions
{
  return ! self.startedTyping && (self.showStickyForCurrentLocation || self.showStickyForDropPin);
}

- (SGSearchSection)typeOfSection:(NSUInteger)section
{
  BOOL stickies = [self showStickyOptions];
  BOOL filtered = self.filteredPreviousResults.count > 0;
  
  if (section == 0) {
    if (stickies) {
      return SGSearchSectionSticky;
    } else if (filtered) {
      return SGSearchSectionAutocompletion;
    } else {
      return SGSearchSectionMore;
    }
  } else if (section == 1) {
    if (stickies) {
      if (filtered) {
        return SGSearchSectionAutocompletion;
      } else {
        return SGSearchSectionMore;
      }
    } else {
      return SGSearchSectionMore;
    }
  } else {
    return SGSearchSectionMore;
  }
}

- (NSInteger)numberOfExtraRows
{
  NSInteger extraRows = 0;
  if (self.showSearchOptions) {
    extraRows++; // the 'search for more'
  }
  if (self.isFiltering) {
    extraRows += self.additionalProviderRows.count;
  }
  return extraRows;
}

- (SGSearchExtraRow)extraRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.showSearchOptions && 0 == indexPath.row) {
    return SGSearchExtraRowSearchForMore;
  } else {
    return SGSearchExtraRowProvider;
  }
}

- (NSInteger)numberOfStickyOptions
{
  NSInteger options = 0;
  if (self.showStickyForCurrentLocation) {
    options++;
  }
  if (self.showStickyForDropPin) {
    options++;
  }
  return options;
}

- (SGSearchSticky)stickyOptionAtIndexPath:(NSIndexPath *)indexPath
{
  if (indexPath.row == 0
      && self.showStickyForCurrentLocation) {
    return SGSearchStickyCurrentLocation;
  }
  return SGSearchStickyDroppedPin;
}

+ (UIImage *)imageForSticky:(SGSearchSticky)sticky
{
	switch (sticky) {
		case SGSearchStickyCurrentLocation:
			return [SGAutocompletionResult imageForType:SGAutocompletionSearchIconCurrentLocation];
			
		case SGSearchStickyDroppedPin:
			return [SGAutocompletionResult imageForType:SGAutocompletionSearchIconPin];
			
		case SGSearchStickyNextEvent:
			return [SGAutocompletionResult imageForType:SGAutocompletionSearchIconCalendar];
			
		default:
			return nil;
	}
}

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
  UITableView *tableView = nil;
  UIView *superview = button;
  while (superview) {
    if ([superview isKindOfClass:[UITableView class]]) {
      tableView = (UITableView *)superview;
      break;
    } else {
      superview = [superview superview];
    }
  }
  if (! tableView)
    return;
  
  NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:[[[event touchesForView:button] anyObject]
                                                              locationInView:tableView]];
  if (! indexPath)
    return;
  
  [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}


#pragma mark - Private methods for populating and filtering search results

+ (NSString *)identifierForProvider:(id<SGAutocompletionDataProvider>)provider
{
  return NSStringFromClass([provider class]);
}

/* This method takes the content of the 'previousResults' array and filters it according to the specified
 * search text and scope. The results are stored in the 'filteredPreviousResults' property, overwriting
 * whatever was in there before.
 *
 * Warning: Completion block will likely be called back on background thread!
 */
- (void)filterContentForSearchText:(NSString *)searchText
                        forMapRect:(MKMapRect)mapRect
                        completion:(SGSearchAutocompletionActionBlock)completion
{
  NSString *string = searchText;
	self.filtering = (0 < [string length] && NO == [string.lowercaseString isEqualToString:Loc.CurrentLocation.lowercaseString]);
	
  if (NO == self.isFiltering) {
    string = nil; // we want empty results!
  }
  if (!string) {
    string = @"";
  }
  
  self.lastSearch = string;
  
  // We do NOT reset `slowResults` and `fastResults` on purpose as otherwise the
  // UI would flicker with them disappearing and popping back in.
  
  // Fast results, we shoot of immediately
  if (self.fastDataProviders.count > 0) {
    [self.fastQueue cancelAllOperations];
    NSUInteger expectedFast = self.fastDataProviders.count;
    __weak typeof (self) weakSelf = self;
    __block NSMutableDictionary *fastResults = [NSMutableDictionary dictionaryWithCapacity:self.fastDataProviders.count];
    
    for (id<SGAutocompletionDataProvider> fastProvider in self.fastDataProviders) {
      [self.fastQueue addOperationWithBlock:^{
        __strong typeof (weakSelf) strongSelf = weakSelf;
        if (strongSelf && (! string || [string isEqualToString:strongSelf.lastSearch])) {
          NSArray *results = [fastProvider autocompleteFast:string forMapRect:mapRect];
          if (!results) {
            results = @[];
          }
          NSString *identifier = [SGAutocompletionDataSource identifierForProvider:fastProvider];
          fastResults[identifier] = results;
          if (fastResults.count == expectedFast) {
            [strongSelf providersCompletedForResults:fastResults
                                           forSearch:string
                                             wasFast:YES
                                     completionBlock:completion];
          }
        }
      }];
    }
  }

  if (self.slowDataProviders.count > 0) {
    [self.slowQueue cancelAllOperations];
    [self.slowTimer invalidate];
    NSDictionary *userInfo = @{
                               @"searchText": string,
                               @"mapRectX": @(mapRect.origin.x),
                               @"mapRectY": @(mapRect.origin.y),
                               @"mapRectWidth": @(mapRect.size.width),
                               @"mapRectHeight": @(mapRect.size.height),
                               @"completion": completion,
                               };
    
    self.slowTimer = [NSTimer scheduledTimerWithTimeInterval:0.3
                                                      target:self
                                                    selector:@selector(performSlowAutocompletion:)
                                                    userInfo:userInfo
                                                     repeats:NO];
  }
}

- (void)performSlowAutocompletion:(NSTimer *)timer
{
  NSDictionary *userInfo = timer.userInfo;
  NSString *string = userInfo[@"searchText"];
  MKMapRect mapRect = MKMapRectMake([userInfo[@"mapRectX"] doubleValue],
                                    [userInfo[@"mapRectY"] doubleValue],
                                    [userInfo[@"mapRectWidth"] doubleValue],
                                    [userInfo[@"mapRectHeight"] doubleValue]);
  SGSearchAutocompletionActionBlock completion = userInfo[@"completion"];
  
  NSUInteger expectedSlow = self.slowDataProviders.count;
  __block NSMutableDictionary *slowResults = [NSMutableDictionary dictionaryWithCapacity:self.slowDataProviders.count];
  
  __weak typeof (self) weakSelf = self;
  for (id<SGAutocompletionDataProvider> slowProvider in self.slowDataProviders) {
    [self.slowQueue addOperationWithBlock:^{
      __strong typeof (weakSelf) strongSelf = weakSelf;
      if (strongSelf && (! string || [string isEqualToString:strongSelf.lastSearch])) {
        [slowProvider autocompleteSlowly:string
                              forMapRect:mapRect
                              completion:
         ^(NSArray *results) {
           if (!results) {
             results = @[];
           }
           NSString *identifier = [SGAutocompletionDataSource identifierForProvider:slowProvider];
           slowResults[identifier] = results;
           if (slowResults.count == expectedSlow) {
             [strongSelf providersCompletedForResults:slowResults
                                            forSearch:string
                                              wasFast:NO
                                      completionBlock:completion];
           }
         }];
      }
    }];
  }
}
                 

- (void)providersCompletedForResults:(NSDictionary *)autocompleterResults
                           forSearch:(NSString *)searchText
                             wasFast:(BOOL)isFast
                     completionBlock:(SGSearchAutocompletionActionBlock)completion
{
  NSArray *providers = isFast ? self.fastDataProviders : self.slowDataProviders;

  if (NO == [self.lastSearch isEqualToString:searchText]) {
    if (completion) {
      completion(NO);
    }
    return;
  }
  
  NSArray *results = @[];
  if (autocompleterResults.count > 0) {
    NSMutableArray *newResults = [NSMutableArray array];
    for (id<SGAutocompletionDataProvider> provider in providers) {
      NSString *identifier = [SGAutocompletionDataSource identifierForProvider:provider];
      for (SGAutocompletionResult *result in autocompleterResults[identifier]) {
        result.provider = provider;
        [newResults addObject:result];
      }
    }
    results = newResults;
  }
  if (isFast) {
    self.fastResults = results;
  } else {
    self.slowResults = results;
  }
  self.filteredPreviousResults = nil;
  completion(YES);
}

#pragma mark - Lazy accessors

- (NSOperationQueue *)slowQueue
{
  if (!_slowQueue) {
    _slowQueue = [[NSOperationQueue alloc] init];
    _slowQueue.name = @"com.buzzhives.TripGo.autocompletion.remote";
    _slowQueue.qualityOfService = NSQualityOfServiceUserInitiated;
  }
  return _slowQueue;
}

- (NSOperationQueue *)fastQueue
{
  if (!_fastQueue) {
    _fastQueue = [[NSOperationQueue alloc] init];
    _fastQueue.name = @"com.buzzhives.TripGo.autocompletion.local";
    _fastQueue.qualityOfService = NSQualityOfServiceUserInitiated;
  }
  return _fastQueue;
}

- (NSArray *)filteredPreviousResults
{
  if (! _filteredPreviousResults) {
    NSArray *results = [self.fastResults arrayByAddingObjectsFromArray:self.slowResults];
    results = [results sortedArrayWithOptions:NSSortStable
                              usingComparator:
               ^NSComparisonResult(SGAutocompletionResult *result1, SGAutocompletionResult *result2) {
                 return [result1 compare:result2];
               }];
    _filteredPreviousResults = results;
  }
  return _filteredPreviousResults;
}

- (NSArray *)additionalProviderRows
{
  if (! _additionalProviderRows) {
    NSArray *allProviders = [self.fastDataProviders arrayByAddingObjectsFromArray:self.slowDataProviders];
    NSMutableArray *extraRows = [NSMutableArray arrayWithCapacity:allProviders.count];
    for (id<SGAutocompletionDataProvider> provider in allProviders) {
      if ([provider respondsToSelector:@selector(additionalActionString)]) {
        NSString *extraActionString = [provider additionalActionString];
        if (extraActionString) {
          [extraRows addObject:provider];
        }
      }
    }
    _additionalProviderRows = extraRows;
  }
  return _additionalProviderRows;
}

@end
