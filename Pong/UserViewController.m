//
//  UserViewController.m
//  Pong
//
//  Created by bw on 6/18/14.
//  Copyright (c) 2014 bw. All rights reserved.
//

#import "UserViewController.h"
#import <AFNetworking.h>
#import <SVProgressHUD.h>
#import "CoffeeScore.h"


@interface UserViewController () <MCSwipeTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation UserViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = self.user.name;
    self.view.backgroundColor = UIColorFromRGB(GREENDARK);

    [self.tableView setNeedsLayout];
    [self grabScores];
}

- (void)grabScores
{
//    [SVProgressHUD showWithStatus:@"Pulling scores"];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:[NSString stringWithFormat:@"http://rounded-pong.herokuapp.com/users/%@.json", self.user.id] parameters:nil success:^(AFHTTPRequestOperation *operation, NSArray *coffeeScores) {
//        [SVProgressHUD dismiss];
        [coffeeScores enumerateObjectsUsingBlock:^(CoffeeScore *coffeeScoreFromArray, NSUInteger idx, BOOL *stop) {
            CoffeeScore *coffeeScore = [CoffeeScore MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"paid_by_id = %@ AND paid_to_id = %@", [coffeeScoreFromArray valueForKey:@"paid_by_id"], self.user.id]]];
            
            if(!coffeeScore) {
                CoffeeScore *c = [CoffeeScore MR_createEntity];
                c.paid_by_id = [coffeeScoreFromArray valueForKey:@"paid_by_id"];
                c.paid_to_id = self.user.id;
                c.coffee_count = [coffeeScoreFromArray valueForKey:@"coffee_count"];
            } else {
                coffeeScore.coffee_count = [coffeeScoreFromArray valueForKey:@"coffee_count"];
            }
        }];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"YA GOT YA-SELF AN ERROR"];
        NSLog(@"Error: %@", error);
    }];

}

#pragma mark - Table view data stuff

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 54;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 40;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.backgroundColor = UIColorFromRGB(GREEN);
        tableViewHeaderFooterView.tintColor = UIColorFromRGB(GREEN);
        tableViewHeaderFooterView.backgroundView.alpha = 1.0;
        tableViewHeaderFooterView.alpha = 1.0;
        tableViewHeaderFooterView.textLabel.textColor = UIColorFromRGB(GREENDARKER);
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [NSString stringWithFormat:@"%@ is owed by", self.user.name];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [User MR_findAll].count-1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    User *user = [[User MR_findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"id != %@", self.user.id]] objectAtIndex:indexPath.row];
    CoffeeScore *coffeeScore = [CoffeeScore MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"paid_by_id = %@ AND paid_to_id = %@", user.id, self.user.id]]];
    if (!coffeeScore) {
        coffeeScore = [CoffeeScore MR_createEntity];
        coffeeScore.paid_by_id = user.id;
        coffeeScore.paid_to_id = self.user.id;
        coffeeScore.coffee_count = 0;
    }
    
    static NSString *CellIdentifier = @"Cell";
    
    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    UILabel *countLabel = nil;
    
    if (!cell) {
        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        // Setting the background color of the cell.
        cell.backgroundColor = UIColorFromRGB(GREEN);
        cell.textLabel.textColor = UIColorFromRGB(WHITE);
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = UIColorFromRGB(WHITE);

        countLabel = [[UILabel alloc] initWithFrame:CGRectMake(280, 0, 20, 54)];
        countLabel.textAlignment = NSTextAlignmentRight;
        countLabel.textColor = UIColorFromRGB(WHITE);
        [cell.contentView addSubview:countLabel];
    }
    
    // Configuring the views and colors.
    UIView *checkView = [self viewWithImageName:@"check"];
    UIColor *greenColor = UIColorFromRGB(GREENDARKER);
    
    UIView *crossView = [self viewWithImageName:@"cross"];
    UIColor *redColor = [UIColor colorWithRed:232.0 / 255.0 green:61.0 / 255.0 blue:14.0 / 255.0 alpha:1.0];
    
    // Setting the default inactive state color to the tableView background color.
    [cell setDefaultColor:[UIColor lightGrayColor]];
    
    [cell.textLabel setText:user.name];

    if (coffeeScore.coffee_count) {
        countLabel.text = [NSString stringWithFormat:@"%@", coffeeScore.coffee_count];
    } else {
        countLabel.text = @"0";
    }
    
    // Adding gestures per state basis.
    [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self changeCoffeeScore:coffeeScore withValue:-1];
    }];
    
    [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState2 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self changeCoffeeScore:coffeeScore withValue:-1];
    }];

    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self changeCoffeeScore:coffeeScore withValue:1];
    }];

    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState4 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
        [self changeCoffeeScore:coffeeScore withValue:1];
    }];
    
    return cell;
}

- (void)changeCoffeeScore:(CoffeeScore *)coffeeScore withValue:(int)valueToChange
{
    coffeeScore.coffee_count = [NSNumber numberWithInt:(coffeeScore.coffee_count.intValue+valueToChange)];
    [self.tableView reloadData];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters = @{ @"coffee_score[paid_by_id]":coffeeScore.paid_by_id, @"coffee_score[paid_to_id]":coffeeScore.paid_to_id, @"coffee_score[delta]": [NSString stringWithFormat:@"%d", valueToChange] };
    [manager POST:@"http://rounded-pong.herokuapp.com/coffee_scores.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"JSON: %@", responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (UIView *)viewWithImageName:(NSString *)imageName {
    UIImage *image = [UIImage imageNamed:imageName];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    imageView.contentMode = UIViewContentModeCenter;
    return imageView;
}

-(UITableView *)tableView
{
    if (!_tableView) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, screenRect.size.height)];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = UIColorFromRGB(GREEN);
        _tableView.separatorColor = UIColorFromRGB(GREENDARK);
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

@end
