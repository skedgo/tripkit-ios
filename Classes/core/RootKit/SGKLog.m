//
//  SGKLog.m
//  TripGo
//
//  Created by Adrian Schoenig on 30/04/2015.
//  Copyright (c) 2015 SkedGo Pty Ltd. All rights reserved.
//

#import "SGKLog.h"

#import "SGKBetaHelper.h"

#ifdef ENABLE_SGKLOG
@import CocoaLumberjack;

// See https://github.com/CocoaLumberjack/CocoaLumberjack/issues/542
#ifdef DEBUG
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;
#else
static const DDLogLevel ddLogLevel = DDLogLevelWarning;
#endif

#endif

typedef NS_ENUM(NSInteger, SGKLogLevel) {
  SGKLogLevel_Error    = 0,
  SGKLogLevel_Warn     = 1,
  SGKLogLevel_Info     = 2,
  SGKLogLevel_Debug    = 3,
  SGKLogLevel_Verbose  = 4,
};

#ifndef SGK_DEBUG_LEVEL
  #ifdef DEBUG
    #define SGK_DEBUG_LEVEL SGKLogLevel_Verbose
  #else
    #define SGK_DEBUG_LEVEL SGKLogLevel_Warn
  #endif
#endif



@implementation SGKLog

+ (void)info:(NSString *)identifier block:(NSString *(^)())block
{
  [self log:identifier level:SGKLogLevel_Info block:block];
}

+ (void)debug:(NSString *)identifier block:(NSString *(^)())block
{
  [self log:identifier level:SGKLogLevel_Debug block:block];
}

+ (void)verbose:(NSString *)identifier block:(NSString *(^)())block
{
  [self log:identifier level:SGKLogLevel_Verbose block:block];
}

+ (void)error:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:SGKLogLevel_Error text:message];
}

+ (void)warn:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:SGKLogLevel_Warn text:message];
}

+ (void)info:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:SGKLogLevel_Info text:message];
}

+ (void)debug:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:SGKLogLevel_Debug text:message];
}

+ (void)verbose:(NSString *)identifier text:(NSString *)message
{
  [self log:identifier level:SGKLogLevel_Verbose text:message];
}

+ (void)error:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:SGKLogLevel_Error text:fullMessage];
}

+ (void)warn:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:SGKLogLevel_Warn text:fullMessage];
}

+ (void)info:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:SGKLogLevel_Info text:fullMessage];
}

+ (void)debug:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:SGKLogLevel_Debug text:fullMessage];
}

+ (void)verbose:(NSString *)identifier format:(NSString *)formatString, ...
{
  va_list variadicArguments;
  va_start(variadicArguments, formatString);
  NSString *fullMessage = [[NSString alloc] initWithFormat:formatString arguments:variadicArguments];
  va_end(variadicArguments);
  [self log:identifier level:SGKLogLevel_Verbose text:fullMessage];
}

+ (NSArray *)logFilePaths
{
#ifdef ENABLE_SGKLOG
  for (id<DDLogger> logger in [DDLog allLoggers]) {
    if ([logger isKindOfClass:[DDFileLogger class]]) {
      DDFileLogger *fileLogger = (DDFileLogger *)logger;
      return [fileLogger.logFileManager sortedLogFilePaths];
    }
  }
#endif
  return nil;
}


#pragma mark - Private

+ (void)log:(NSString *)identifier level:(SGKLogLevel)level block:(NSString *(^)())block
{
  if (SGK_DEBUG_LEVEL < level || ![SGKBetaHelper isDev]) {
    return;
  }
  NSString *message = block();
  [self log:identifier level:level text:message];
}


+ (void)log:(NSString *)identifier level:(SGKLogLevel)level text:(NSString *)message
{
  if (SGK_DEBUG_LEVEL < level || ![SGKBetaHelper isDev]) {
    return;
  }
  
#ifdef ENABLE_SGKLOG

  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [DDLog addLogger:[DDASLLogger sharedInstance]];
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];
    fileLogger.rollingFrequency = 60 * 60 * 24; // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:fileLogger];
  });
  
  switch (level) {
    case SGKLogLevel_Error:
      DDLogError(@"E %@: %@", identifier, message);
      break;
      
    case SGKLogLevel_Warn:
      DDLogWarn(@"W %@: %@", identifier, message);
      break;

    case SGKLogLevel_Info:
      DDLogInfo(@"i %@: %@", identifier, message);
      break;

    case SGKLogLevel_Debug:
      DDLogDebug(@"d %@: %@", identifier, message);
      break;

    case SGKLogLevel_Verbose:
      DDLogVerbose(@"v %@: %@", identifier, message);
      break;
  }
  
#elif DEBUG
  DLog(@"%@: %@", identifier, message);
#endif
}


@end
