//
//  BPKSever.h
//  TripKit
//
//  Created by Kuan Lun Huang on 16/11/2015.
//  Copyright © 2015 SkedGo Pty Ltd. All rights reserved.
//

@import Foundation;

#ifdef TK_NO_MODULE
#import "SVKServer.h"
#else
@import TripKit;
#endif

@interface BPKServerUtil : NSObject

+ (void)requestFormForBookingURL:(NSURL *)bookingURL
                        postData:(NSDictionary *)postData
                      completion:(SGServerGenericBlock)completion;

@end
