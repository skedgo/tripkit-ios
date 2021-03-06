//
//  BPKTextFieldBlock.h
//  TripKit
//
//  Created by Kuan Lun Huang on 12/02/2015.
//
//

#ifndef TripKit_BPKTextFieldBlock_h
#define TripKit_BPKTextFieldBlock_h

typedef void (^BPKTextFieldNilReturnBlock)(UITextField *textField);
typedef BOOL (^BPKTextFieldBoolReturnBlock)(UITextField *textField);

@protocol BPKTextFieldBlock <NSObject>

@optional

- (void)setTextFieldShouldEndEditingBlock:(BPKTextFieldNilReturnBlock)block;
- (void)setTextFieldDidEndEditingBlock:(BPKTextFieldNilReturnBlock)block;
- (void)setTextFieldDidBeginEditingBlock:(BPKTextFieldNilReturnBlock)block;
- (void)setTextFieldShouldBeginEditingBlock:(BPKTextFieldBoolReturnBlock)block;
- (void)setTextFieldShouldReturnBlock:(BPKTextFieldBoolReturnBlock)block;

@end

#endif
