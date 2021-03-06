//
//  Constants.h
//  ephone
//
//  Created by Jian Liao on 16/4/21.
//  Copyright © 2016年 zeoh. All rights reserved.
//

#ifndef Constants_h
#define Constants_h

#define SCREEN_ORIGIN_X [UIScreen mainScreen].bounds.origin.x
#define SCREEN_ORIGIN_Y [UIScreen mainScreen].bounds.origin.y
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)
#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)
#define SERVER_ADDRESS @"121.42.43.237"

typedef enum {
    OUTCOMING = 0,
    INCOMING,
    FAILED,
    MISSED,
} CallType;

typedef enum {
    SIP = 0,
    PSTN,
} NetworkType;

@protocol DialDelegate <NSObject>
@optional
- (void)makeSipCall:(NSString*) sipUrl;
@end

#endif /* Constants_h */
