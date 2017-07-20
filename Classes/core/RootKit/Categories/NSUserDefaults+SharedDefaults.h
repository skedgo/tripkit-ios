//
//  NSUserDefaults+SharedDefaults.h
//  TripGo
//
//  Created by Kuan Lun Huang on 30/12/2014.
//
//

#import <Foundation/Foundation.h>

@interface NSUserDefaults (SharedDefaults)

+ (nonnull NSUserDefaults *)sharedDefaults NS_REFINED_FOR_SWIFT;

@end
