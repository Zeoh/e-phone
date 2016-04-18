//
//  CallViewController.m
//  ephone-z
//
//  Created by Jian Liao on 16/4/14.
//  Copyright © 2016年 fungotech. All rights reserved.
//

#import "CallViewController.h"

@implementation CallViewController {
    UILabel *statusLabel;
    UILabel *callingNumLabel;
    
    NSTimer *updateTimer;
    
    int hours, minutes, seconds, timeHelper;
    
    DisconnectReason disconnectReason;
    
    UIButton *muteBtn;
    UIButton *holdBtn;
    UIButton *videoBtn;
    UIButton *speakerBtn;
    UIButton *hangupBtn;
    
    float volume, micVol;
    BOOL isMute, isHold, isVideo, isSpeaker;
}

@synthesize callingNumber = _callingNumber;
@synthesize call = _call;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initData];
    [self initViews];
}

- (void)initData {
    seconds = -1;
    hours = minutes = 0;
    timeHelper = 1;
    isMute = isHold = isVideo = isSpeaker = NO;
    volume = _call.volume;
    micVol = _call.micVolume;
    updateTimer = nil;
    disconnectReason = INVALID_NUMBER;
    [_call addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:@"callStatusContext"];
}

- (void)initViews {
    [self.view setBackgroundColor:[UIColor blackColor]];
    
    UILabel *test = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.screenHeight*0.15, self.screenHeight*0.15)];
    test.center = CGPointMake(self.screenWidth*0.25, self.screenHeight*0.2);
    [test setBackgroundColor:[UIColor grayColor]]; //////////
    [self.view addSubview:test];
    
    callingNumLabel = [[UILabel alloc] initWithFrame:CGRectMake(test.frame.origin.x + test.frame.size.width + self.screenWidth*0.05,
                                                           test.frame.origin.y,
                                                           self.screenWidth/2,
                                                           self.screenHeight*0.1 - 1)];
    //[callingNumLabel setBackgroundColor:[UIColor grayColor]]; //////////
    callingNumLabel.text = _callingNumber;
    callingNumLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:callingNumLabel];
    
    statusLabel = [[UILabel alloc] initWithFrame:callingNumLabel.frame];
    statusLabel.center = CGPointMake(statusLabel.center.x,
                                         statusLabel.center.y + test.frame.size.height - statusLabel.frame.size.height);
    //[statusLabel setBackgroundColor:[UIColor grayColor]]; //////////
    statusLabel.text = @"Connecting...";
    statusLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:statusLabel];
    
    float btnSide = self.screenWidth*0.25-1;
    
    muteBtn = [[UIButton alloc] initWithFrame:CGRectMake(test.frame.origin.x,
                                                         test.frame.origin.y + test.frame.size.height + self.screenHeight*0.06,
                                                         btnSide*1.5, btnSide)];
    [muteBtn.layer setCornerRadius:0];
    [muteBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    [muteBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
    [muteBtn.layer setBorderWidth:1];
    [muteBtn setTitle:@"Mute" forState:UIControlStateNormal];
    [muteBtn addTarget:self action:@selector(muteBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:muteBtn];
    
    holdBtn = [[UIButton alloc] initWithFrame:muteBtn.frame];
    holdBtn.center = CGPointMake(holdBtn.center.x + btnSide*1.5 + 1, holdBtn.center.y);
    [holdBtn.layer setCornerRadius:0];
    [holdBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    [holdBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
    [holdBtn.layer setBorderWidth:1];
    [holdBtn setTitle:@"Hold" forState:UIControlStateNormal];
    [holdBtn addTarget:self action:@selector(holdBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:holdBtn];
    
    videoBtn = [[UIButton alloc] initWithFrame:muteBtn.frame];
    videoBtn.center = CGPointMake(videoBtn.center.x, videoBtn.center.y + btnSide + 1);
    [videoBtn.layer setCornerRadius:0];
    [videoBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    [videoBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
    [videoBtn.layer setBorderWidth:1];
    [videoBtn setTitle:@"Video" forState:UIControlStateNormal];
    [videoBtn addTarget:self action:@selector(videoBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:videoBtn];
    
    speakerBtn = [[UIButton alloc] initWithFrame:videoBtn.frame];
    speakerBtn.center = CGPointMake(speakerBtn.center.x + btnSide*1.5 + 1, speakerBtn.center.y);
    [speakerBtn.layer setCornerRadius:0];
    [speakerBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    [speakerBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
    [speakerBtn.layer setBorderWidth:1];
    [speakerBtn setTitle:@"Speaker" forState:UIControlStateNormal];
    [speakerBtn addTarget:self action:@selector(speakerBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:speakerBtn];
    
    hangupBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, btnSide*3, btnSide)];
    hangupBtn.center = CGPointMake(self.screenWidth/2 - 3, videoBtn.center.y + btnSide + self.screenHeight*0.06);
    [hangupBtn.layer setCornerRadius:0];
    [hangupBtn.layer setBackgroundColor:[UIColor redColor].CGColor];
    [hangupBtn.layer setBorderColor:[UIColor whiteColor].CGColor];
    [hangupBtn.layer setBorderWidth:1];
    [hangupBtn setTitle:@"Hang Up" forState:UIControlStateNormal];
    [hangupBtn addTarget:self action:@selector(hangupBtnClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:hangupBtn];
    
    [self setEnabledOfAllButtons:NO];
    [hangupBtn.layer setBackgroundColor:[UIColor redColor].CGColor];
    [hangupBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

#pragma mark - Button event handler
- (void)muteBtnClicked {
    if(isMute) {
        // Unmute
        if([_call setVolume:volume]) {
            isMute = NO;
            [muteBtn setTitle:@"Unmute" forState:UIControlStateNormal];
            [muteBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
        }
    } else {
        // Mute
        if([_call setVolume:0]) {
            isMute = YES;
            [muteBtn setTitle:@"Mute" forState:UIControlStateNormal];
            [muteBtn.layer setBackgroundColor:[UIColor grayColor].CGColor];
        }
    }
}

- (void)holdBtnClicked {
    if(isHold) {
        // Unhold
        if([_call setVolume:volume] && [_call setMicVolume:micVol]) {
            isHold = NO;
            timeHelper = 1;
            [holdBtn setTitle:@"Hold" forState:UIControlStateNormal];
            [holdBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
            //[holdBtn.layer setBorderWidth:1];
        }
    } else {
        // Hold
        if([_call setVolume:0] && [_call setMicVolume:0]) {
            isHold = YES;
            timeHelper = 0;
            [holdBtn setTitle:@"Unhold" forState:UIControlStateNormal];
            [holdBtn.layer setBackgroundColor:[UIColor grayColor].CGColor];
        }
    }
}

- (void)videoBtnClicked {
    if(isVideo) {
        // Close Video
        isVideo = NO;
        [videoBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    } else {
        // Open Video
        isVideo = YES;
        [videoBtn.layer setBackgroundColor:[UIColor grayColor].CGColor];
    }
}

- (void)speakerBtnClicked {
    if(isSpeaker) {
        // Use headphone
        isSpeaker = NO;
        [speakerBtn setTitle:@"Speaker" forState:UIControlStateNormal];
        [speakerBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];

    } else {
        // Use Speaker
        isSpeaker = YES;
        [speakerBtn setTitle:@"Headphone" forState:UIControlStateNormal];
        [speakerBtn.layer setBackgroundColor:[UIColor grayColor].CGColor];
    }
}

- (void)hangupBtnClicked {
    disconnectReason = HANGUP;
    [_call end];
}

- (void)setEnabledOfAllButtons:(BOOL)enabled {
    [muteBtn setEnabled:enabled];
    [holdBtn setEnabled:enabled];
    [videoBtn setEnabled:enabled];
    [speakerBtn setEnabled:enabled];
    [hangupBtn setEnabled:enabled];
    if(enabled) {
        [muteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [holdBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [videoBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [speakerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [hangupBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [hangupBtn.layer setBackgroundColor:[UIColor redColor].CGColor];
    } else {
        [muteBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [holdBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [videoBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [speakerBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [hangupBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
        [hangupBtn.layer setBackgroundColor:[UIColor blackColor].CGColor];
    }
}

#pragma mark - Update timerLabel
- (void)timerDone{
    seconds += timeHelper;
    if(seconds >= 60) {
        seconds = 0;
        minutes++;
        if (minutes>=60) {
            minutes = 0;
            hours++;
        }
    }
    NSLog(@"Duration: %02d:%02d:%02d", hours, minutes, seconds);
    statusLabel.text = [NSString stringWithFormat:@"Duration: %02d:%02d:%02d", hours, minutes, seconds];
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
    switch (_call.status) {
        case GSCallStatusConnected: {
            NSLog(@"GSCallStatusConnected");
            [self setEnabledOfAllButtons:YES];
            disconnectReason = HANGUP;
            if(!updateTimer)
                updateTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerDone) userInfo:nil repeats:YES];
            //            [UIView animateWithDuration:0.3 delay:0.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
            //                UIImage *dial_unselected = [UIImage imageNamed:@"icon_phone_on.png"];
            //                [phonePadView.dialBtn setImage:dial_unselected forState:UIControlStateNormal];
            //            } completion:^(BOOL finish){
            //            }];
        } break;
        case GSCallStatusReady: {
            NSLog(@"GSCallStatusReady");
        } break;
        case GSCallStatusConnecting: {
            NSLog(@"GSCallStatusConnecting");
            disconnectReason = REJECTED;
        } break;
        case GSCallStatusCalling: {
            NSLog(@"GSCallStatusCalling");
        } break;
        case GSCallStatusDisconnected: {
            NSLog(@"GSCallStatusDisconnected");
            [self setEnabledOfAllButtons:NO];
            [_call removeObserver:self forKeyPath:@"status" context:@"callStatusContext"];
            //            [UIView animateWithDuration:0.3 delay:0.35 options:UIViewAnimationOptionCurveEaseOut animations:^{
            //                UIImage *dial_unselected = [UIImage imageNamed:@"icon_phone.png"];
            //                [phonePadView.dialBtn setImage:dial_unselected forState:UIControlStateNormal];
            //                phonePadView.dialBtn.transform = CGAffineTransformMakeRotation(M_PI*2);
            //            } completion:^(BOOL finish){
            //                isCalling = NO;
            //                isConnecting = NO;
            //            }];
            [updateTimer invalidate];
            switch (disconnectReason) {
                case INVALID_NUMBER:
                    statusLabel.text = @"Invalid Number";
                    break;
                case REJECTED:
                    statusLabel.text = @"Call Rejected";
                    break;
                case HANGUP:
                    statusLabel.text = @"Disconncted";
                    break;
            }
            [self performSelector:@selector(dissMissSelf) withObject:nil afterDelay:2.5];
        } break;
            
    }
}

- (void)dissMissSelf{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

@end