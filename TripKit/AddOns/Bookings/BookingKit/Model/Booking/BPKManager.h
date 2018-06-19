//
//  BPKManager.h
//  TripKit
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import <Foundation/Foundation.h>

@interface BPKManager : NSObject

// ****** Properties ******

@property (nonatomic, strong) NSURL *refreshURLForSourceObject;

@property (nonatomic, assign) BOOL showReminder;
@property (nonatomic, assign) BOOL wantsReminder;
@property (nonatomic, assign) NSInteger reminderHeadway; // in minutes

@end


