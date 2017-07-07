//
//  SGSearchDataSource.h
//  Pods
//
//  Created by Adrian Schoenig on 22/06/2016.
//
//

#if TARGET_OS_IPHONE

@protocol SGSearchDataSource <UITableViewDataSource>

@optional
- (BOOL)searchShouldShowAccessoryButtons;

@end

#endif
