//
//  AirportClient.h
//  EuroFlight
//
//  Created by Ken Szubzda on 3/9/15.
//  Copyright (c) 2015 OkStupid. All rights reserved.
//

#import "AFHTTPRequestOperationManager.h"

@interface AirportClient : AFHTTPRequestOperationManager
+ (AirportClient *)sharedInstance;
- (void)searchAirportByName:(NSString *)name completion:(void (^)(NSMutableArray *, NSError *))completion;
@end