//
//  CallTableViewCell.h
//  ephone
//
//  Created by Jian Liao on 16/4/22.
//  Copyright © 2016年 zeoh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallRecordModel.h"

@interface CallTableViewCell : UITableViewCell

@property (weak, nonatomic) CallRecordModel *callRecord;

-(id)initWithCallRecordModel:(CallRecordModel*)crm;
-(void)initViews;

@end
