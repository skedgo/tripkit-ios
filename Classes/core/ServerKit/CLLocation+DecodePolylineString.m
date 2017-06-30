//
//  CLLocation+DecodePolylineString.m
//  TripPlanner
//
//  Created by Adrian Schoenig on 2/05/13.
//
//

#import "CLLocation+DecodePolylineString.h"

@implementation CLLocation (DecodePolylineString)

// Thanks to http://objc.id.au/post/9245961184/mapkit-encoded-polylines
+ (NSArray *)decodePolyLine:(NSString *)encodedString
{
	const char *bytes = [encodedString UTF8String];
	NSUInteger length = [encodedString lengthOfBytesUsingEncoding:NSUTF8StringEncoding];
	NSUInteger idx = 0;
	
	NSUInteger count = length / 4;
	NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:count];

	float latitude = 0;
	float longitude = 0;
	while (idx < length) {
		char byte = 0;
		int res = 0;
		char shift = 0;
		
		do {
			if (idx > length) break;
			byte = bytes[idx++] - 63;
			res |= (byte & 0x1F) << shift;
			shift += 5;
		} while (byte >= 0x20);
		
		float deltaLat = ((res & 1) ? ~(res >> 1) : (res >> 1));
		latitude += deltaLat;
		
		shift = 0;
		res = 0;
		
		do {
			if (idx > length) break;
			byte = bytes[idx++] - 0x3F;
			res |= (byte & 0x1F) << shift;
			shift += 5;
		} while (byte >= 0x20);
		
		float deltaLon = ((res & 1) ? ~(res >> 1) : (res >> 1));
		longitude += deltaLon;
		
		double finalLat = latitude * 1E-5;
		double finalLon = longitude * 1E-5;
		
		CLLocation *location = [[CLLocation alloc] initWithLatitude:finalLat longitude:finalLon];
		[array addObject:location];
	}
	
	return array;
}

@end
