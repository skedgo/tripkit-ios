//
//  AMKItem.h
//  TripKit
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#import <Foundation/Foundation.h>

typedef void (^AMKDidSelectItemHandler)(void);

typedef NS_ENUM(NSUInteger, AMKItemActionType) {
  AMKItemActionType_None,
  AMKItemActionType_Standard,
  AMKItemActionType_Destructive
};

@interface AMKItem : NSObject

@property (nonatomic, assign, getter=isReadOnly) BOOL readOnly;

@property (nonatomic, copy) NSString *primaryText;
@property (nonatomic, copy) NSString *secondaryText;

// Handle actions on select
@property (nonatomic, assign, readonly) AMKItemActionType actionType;
@property (nonatomic, copy, readonly) AMKDidSelectItemHandler didSelectHandler;

- (void)addDidSelectHandler:(AMKDidSelectItemHandler)handler forActionType:(AMKItemActionType)type;

@end


