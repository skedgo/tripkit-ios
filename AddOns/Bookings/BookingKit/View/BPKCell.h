//
//  SGPaymentBaseCell.h
//  TripGo
//
//  Created by Kuan Lun Huang on 27/01/2015.
//
//

@import UIKit;

#ifdef TK_NO_FRAMEWORKS
#import "SGTableCell.h"
#else
@import TripKitUI;
#endif

#import "BPKConstants.h"

#import "NSString+BookingKit.h"

@class BPKSectionItem;

@interface BPKCell : SGTableCell

@property (nonatomic, assign, getter=isReadOnly) BOOL readOnly;

- (UITableViewCellAccessoryType)accessoryTypeForItem:(BPKSectionItem *)item;

@end

typedef void (^BPKDidChangeValueHandler)(id newValue);

@protocol BPKFormCell <NSObject>

@property (nonatomic, copy) BPKDidChangeValueHandler didChangeValueHandler;

- (void)configureForItem:(BPKSectionItem *)item;

@end
