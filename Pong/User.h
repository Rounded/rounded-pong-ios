//
//  User.h
//  Pong
//
//  Created by bw on 6/18/14.
//  Copyright (c) 2014 bw. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * id;

@end
