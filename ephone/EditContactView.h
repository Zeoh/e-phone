//
//  EditContactView.h
//  ephone
//
//  Created by Jian Liao on 16/5/13.
//  Copyright © 2016年 zeoh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactModel.h"
#import "Constants.h"
#import "DBUtil.h"

@interface EditContactView : UIView

@property (strong, nonatomic) UITextField *nameInput;
@property (strong, nonatomic) UITextField *accountInput;
@property (strong, nonatomic) UITextField *addressInput;

- (id)initWithContactModel:(ContactModel*) cm;

@end
