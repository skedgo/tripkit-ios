//
//  AMKEmail.h
//  TripKit
//
//  Created by Kuan Lun Huang on 9/02/2015.
//
//

#import <Foundation/Foundation.h>

@interface AMKEmail : NSObject

@property (nonatomic, copy) NSString *address;
@property (nonatomic, assign) BOOL isPrimary;
@property (nonatomic, assign) BOOL isVerified;

- (instancetype)initWithAddress:(NSString *)address isPrimary:(BOOL)primary isVerified:(BOOL)verified;

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

- (NSDictionary *)toDictionary;

@end
