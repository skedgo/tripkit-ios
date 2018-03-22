//
//  AutocompletionDataSource.m
//  TripKit
//
//  Created by Adrian Schoenig on 21/10/2013.
//
//

#import "SGAutocompletionDataSource.h"

#import "TripKit.h"
#import "TripKit/TripKit-Swift.h"

#import "SGAutocompletionDataProvider.h"
#import "SGAutocompletionResult.h"


@interface SGAutocompletionDataSource ()

@property (nonatomic, assign) BOOL showStickyForCurrentLocation;
@property (nonatomic, assign) BOOL showTextForCurrentCity;
@property (nonatomic, assign) BOOL showStickyForDropPin;
@property (nonatomic, assign) BOOL showSearchOptions;

@end

@implementation SGAutocompletionDataSource

#pragma mark - Public methods

- (instancetype)initWithStorage:(SGAutocompletionDataSourceSwiftStorage *)storage
{
	self = [super init];
	if (self) {
    self.storage = storage;
	}
	return self;
}

- (void)prepareForNewSearchForMapRect:(MKMapRect)mapRect
         showStickyForCurrentLocation:(BOOL)stickyForGPS
                 showStickyForDropPin:(BOOL)stickyForDropped
                    showSearchOptions:(BOOL)showSearchOptions
{
  // config for what to include in autocompletion
  self.showStickyForCurrentLocation = stickyForGPS;
  self.showStickyForDropPin = stickyForDropped;
  self.showSearchOptions = showSearchOptions;
 
  [self prepareForNewSearchForMapRect:mapRect];
}


#if TARGET_OS_IPHONE

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
  if (self.autocompletionResults.count > 0) {
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
      return [self.autocompletionResults count];
      
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
      if (row >= self.autocompletionResults.count) {
        [SGKLog warn:@"SGAutocompletionDataSource" format:@"Unexpected index path in autocompletion results: %@", indexPath];
        row = (NSUInteger) MAX(0, (NSInteger)self.autocompletionResults.count - 1);
      }
      
      SGAutocompletionResult *result = [self.autocompletionResults objectAtIndex:row];
      [self configureCell:cell forResult:result];
      break;
    }
      
    case SGSearchSectionMore: {
      [self configureCell:cell forExtraRowAtIndexPath:indexPath];
      break;
    }
  }
  
  cell.backgroundColor = [SGKColor clearColor];
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
  cell.imageView.tintColor  = [SGKColor colorWithWhite:216/255.f alpha:1]; // From SkedGo default icons
  cell.textLabel.text       = result.title;
  cell.textLabel.textColor  = [SGStyleManager darkTextColor];
  cell.detailTextLabel.text = ! [result.subtitle isEqualToString:result.title] ? result.subtitle : nil;
  cell.detailTextLabel.textColor  = [SGStyleManager lightTextColor];
  
  if (result.isInSupportedRegion) {
    cell.contentView.alpha = result.isInSupportedRegion.boolValue ? 1.0f : 0.33f;
  } else {
    cell.contentView.alpha = 1.0f;
  }
  
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
      if (index >= 0 && index < (NSInteger)self.additionalActions.count) {
        cell.textLabel.text = self.additionalActions[index];
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

#endif

#pragma mark - Helpers

- (BOOL)showStickyOptions
{
  return ! self.startedTyping && (self.showStickyForCurrentLocation || self.showStickyForDropPin);
}

- (SGSearchSection)typeOfSection:(NSInteger)section
{
  BOOL stickies = [self showStickyOptions];
  BOOL filtered = self.autocompletionResults.count > 0;
  
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
  extraRows += self.additionalActions.count;
  return extraRows;
}

- (SGSearchExtraRow)extraRowAtIndexPath:(NSIndexPath *)indexPath
{
  if (self.showSearchOptions && 0 == indexPath.item) {
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
  if (indexPath.item == 0
      && self.showStickyForCurrentLocation) {
    return SGSearchStickyCurrentLocation;
  }
  return SGSearchStickyDroppedPin;
}

+ (SGKImage *)imageForSticky:(SGSearchSticky)sticky
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

#if TARGET_OS_IPHONE

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

#endif


@end
