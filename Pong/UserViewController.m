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
#import <POP/POP.h>

//#import <AVFoundation/AVFoundation.h>
//#include <AudioToolbox/AudioToolbox.h>

@interface UserViewController () <MCSwipeTableViewCellDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSNumber *lastTransactionID;
@property (nonatomic, strong) CoffeeScore *lastTransactionCoffee;

@end

@implementation UserViewController

- (void)viewDidAppear:(BOOL)animated
{
    [self becomeFirstResponder];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [self becomeFirstResponder];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.user = [User MR_findFirstByAttribute:@"id" withValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"currentUserID"]];
    
    self.title = self.user.name.uppercaseString;
    self.view.backgroundColor = UIColorFromRGB(GREENDARK);

//    self.navigationController.navigationItem.hidesBackButton = TRUE;
    self.view.backgroundColor = UIColorFromRGB(GREEN);
    self.navigationController.navigationBar.barTintColor = UIColorFromRGB(GREEN);
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.translucent = NO;
    [self.navigationController.navigationBar setTitleTextAttributes:@{ NSFontAttributeName: [UIFont fontWithName:@"Raleway-Medium" size:18], NSForegroundColorAttributeName: [UIColor whiteColor] }];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(dismiss)];

    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.tintColor = [UIColor whiteColor];
    [self.refreshControl addTarget:self action:@selector(grabScores:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [SVProgressHUD showWithStatus:@"Pulling latest scores"];
    [self grabScores:nil];
 
    [self.imageView setImage:[UIImage imageNamed:self.user.name]];
    [self.view addSubview:_imageView];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)topRightButtonPressed:(id)sender
{
//    //start a background sound
//    NSString *soundFilePath = [[NSBundle mainBundle] pathForResource:@"rain" ofType: @"mp3"];
//    NSURL *fileURL = [[NSURL alloc] initFileURLWithPath:soundFilePath ];
//    myAudioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
//    myAudioPlayer.numberOfLoops = -1; //infinite loop
//    [myAudioPlayer play];
//    
//    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
//    manager.responseSerializer = [AFJSONResponseSerializer serializer];
//    [manager PATCH:@"http://rounded-pong.herokuapp.com/rains/1.json" parameters:@{@"rain[make_it_rain]": @true} success:^(AFHTTPRequestOperation *operation, id responseObject) {
//        
//    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
//        
//    }];
}

- (void)grabScores:(id)sender
{
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    [manager GET:[NSString stringWithFormat:@"http://rounded-pong.herokuapp.com/users/%@.json", self.user.id] parameters:nil success:^(AFHTTPRequestOperation *operation, NSArray *coffeeScores) {
        [SVProgressHUD dismiss];
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
        [self.refreshControl endRefreshing];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [SVProgressHUD showErrorWithStatus:@"Woop! There's an error."];
        [self.refreshControl endRefreshing];
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
    
//    MCSwipeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
    
    if (!cell) {
//        cell = [[MCSwipeTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
        
        // Remove inset of iOS 7 separators.
        if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
            cell.separatorInset = UIEdgeInsetsZero;
        }
        
        [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
        
        // Setting the background color of the cell.
        cell.backgroundColor = UIColorFromRGB(GREEN);
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.selectedBackgroundView = [UIView new];
        cell.selectedBackgroundView.backgroundColor = UIColorFromRGB(GREENDARKER);
    }
    
//    // Configuring the views and colors.
//    UIView *checkView = [self viewWithImageName:@"icon_win"];
//    UIColor *greenColor = UIColorFromRGB(GREENDARKER);
//    
//    UIView *crossView = [self viewWithImageName:@"icon_paid"];
//    UIColor *redColor = UIColorFromRGB(RED);
//    
//    // Setting the default inactive state color to the tableView background color.
//    [cell setDefaultColor:[UIColor lightGrayColor]];
    
    cell.textLabel.font = [UIFont fontWithName:@"Asap-Regular" size:16];

    if (coffeeScore.coffee_count.intValue == 0) {
        cell.textLabel.text = user.name.uppercaseString;
    } else if (coffeeScore.coffee_count.intValue > 0) {
        NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ OWES YOU", user.name.uppercaseString]];
        [attrText addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(GREENDARKER) range:NSMakeRange(user.name.length, 9)];
        cell.textLabel.attributedText = attrText;
    } else {
        NSMutableAttributedString *attrText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ IS OWED", user.name.uppercaseString]];
        [attrText addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(GREENDARKER) range:NSMakeRange(user.name.length, 8)];
        cell.textLabel.attributedText = attrText;
//        [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState1 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//            [self changeCoffeeScore:coffeeScore withValue:-1];
//        }];
//        [cell setSwipeGestureWithView:crossView color:redColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState2 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//            [self changeCoffeeScore:coffeeScore withValue:-1];
//        }];
    }
    
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", abs(coffeeScore.coffee_count.intValue)];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Asap-Regular" size:16];
    cell.detailTextLabel.textColor = [UIColor whiteColor];
    
    // Adding gestures per state basis.
//    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState3 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//        [self changeCoffeeScore:coffeeScore withValue:1];
//    }];
//
//    [cell setSwipeGestureWithView:checkView color:greenColor mode:MCSwipeTableViewCellModeSwitch state:MCSwipeTableViewCellState4 completionBlock:^(MCSwipeTableViewCell *cell, MCSwipeTableViewCellState state, MCSwipeTableViewCellMode mode) {
//        [self changeCoffeeScore:coffeeScore withValue:1];
//    }];
    
    return cell;
}

- (NSArray *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath
{
    User *user = [[User MR_findAllSortedBy:@"name" ascending:YES withPredicate:[NSPredicate predicateWithFormat:@"id != %@", self.user.id]] objectAtIndex:indexPath.row];
    CoffeeScore *coffeeScore = [CoffeeScore MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"paid_by_id = %@ AND paid_to_id = %@", user.id, self.user.id]]];
    
    
    UITableViewRowAction *boughtCoffee = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"Bought Coffee" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self changeCoffeeScore:coffeeScore withValue:-1];
    }];
    boughtCoffee.backgroundColor = UIColorFromRGB(RED);
    
    UITableViewRowAction *won = [UITableViewRowAction rowActionWithStyle:UITableViewRowActionStyleDefault title:@"I Won" handler:^(UITableViewRowAction *action, NSIndexPath *indexPath) {
        [self changeCoffeeScore:coffeeScore withValue:1];
    }];
    won.backgroundColor = UIColorFromRGB(GREENDARKER);
    
    if (coffeeScore.coffee_count.intValue==0) {
        return @[won];
    } else if(coffeeScore.coffee_count.intValue > 0) {
        return @[won];
    } else {
        return @[won, boughtCoffee];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{

}


- (void)changeCoffeeScore:(CoffeeScore *)coffeeScore withValue:(int)valueToChange
{

//    User *userImage = [User MR_findFirstByAttribute:@"id" withValue:coffeeScore.paid_by_id];
//    [self.imageView setImage:[UIImage imageNamed:userImage.name]];
//
//    POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerSize];
//    animation.springBounciness = 6;
//    animation.springSpeed = 9;
//    animation.toValue = [NSValue valueWithCGSize:CGSizeMake(320, 480)];
//    [self.imageView pop_addAnimation:animation forKey:@"size"];
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//        POPSpringAnimation *animation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerSize];
//        animation.springBounciness = 6;
//        animation.springSpeed = 9;
//        animation.toValue = [NSValue valueWithCGSize:CGSizeMake(0, 0)];
//        [self.imageView pop_addAnimation:animation forKey:@"size"];
//    });
    
    coffeeScore.coffee_count = [NSNumber numberWithInt:(coffeeScore.coffee_count.intValue+1)];
    [self.tableView reloadData];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSDictionary *parameters;
    if (valueToChange > 0) {
        parameters = @{ @"coffee_score[paid_by_id]":coffeeScore.paid_by_id, @"coffee_score[paid_to_id]":coffeeScore.paid_to_id, @"coffee_score[delta]": [NSString stringWithFormat:@"%d", valueToChange] };
    } else {
        parameters = @{ @"coffee_score[paid_by_id]":coffeeScore.paid_to_id, @"coffee_score[paid_to_id]":coffeeScore.paid_by_id, @"coffee_score[delta]": [NSString stringWithFormat:@"%d", valueToChange] };
    }
    
    [manager POST:@"http://rounded-pong.herokuapp.com/coffee_scores.json" parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        self.lastTransactionID = (NSNumber *)[responseObject valueForKey:@"id"];
        self.lastTransactionCoffee = coffeeScore;
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

#pragma mark Shake to undo
- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"Let me guess: You messed up cause you were carelessly poking around and now you're gonna blame the developer." delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Undo", nil];
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==1) {
        if(self.lastTransactionCoffee) {
            self.lastTransactionCoffee.coffee_count = [NSNumber numberWithInt:(self.lastTransactionCoffee.coffee_count.intValue-1)];
            [self.tableView reloadData];
            AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
            [manager DELETE:[NSString stringWithFormat:@"http://rounded-pong.herokuapp.com/coffee_scores/%@.json", self.lastTransactionID] parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                [self.tableView reloadData];
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                [SVProgressHUD showErrorWithStatus:@"Couldn't undo the action via the server. Contact support: 1-800-POO-POOP"];
            }];
        } else {
            [SVProgressHUD showErrorWithStatus:@"You can't undo!"];
        }
    }
}

#pragma mark Getters

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(160, 240, 0, 0)];
        _imageView.backgroundColor = [UIColor blackColor];
    }
    return _imageView;
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
