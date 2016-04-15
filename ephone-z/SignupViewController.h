//
//  SignupViewController.h
//  ephone-z
//
//  Created by Jian Liao on 16/3/4.
//  Copyright © 2016年 fungotech. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseViewController.h"

@interface SignupViewController : BaseViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTF;

- (IBAction)save:(id)sender;
- (IBAction)cancel:(id)sender;

@end
