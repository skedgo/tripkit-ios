//
//  TKLog.m
//  TripKit
//
//  Created by Adrian Schoenig on 30/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "TKLog.h"

#import "TKBetaHelper.h"

typedef NS_ENUM(NSInteger, TKLogLevel) {
  TKLogLevel_Error    = 0,
  TKLogLevel_Warn     = 1,
  TKLogLevel_Info     = 2,
  TKLogLevel_Debug    = 3,
  TKLogLevel_Verbose  = 4,
};

#ifndef TK_DEBUG_LEVEL
  #ifdef DEBUG
    #define TK_DEBUG_LEVEL TKLogLevel_Verbose
  #else
    #define TK_DEBUG_LEVEL TKLogLevel_Warn
  #endif
#endif



@implementation TKLog

+ (void)info:(NSString *)identifier block:(NSString * _Nonnull (^)(void))block
{
  [self log:identifier level:TKLogLevel_Info block:block];
}

+ (void)debug:(NSString *)identifier block:(NSString * _Nonnull (^)(void))block
{
  [self log:identifier level:TKLogLevel_Debug block:block];
}

+ (void)verbose:(NSString *)identifier block:(NSString * _Nonnull (^)(void))block
{
  [self log:identifier level:TKLogLevel_Verbose block:block];
}

+ (void)error:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:TKLogLevel_Error text:message];
}

+ (void)warn:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:TKLogLevel_Warn text:message];
}

+ (void)info:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:TKLogLevel_Info text:message];
}

+ (void)debug:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:TKLogLevel_Debug text:message];
}

+ (void)verbose:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:TKLogLevel_Verbose text:message];
}

+ (void)error:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:TKLogLevel_Error text:fullMessage];
}

+ (void)warn:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:TKLogLevel_Warn text:fullMessage];
}

+ (void)info:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:TKLogLevel_Info text:fullMessage];
}

+ (void)debug:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:TKLogLevel_Debug text:fullMessage];
}

+ (void)verbose:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:TKLogLevel_Verbose text:fullMessage];
}

#pragma mark - Private

+ (void)log:(NSString *)identifier level:(TKLogLevel)level block:(NSString *(^)(void))block
{
  if (TK_DEBUG_LEVEL < level || ![TKBetaHelper isDev]) {
    return;
  }
  NSString *message = block();
  [self log:identifier level:level text:message];
}


+ (void)log:(NSString *)identifier level:(TKLogLevel)level text:(NSString *)message
{
  if (TK_DEBUG_LEVEL < level || ![TKBetaHelper isDev]) {
    return;
  }
  
#ifdef DEBUG
  DLog(@"%@: %@", identifier, message);
#endif
}


@end
