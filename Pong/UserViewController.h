//
//  UserViewController.h
//  Pong
//
//  Created by bw on 6/18/14.
//  Copyright (c) 2014 bw. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import <MCSwipeTableViewCell.h>

@interface UserViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate>

@property (strong, nonatomic) User *user;

@end
