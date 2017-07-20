//
//  BPKManager.h
//  TripGo
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BPKCost, BPKUser, BPKForm;

@interface BPKManager : NSObject

// ****** Properties ******

@property (nonatomic, strong) NSURL *refreshURLForSourceObject;

@property (nonatomic, assign) BOOL showReminder;
@property (nonatomic, assign) BOOL wantsReminder;
@property (nonatomic, assign) NSInteger reminderHeadway; // in minutes

// ***** Public methods ******

//// Request payment
//+ (void)requestPaymentFromUser:(BPKUser *)user
//                       forCost:(BPKCost *)cost
//                        hitURL:(NSURL *)url
//                    completion:(SVKServerCompletionBlock)completion;

#ifdef BRAINTREE

// ----- Payment (Braintree) -----

- (void)requestPaymentWithInitiatingURL:(NSURL *)url
                         fromController:(UIViewController *)controller
                             completion:(void(^)(BPKForm *, NSError *))completion;

#endif

@end


