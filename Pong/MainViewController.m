//
//  MainViewController.m
//  Pong
//
//  Created by bw on 6/18/14.
//  Copyright (c) 2014 bw. All rights reserved.
//

#import "MainViewController.h"
#import "UserViewController.h"
#import <AFNetworking.h>
#import "User.h"
#import <SVProgressHUD.h>

@interface MainViewController ()

@property (nonatomic, strong) UITableView *tableView;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Rounded Scoreboard";
    [self.tableView setNeedsLayout];
    
    [self grabUsers];
}

- (void)grabUsers
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [SVProgressHUD showWithStatus:@"Pulling users"];
    [manager GET:@"http://rounded-pong.herokuapp.com/users.json" parameters:nil success:^(AFHTTPRequestOperation *operation, NSArray *users) {
        [SVProgressHUD dismiss];
        [users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
            if (![User MR_findFirstByAttribute:@"id" withValue:[user valueForKey:@"id"]]) {
                User *u = [User MR_createEntity];
                u.name = [user valueForKey:@"name"];
                u.id = [user valueForKey:@"id"];
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [User MR_findAll].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [[User MR_findAllSortedBy:@"name" ascending:YES] objectAtIndex:indexPath.row];
    
    static NSString *CellIdentifier = @"tableViewCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tableViewCellIdentifier"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = user.name;
    
    return cell;
}

#pragma mark - Table view data delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UserViewController *userViewController = [UserViewController new];
    userViewController.user = [[User MR_findAllSortedBy:@"name" ascending:YES] objectAtIndex:indexPath.row];
    [self.navigationController pushViewController:userViewController animated:true];
}

-(UITableView *)tableView
{
    if (!_tableView) {
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = [UIColor whiteColor];
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

@end
