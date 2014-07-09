//
//  CoffeeScore.h
//  Pong
//
//  Created by bw on 7/7/14.
//  Copyright (c) 2014 bw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface CoffeeScore : NSManagedObject

@property (nonatomic, retain) NSNumber * coffee_count;
@property (nonatomic, retain) NSNumber * paid_by_id;
@property (nonatomic, retain) NSNumber * paid_to_id;
@property (nonatomic, retain) NSNumber * delta;

@end
