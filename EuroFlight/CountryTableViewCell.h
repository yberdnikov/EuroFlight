//
//  CountryTableViewCell.h
//  EuroFlight
//
//  Created by Ken Szubzda on 3/7/15.
//  Copyright (c) 2015 OkStupid. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Country.h"
#import "City.h"

@class CountryTableViewCell;

@protocol CountryTableViewCellDelegate <NSObject>

- (void)didTapEvent:(CountryTableViewCell *)cell;
- (void)didTapCityPrice:(City *)city;
- (void)didTapInfo:(City *)city;
@end

@interface CountryTableViewCell : UITableViewCell

@property (nonatomic, strong) Country *country;
@property (nonatomic, weak) id<CountryTableViewCellDelegate> delegate;
@property (nonatomic, assign) NSInteger eventIndex;
@property (nonatomic, assign) BOOL countryCellSelected;

// call this to animate the showing/hiding of the city views
// returns YES if animation was set to occur, NO otherwise
- (BOOL)showCityViews:(BOOL)showViews;

@end
