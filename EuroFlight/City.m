//
//  City.m
//  EuroFlight
//
//  Created by Ken Szubzda on 3/7/15.
//  Copyright (c) 2015 OkStupid. All rights reserved.
//

#import "City.h"
#import "Context.h"
#import "TripClient.h"
#import "PlacesClient.h"
#import "Place.h"
#import "Trip.h"
#import "KimonoClient.h"
#import "FavoritesManager.h"
#import "SkyscannerClient.h"
#import "Event.h"

#define kPushNotificationDelay 7

NSString * const FavoritedNotification = @"FavoritedNotification";

@interface City ()

@property (nonatomic, strong) NSDictionary *summaries;

@end

@implementation City

- (void)initSkyscannerTripsWithCompletion:(void (^)())completion {
    [[SkyscannerClient sharedInstance] flightSearchWithDestinationAirport:self.airportCodes[0] completion:^(NSArray *results, NSError *error) {
        if (error) {
            NSLog(@"error retrieving flights to %@ from Skyscanner: %@", self.airportCodes[0], error);
        } else {
            self.skyscannerTrips = results;
            completion();
        }
    }];
}

- (void)getGoogleFlightsWithCompletion:(void (^)())completion {
    __block NSInteger completedAirports;
    completedAirports = 0;
    for (NSString *airportCode in self.airportCodes) {
        [[TripClient sharedInstance] tripsWithDestinationAirport:airportCode completion:^(NSArray *trips, NSError *error) {
            if (error) {
                NSLog(@"Error retrieving flights from Google: %@", error);
            } else {
                [self.trips addObjectsFromArray:trips];
            }

            if (++completedAirports >= self.airportCodes.count) {
                completion();
            }
        }];
    }
}

NSString * const kPlaceDataPrefix = @"PlaceData";

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self) {
        self.name = dictionary[@"city"];
        self.trips = [[NSMutableArray alloc] init];
        self.airportCodes = dictionary[@"airportCodes"];

        // don't ask for flights yet
//        for (NSString *airportCode in self.airportCodes) {
//            [self makeFlightRequestWithAirportCode:airportCode];
//        }

        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[self userDefaultsKeyWithCity:self.name]];
        if (data != nil) {
            NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            //NSLog(@"Using saved data");
            self.places = [Place placesWithArray:dictionary[@"results"]];
        } else {
            [[PlacesClient sharedInstance] searchWithCity:self.name success:^(AFHTTPRequestOperation *operation, id response) {
                NSLog(@"Status %@", response[@"status"]);
                if ([response[@"status"] isEqualToString:@"OK"]) {
                    self.places = [Place placesWithArray:response[@"results"]];
                    NSData *data = [NSJSONSerialization dataWithJSONObject:response options:0 error:NULL];
                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:[self userDefaultsKeyWithCity:self.name]];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Failed for %@", self.name);
            }];
        }
        
        NSString *summary = [KimonoClient sharedInstance].placeSummaries[self.name];
        if (summary != nil) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\s+[^\\.]+\\.{3}$" options:0 error:nil];
            NSString *truncatedSummary = [regex stringByReplacingMatchesInString:summary options:0 range:NSMakeRange(0, [summary length]) withTemplate:@""];
            self.summary = truncatedSummary;
        }
        self.imageURL = [KimonoClient sharedInstance].cityImages[self.name];
        self.events = [NSMutableArray array];
    }
    return self;
}

- (NSString *)userDefaultsKeyWithCity:(NSString *)cityName {
    return [NSString stringWithFormat:@"%@%@", kPlaceDataPrefix, cityName];
}

- (void)makeFlightRequestWithAirportCode:(NSString *)airportCode {
    [[TripClient sharedInstance] tripsWithDestinationAirport:airportCode completion:^(NSArray *trips, NSError *error) {
        if (error) {
            NSLog(@"Error retrieving flights from Google: %@", error);
        } else {
            [self.trips addObjectsFromArray:trips];
        }
    }];
}

// dynamically compute the lowest cost across all trips available
- (float)lowestCost {
    float min = [[self.trips valueForKeyPath:@"@min.flightCost"] floatValue];
    return min;
}

- (NSString *)currencyType {
    if (self.trips.count > 0) {
        return ((Trip *) self.trips[0]).currencyType;
    } else {
        return nil;
    }
}

- (BOOL)isFavorited {
    return [[FavoritesManager sharedInstance] isCityNameFavorited:self.name];
}

// TODO any way to make this a custom setter instead of an exposed method?
- (void)setFavoritedState:(BOOL)state {
    [[FavoritesManager sharedInstance] setCity:self favorited:state];

    // set up local notification for the first event in the city
    if (state && self.events.count > 0) {
        Event *event = [self.events firstObject];

        NSDictionary *userInfo =
        @{
          @"cityName": self.name,
          @"eventName" : event.name
          };

        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
        localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:kPushNotificationDelay];
        localNotification.alertBody = [NSString stringWithFormat:@"%@ is coming up in %@! Book your flight!", event.name, self.name];
        localNotification.soundName = UILocalNotificationDefaultSoundName;
        localNotification.userInfo = userInfo;
        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
    }
}

@end
