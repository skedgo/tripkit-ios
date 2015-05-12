//
//  Cell.h
//  TripPlanner
//
//  Created by Adrian Schoenig on 28/11/12.
//
//

#import <CoreData/CoreData.h>

@interface Cell : NSManagedObject

///-----------------------------------------------------------------------------
/// @name CoreData Properties
///-----------------------------------------------------------------------------

@property (nonatomic, retain) NSString *identifier;
@property (nonatomic, retain) NSString *regionIdentifier;
@property (nonatomic, retain) NSNumber *flags;
@property (nonatomic, retain) NSDate *lastUpdate;
@property (nonatomic, retain) NSNumber *levelRaw;
@property (nonatomic, retain) NSNumber *hashCode;
@property (nonatomic, assign) BOOL toDelete;
@property (nonatomic, retain) NSSet *stops;

@end
