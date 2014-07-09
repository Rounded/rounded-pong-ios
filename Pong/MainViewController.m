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
#import "AppDelegate.h"

@interface MainViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

@end

@implementation MainViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"WHO ARE YOU?";
    self.view.backgroundColor = UIColorFromRGB(GREEN);
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(GREEN);
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Raleway-Medium" size:18], NSForegroundColorAttributeName: [UIColor whiteColor] }];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(grabUsers:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    [SVProgressHUD showWithStatus:@"Pulling users"];
    [self grabUsers:nil];
}

- (void)grabUsers:(id)sender
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:@"http://rounded-pong.herokuapp.com/users.json" parameters:nil success:^(AFHTTPRequestOperation *operation, NSArray *users) {
        [SVProgressHUD dismiss];
        [users enumerateObjectsUsingBlock:^(User *user, NSUInteger idx, BOOL *stop) {
            if (![User MR_findFirstByAttribute:@"id" withValue:[user valueForKey:@"id"]]) {
                User *u = [User MR_createEntity];
                u.name = [user valueForKey:@"name"];
                u.id = [user valueForKey:@"id"];
            }
            AppDelegate *appDelegate = [UIApplication sharedApplication].delegate;
            [appDelegate.managedObjectContext save:nil];
        }];
        [self.refreshControl endRefreshing];
        [self.tableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error);
        [SVProgressHUD showErrorWithStatus:@"Woops"];
        [self.refreshControl endRefreshing];
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
    cell.backgroundColor = UIColorFromRGB(GREEN);
    cell.textLabel.textColor = [UIColor whiteColor];
//    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectedBackgroundView = [UIView new];
    cell.selectedBackgroundView.backgroundColor = UIColorFromRGB(GREENDARK);
    cell.textLabel.font = [UIFont fontWithName:@"Asap-Regular" size:16];
    
    cell.textLabel.text = user.name.uppercaseString;
    
    return cell;
}

#pragma mark - Table view data delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    User *user = [[User MR_findAllSortedBy:@"name" ascending:YES] objectAtIndex:indexPath.row];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:user.id forKey:@"currentUserID"];
    [defaults synchronize];
    
    
    UserViewController *userViewController = [UserViewController new];
    userViewController.user = user;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:userViewController];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

-(UITableView *)tableView
{
    if (!_tableView) {
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, 320, screenRect.size.height-64)];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.backgroundColor = UIColorFromRGB(GREEN);
        _tableView.separatorColor = UIColorFromRGB(GREENDARK);
        [self.view addSubview:_tableView];
    }
    return _tableView;
}

@end
