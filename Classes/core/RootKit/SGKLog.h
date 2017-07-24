//
//  SGKLog.h
//  TripKit
//
//  Created by Adrian Schoenig on 30/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SGKLog : NSObject

+ (void)info:(NSString *)identifier block:(NSString *(^)(void))block;
+ (void)debug:(NSString *)identifier block:(NSString *(^)(void))block;
+ (void)verbose:(NSString *)identifier block:(NSString *(^)(void))block;

+ (void)error:(NSString *)identifier text:(NSString *)message;
+ (void)warn:(NSString *)identifier text:(NSString *)message;
+ (void)info:(NSString *)identifier text:(NSString *)message;
+ (void)debug:(NSString *)identifier text:(NSString *)message;
+ (void)verbose:(NSString *)identifier text:(NSString *)message;

+ (void)info:(NSString *)identifier format:(NSString *)message, ...;
+ (void)error:(NSString *)identifier format:(NSString *)message, ...;
+ (void)warn:(NSString *)identifier format:(NSString *)message, ...;

+ (nullable NSArray *)logFilePaths;

@end

NS_ASSUME_NONNULL_END
