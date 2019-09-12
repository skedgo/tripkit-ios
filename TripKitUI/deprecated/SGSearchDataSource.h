//
//  SGSearchDataSource.h
//  TripKit
//
//  Created by Adrian Schoenig on 22/06/2016.
//
//

#if TARGET_OS_IPHONE

NS_CLASS_DEPRECATED(10_10, 10_13, 2_0, 11_0, "Use TKAutocompleting instead")
@protocol SGSearchDataSource <UITableViewDataSource>

@optional
- (BOOL)searchShouldShowAccessoryButtons;

@end

#endif
