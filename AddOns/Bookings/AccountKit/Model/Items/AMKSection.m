//
//  SGUserAccountSection.m
//  WotGo
//
//  Created by Kuan Lun Huang on 12/12/2014.
//  Copyright (c) 2014 Adrian Schoenig. All rights reserved.
//

#import "AMKSection.h"

@interface AMKSection ()

@property (nonatomic, strong) NSMutableArray *mItems;

@end

@implementation AMKSection

- (instancetype)init
{
  self = [super init];
  
  if (self) {
    _mItems = [NSMutableArray array];
  }
  
  return self;
}

- (void)addItem:(AMKItem *)item
{
  if (item != nil) {
    [_mItems addObject:item];
  }
}

- (NSArray *)items
{
  return _mItems;
}

@end

