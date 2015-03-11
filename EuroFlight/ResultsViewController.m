//
//  ResultsViewController.m
//  EuroFlight
//
//  Created by Ken Szubzda on 3/7/15.
//  Copyright (c) 2015 OkStupid. All rights reserved.
//

#import "ResultsViewController.h"
#import "Country.h"
#import "CountryTableViewCell.h"
#import "CityTableViewCell.h"
#import "City.h"
#import "CityDetailsViewController.h"
#import "Event.h"
#import "EventDetailViewController.h"

@interface ResultsViewController () <UITableViewDataSource, UITableViewDelegate, CountryTableViewCellDelegate>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
// keeps track of all countries
@property (strong, nonatomic) NSArray *allCountries;
// keeps track of the countries we're currently displaying (i.e. all or favorites-only)
@property (strong, nonatomic) NSArray *countries;
@property (nonatomic, assign) NSInteger currentExpandedIndex;
@property (nonatomic, strong) NSMutableSet *expandedSections;
@property (nonatomic, assign) BOOL isFavoritesOnly;

@end

@implementation ResultsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerNib:[UINib nibWithNibName:@"CountryTableViewCell" bundle:nil] forCellReuseIdentifier:@"CountryTableViewCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"CityTableViewCell" bundle:nil] forCellReuseIdentifier:@"CityTableViewCell"];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.title = @"Flight Results";

    // set up favorites button
    UIImageView *favoritesImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"favorite-on"]];
    favoritesImageView.frame = CGRectMake(0, 0, 20, 20);
    favoritesImageView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onFavoritesButton)];
    [favoritesImageView addGestureRecognizer:tapGesture];
    UIBarButtonItem *favoritesButton = [[UIBarButtonItem alloc] initWithCustomView:favoritesImageView];
    self.navigationItem.rightBarButtonItem = favoritesButton;
    self.isFavoritesOnly = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)initWithResults {
    self = [super init];
    if (self) {
        self.countries = [Country initCountries];
        self.allCountries = self.countries;
        [self sortCountriesList];
        self.currentExpandedIndex = -1;
        self.expandedSections = [[NSMutableSet alloc] init];
    }
    return self;
}

#pragma mark helper methods
+ (NSComparisonResult)compareFloats:(float)first secondFloat:(float)second {
    if (first == second) {
        return NSOrderedSame;
    } else if (first > second) {
        return NSOrderedDescending;
    } else {
        return NSOrderedAscending;
    }
}

+ (NSNumberFormatter *)currencyFormatterWithCurrencyCode:(NSString *)code {
    static NSNumberFormatter *sharedFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (sharedFormatter == nil) {
            sharedFormatter = [[NSNumberFormatter alloc] init];
            [sharedFormatter setCurrencyCode:code];
            [sharedFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
        }
    });
    return sharedFormatter;
}

#pragma mark Table view methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BOOL sectionExpanded = [self.expandedSections containsObject:@(indexPath.section)];
    if (sectionExpanded && indexPath.row > 0) { // cell is child
        CityTableViewCell *cityCell = [self.tableView dequeueReusableCellWithIdentifier:@"CityTableViewCell"];
        cityCell.city = [((Country *) self.countries[indexPath.section]) citiesWithFavorite:self.isFavoritesOnly][indexPath.row - 1];
        return cityCell;
    } else {
        CountryTableViewCell *countryCell =  [self.tableView dequeueReusableCellWithIdentifier:@"CountryTableViewCell"];
        countryCell.country = (Country *) self.countries[indexPath.section];
        countryCell.delegate = self;
        return countryCell;
    }
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    BOOL sectionExpanded = [self.expandedSections containsObject:@(section)];
    if (sectionExpanded) {
        return [((Country *) self.countries[section]) citiesWithFavorite:self.isFavoritesOnly].count + 1;
    } else {
        return 1;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.countries.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    BOOL sectionExpanded = [self.expandedSections containsObject:@(indexPath.section)];
    if (sectionExpanded && indexPath.row > 0) { // cell is child
        CityDetailsViewController *vc = [[CityDetailsViewController alloc] init];
        vc.city = [((Country *)self.countries[indexPath.section]) citiesWithFavorite:self.isFavoritesOnly][indexPath.row - 1];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }
    
    [self.tableView beginUpdates];
    if (sectionExpanded) {
        [self.expandedSections removeObject:@(indexPath.section)];
        [self collapseSubItemsInSection:indexPath.section];
    } else {
        [self.expandedSections addObject:@(indexPath.section)];
        [self expandSubItemsInSection:indexPath.section];
    }
    [self.tableView endUpdates];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (void)collapseSubItemsInSection:(NSInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray new];
    for (NSInteger i = 1; i <= [((Country *) self.countries[section]) citiesWithFavorite:self.isFavoritesOnly].count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:section]];
    }
    [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void)expandSubItemsInSection:(NSInteger)section {
    NSMutableArray *indexPaths = [NSMutableArray new];
    NSArray *currentSubItems = [((Country *) self.countries[section]) citiesWithFavorite:self.isFavoritesOnly];
    NSInteger insertPos = 1;
    for (int i = 0; i < currentSubItems.count; i++) {
        [indexPaths addObject:[NSIndexPath indexPathForRow:insertPos++ inSection:section]];
    }
    [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationFade];
}

- (void)didTapEvent:(CountryTableViewCell *)cell {
    EventDetailViewController *vc = [[EventDetailViewController alloc] init];
    vc.event = [cell.country.events objectAtIndex:cell.eventIndex];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)onFavoritesButton {
    if (!self.isFavoritesOnly) {
        NSPredicate *favoritedPredicate = [NSPredicate predicateWithFormat:@"favoritedCities[SIZE] > 0"];
        self.countries = [self.allCountries filteredArrayUsingPredicate:favoritedPredicate];
    } else {
        self.countries = self.allCountries;
    }

    [self sortCountriesList];
    [self.expandedSections removeAllObjects];
    self.isFavoritesOnly = !self.isFavoritesOnly;
    [self.tableView reloadData];
}

- (void)sortCountriesList {
    self.countries = [self.countries sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        float price1 = ((Country *) obj1).lowestCost;
        float price2 = ((Country *) obj2).lowestCost;
        return [ResultsViewController compareFloats:price1 secondFloat:price2];
    }];
}

@end
