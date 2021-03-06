//
//  MainTabBarViewController.m
//  ephone-z
//
//  Created by Jian Liao on 16/3/7.
//  Copyright © 2016年 fungotech. All rights reserved.
//

#import "MainTabBarViewController.h"

@implementation MainTabBarViewController {
    DBUtil *dbUtil;
    AudioUtil *audioUtil;
    
    GSCall *call;
    CallRecordModel *crm;
    UIAlertView *incomingAlert;
    
    NSString *callingNumber;
    
    BOOL isReceivingCall;
    BOOL isIncomingCallRinging;
}

@synthesize agent = _agent;
@synthesize account = _account;
@synthesize dialVC = _dialVC;
@synthesize contactsVC = _contactsVC;
@synthesize meVC = _meVC;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initViews];
}

- (void)initData {
    dbUtil = [DBUtil sharedManager];
    audioUtil = [AudioUtil sharedManager];
    
    _dialVC  = [DialViewController new];
    _contactsVC  = [ContactsViewController new];
    _meVC  = [MeViewController new];
    
    _dialVC.delegate = self;
    _contactsVC.delegate = self;
    _dialVC.myAccount = self.username;
    _contactsVC.myAccount = self.username;
    _meVC.myAccount = self.username;
    
    _agent = [GSUserAgent sharedAgent];
    _account = _agent.account;
    _account.delegate = self;
    
    callingNumber = @"";
    isReceivingCall = YES;
    isIncomingCallRinging = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(incomingCallDisconnected)
                                                 name:GSSIPCallStateDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(logout)
                                                 name:@"logout"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:dbUtil
                                             selector:@selector(updatePhoneRecords)
                                                 name:@"contactInsertingDone"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:dbUtil
                                             selector:@selector(updatePhoneRecords)
                                                 name:@"contactDeletionSuccess"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:dbUtil
                                             selector:@selector(updatePhoneRecords)
                                                 name:@"contactEditSuccess"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactInsertingDone)
                                                 name:@"contactInsertingDone"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactInsertingFailed)
                                                 name:@"contactInsertingFailed"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactEmptyName)
                                                 name:@"contactEmptyName"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactEmptyAccount)
                                                 name:@"contactEmptyAccount"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(recordDeletionSuccess)
                                                 name:@"recordDeletionSuccess"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactDeletionSuccess)
                                                 name:@"contactDeletionSuccess"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactEditSuccess)
                                                 name:@"contactEditSuccess"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contactEditFailed)
                                                 name:@"contactEditFailed"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nothingIsChanged)
                                                 name:@"nothingIsChanged"
                                               object:nil];
}

- (void)initViews {
    _dialVC.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemHistory tag:1];
    _contactsVC.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemContacts tag:2];
    _meVC.tabBarItem = [[UITabBarItem alloc]initWithTabBarSystemItem:UITabBarSystemItemFavorites tag:3];
    
    self.viewControllers = @[_dialVC, _contactsVC, _meVC];
    [self setSelectedIndex:0];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    self.logoutIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.logoutIndicatorView.center = self.view.center;
    [self.view addSubview: self.logoutIndicatorView];
    
//    UIButton *testbtn1 = [[UIButton alloc] initWithFrame:CGRectMake(10, 50, 100, 100)];
//    [testbtn1 setBackgroundColor:[UIColor purpleColor]];
//    [testbtn1 addTarget:self action:@selector(testBtn1Clicked) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:testbtn1];
//    
//    UIButton *testbtn2 = [[UIButton alloc] initWithFrame:CGRectMake(200, 50, 100, 100)];
//    [testbtn2 setBackgroundColor:[UIColor yellowColor]];
//    [testbtn2 addTarget:self action:@selector(testBtn2Clicked) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:testbtn2];
}

//- (void)testBtn1Clicked {
//    NSLog(@"Test Button 1 Clicked!!!");
//    [audioUtil playSoundConstantly];
//    [audioUtil playVibrateConstantly];
//}
//
//- (void)testBtn2Clicked {
//    NSLog(@"Test Button 1 Clicked!!!");
//    [audioUtil stop];
//}

#pragma mark - DialDelegate
- (void)makeSipCall:(NSString*) sipUri {
    call = [GSCall outgoingCallToUri:sipUri fromAccount:_account];
    [self makeCall:OUTCOMING];
}

#pragma mark - GSAccountDelegate
- (void)account:(GSAccount *)account didReceiveIncomingCall:(GSCall *)incomingCall {
    if(isReceivingCall) isReceivingCall = NO;
    else return;
    isIncomingCallRinging = YES;
    call = incomingCall;
    [audioUtil playSoundConstantly];
    [audioUtil playVibrateConstantly];
    
    crm = [CallRecordModel new];
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
    crm.callTime = [df stringFromDate:[NSDate date]];
    
    NSString *remoteUriAddress = [call getRemoteUri];
    NSArray *remoteArray = [remoteUriAddress componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<:@>"]];
    int shift = 0;
    if([remoteArray[0] isEqualToString:@""]) shift = 1;
    NSString *remoteAccount = remoteArray[1+shift];
    NSString *remoteDomain = remoteArray[2+shift];
    
    crm.account = remoteAccount;
    crm.domain = remoteDomain;
    crm.myAccount = (NSString *)self.username;
    
    incomingAlert = [[UIAlertView alloc] init];
    [incomingAlert setAlertViewStyle:UIAlertViewStyleDefault];
    [incomingAlert setDelegate:self];
    [incomingAlert setTitle:@"Incoming call."];
    [incomingAlert addButtonWithTitle:@"Decline"];
    [incomingAlert addButtonWithTitle:@"Answer"];
    [incomingAlert setCancelButtonIndex:0];
    [incomingAlert show];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex == [alertView cancelButtonIndex]) {
        [self userDidDenyCall];
    } else {
        [self userDidPickupCall];
    }
    isIncomingCallRinging = NO;
}

- (void)userDidPickupCall {
    [audioUtil stop];
    [self makeCall:INCOMING];
}

- (void)userDidDenyCall {
    [audioUtil stop];
    [self addMissedCallRecord];
    [call end];
    call = nil;
}

- (void)addMissedCallRecord {
    crm.name = @"";
    crm.attribution = @"";
    crm.duration = @"--:--:--";
    crm.callType = MISSED;
    crm.networkType = SIP;
    
    [dbUtil insertRecentContactsRecord:crm];
}

- (void)makeCall:(CallType) callType {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.dialVC.phonePadView.dialBtn.transform = CGAffineTransformMakeRotation(M_PI*3/4);
    } completion:^(BOOL finish){
        [call addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:@"callStatusContext"];
        [call begin];
        [self.dialVC.phonePadView.dialBtn setEnabled:NO];
        CallViewController *callVC = [CallViewController new];
        callVC.call = call;
        [call removeObserver:self forKeyPath:@"status" context:@"callStatusContext"];
        [self presentViewController:callVC animated:YES completion:^{
            [self.dialVC.phonePadView.dialBtn setEnabled:YES];
            self.dialVC.phonePadView.dialBtn.transform = CGAffineTransformMakeRotation(0);
            callVC.crm.callType = callType;
        }];
        isReceivingCall = YES;
    }];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqualToString:@"status"])
        [self callStatusDidChange];
}

- (void)callStatusDidChange {
    switch (call.status) {
        case GSCallStatusReady: {
            NSLog(@"Main: GSCallStatusReady");
        } break;
        case GSCallStatusConnecting: {
            NSLog(@"Main: GSCallStatusConnecting");
        } break;
        case GSCallStatusCalling: {
            NSLog(@"Main: GSCallStatusCalling");
        } break;
        case GSCallStatusConnected: {
            NSLog(@"Main: GSCallStatusConnected");
        } break;
        case GSCallStatusDisconnected: {
            NSLog(@"Main: GSCallStatusDisconnected");
        } break;
    }
}

- (void)logout {
    [self.logoutIndicatorView startAnimating];
    _agent = [GSUserAgent sharedAgent];
    [_agent.account disconnect];
    [_agent reset];
    [self.logoutIndicatorView stopAnimating];
    [self dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark - Notification Handler
- (void)incomingCallDisconnected {
    if(isIncomingCallRinging) {
        [incomingAlert dismissWithClickedButtonIndex:[incomingAlert cancelButtonIndex] animated:YES];
        isIncomingCallRinging = NO;
        isReceivingCall = YES;
    }
}

- (void)contactInsertingDone {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the custom view mode to show any view.
    hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
    UIImage *image = [[UIImage imageNamed:@"Checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    hud.customView = [[UIImageView alloc] initWithImage:image];
    // Looks a bit nicer if we make it square.
    hud.square = YES;
    // Optional label text.
    hud.labelText = @"Done";
    //hud.label.text = NSLocalizedString(@"Done", @"HUD done title");
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)contactInsertingFailed {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Replicated Contact!";
    // Move to bottm center.
    hud.yOffset = SCREEN_HEIGHT/4;
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)contactEmptyName {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Please input name!";
    // Move to bottm center.
    hud.yOffset = SCREEN_HEIGHT/4;
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)contactEmptyAccount {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Please input number!";
    // Move to bottm center.
    hud.yOffset = SCREEN_HEIGHT/4;
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)recordDeletionSuccess {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the custom view mode to show any view.
    hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
    UIImage *image = [[UIImage imageNamed:@"Checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    hud.customView = [[UIImageView alloc] initWithImage:image];
    // Looks a bit nicer if we make it square.
    hud.square = YES;
    // Optional label text.
    hud.labelText = @"Done";
    //hud.label.text = NSLocalizedString(@"Done", @"HUD done title");
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)contactDeletionSuccess {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the custom view mode to show any view.
    hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
    UIImage *image = [[UIImage imageNamed:@"Checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    hud.customView = [[UIImageView alloc] initWithImage:image];
    // Looks a bit nicer if we make it square.
    hud.square = YES;
    // Optional label text.
    hud.labelText = @"Done";
    //hud.label.text = NSLocalizedString(@"Done", @"HUD done title");
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)contactEditSuccess {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the custom view mode to show any view.
    hud.mode = MBProgressHUDModeCustomView;
    // Set an image view with a checkmark.
    UIImage *image = [[UIImage imageNamed:@"Checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    hud.customView = [[UIImageView alloc] initWithImage:image];
    // Looks a bit nicer if we make it square.
    hud.square = YES;
    // Optional label text.
    hud.labelText = @"Done";
    //hud.label.text = NSLocalizedString(@"Done", @"HUD done title");
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)contactEditFailed {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Replicated Contact!";
    // Move to bottm center.
    hud.yOffset = SCREEN_HEIGHT/4;
    
    [hud hide:YES afterDelay:1.5f];
}

- (void)nothingIsChanged {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    // Set the annular determinate mode to show task progress.
    hud.mode = MBProgressHUDModeText;
    hud.labelText = @"Nothing is changed.";
    // Move to bottm center.
    hud.yOffset = SCREEN_HEIGHT/4;
    
    [hud hide:YES afterDelay:1.5f];
}

@end
