//
//  AMKItem.h
//  TripGo
//
//  Created by Kuan Lun Huang on 16/02/2015.
//
//

#import <Foundation/Foundation.h>

typedef void (^AMKDidSelectItemHandler)();

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

/**
 *  A convenience initializer for items that will be used store info obtained from
 *  external accounts such as Facebook. By default, items used for external accounts
 *  are read-only.
 *
 *  @return An instance of AMKItem that has read-only property set to true.
 */
- (AMKItem *)initForExternalAccount;

- (void)addDidSelectHandler:(AMKDidSelectItemHandler)handler forActionType:(AMKItemActionType)type;

@end


