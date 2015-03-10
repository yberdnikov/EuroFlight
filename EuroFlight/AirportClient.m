//
//  AirportClient.m
//  EuroFlight
//
//  Created by Ken Szubzda on 3/9/15.
//  Copyright (c) 2015 OkStupid. All rights reserved.
//

#import "AirportClient.h"
#import "Airport.h"

NSString * const kAirportAeroBaseUrl = @"https://airport.api.aero/";
NSString * const kAirportAeroKey = @"49cfc5c6fa0f1e4a9bef3ce3e71d7a5a";

@implementation AirportClient

// Docs: https://www.developer.aero/Airport-API/Try-it-Now

+ (AirportClient *)sharedInstance {
    static AirportClient *instance = nil;
    static dispatch_once_t token;
    
    dispatch_once(&token, ^ {
        instance = [[AirportClient alloc] initWithBaseURL:[NSURL URLWithString:kAirportAeroBaseUrl]];
    });
    
    return instance;
}

- (void)searchAirportByName:(NSString *)name completion:(void (^)(NSMutableArray *, NSError *))completion {
    NSString *url = [NSString stringWithFormat:@"/airport/match/%@", name];
    [self GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSMutableArray *airports = [Airport airportsWithArray:responseObject];
        completion(airports, nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Failed retrieving airports: %@", error);
        completion(nil, error);
    }];
}

@end
