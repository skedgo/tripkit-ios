//
//  SGBPFormParser.h
//  TripGo
//
//  Created by Brian Huang on 30/01/2015.
//
//

#import <Foundation/Foundation.h>

@class BPKCost, BPKManager, BPKForm;

@interface BPKFormBuilder : NSObject

// Booking
+ (NSArray *)buildSectionsFromForm:(BPKForm *)form;
+ (NSDictionary *)buildFormFromSections:(NSArray *)sections;
+ (NSArray *)indexPathsForInvalidItemsInSections:(NSArray *)sections;

// Payment
+ (NSArray *)buildSectionsFromCost:(BPKCost *)cost;

// Confirmation
+ (NSArray *)buildReminderSectionWithManager:(BPKManager *)manager;


@end
