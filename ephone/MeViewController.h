//
//  MeViewController.h
//  ephone-z
//
//  Created by Jian Liao on 16/3/8.
//  Copyright © 2016年 fungotech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Constants.h"
#import "CustomTableViewCell.h"

@interface MeViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, assign) const NSString *myAccount;

@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *listMe;

@end