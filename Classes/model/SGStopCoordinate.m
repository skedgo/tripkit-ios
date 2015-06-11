//
//  SGStopCoordinate.m
//  TripGo
//
//  Created by Adrian Schoenig on 29/10/2014.
//
//

#import "SGStopCoordinate.h"

#import "SVKServerKit.h"

@implementation SGStopCoordinate

- (NSString *)stopCode
{
  return self.data[@"sg_stopCode"];
}

- (void)setStopCode:(NSString *)stopCode
{
  [self.data setValue:stopCode forKey:@"sg_stopCode"];
}

- (NSString *)stopShortName
{
  return self.data[@"sg_stopShortName"];
}

- (void)setStopShortName:(NSString *)stopShortName
{
  [self.data setValue:stopShortName forKey:@"sg_stopShortName"];
}

- (NSNumber *)stopSortScore
{
  return self.data[@"sg_stopSortScore"];
}

- (void)setStopSortScore:(NSNumber *)stopSortScore
{
  [self.data setValue:stopSortScore forKey:@"sg_stopSortScore"];
}

- (ModeInfo *)stopModeInfo
{
  return self.data[@"sg_modeInfo"];
}

- (void)setStopModeInfo:(ModeInfo *)stopModeInfo
{
  [self.data setValue:stopModeInfo forKey:@"sg_modeInfo"];
}

#pragma mark - ASDisplayablePoint protocol

- (NSString *)title
{
  return self.name;
}

- (BOOL)isDraggable
{
  return NO;
}

- (BOOL)pointDisplaysImage
{
  return (self.stopModeInfo.localImageName != nil);
}

- (UIImage *)pointImage
{
  return [SGStyleManager imageForModeImageName:self.stopModeInfo.localImageName
                                    isRealTime:NO
                                    ofIconType:SGStyleModeIconTypeMapIcon];
}

- (NSURL *)pointImageURL
{
  return [SVKServer imageURLForIconFileNamePart:self.stopModeInfo.remoteImageName
                                     ofIconType:SGStyleModeIconTypeMapIcon];
}

@end
