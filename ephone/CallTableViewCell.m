//
//  CallTableViewCell.m
//  "
//
//  Created by Jian Liao on 16/4/22.
//  Copyright © 2016年 zeoh. All rights reserved.
//

#import "CallTableViewCell.h"

@implementation CallTableViewCell {
    UILabel *nameLabel;
    UILabel *phoneNumberLabel;
    UILabel *callTimeLabel;
    UILabel *addressLabel;
    UIImageView *callTypeImageView;
}

@synthesize callRecord = _callRecord;
@synthesize expandImageView = _expandImageView;

-(id)initWithCallRecordModel:(CallRecordModel*) crm {
    if(self=[super init]) {
        _callRecord = crm;
        [self initViews];
    }
    return self;
}

-(void)initViews {
    const float CELL_WIDTH = self.frame.size.width;
    const float CELL_HEIGHT = self.frame.size.height;
    const float ORIGIN_X = self.frame.origin.x + CELL_WIDTH*0.03;
    const float ORIGIN_Y = self.frame.origin.y + CELL_WIDTH*0.03;
    
    NSString *callTypeImagePath;
    switch (_callRecord.callType) {
        case OUTCOMING: callTypeImagePath = @"icon_call_out.png"; break;
        case INCOMING: callTypeImagePath = @"icon_call_in.png"; break;
        case FAILED: callTypeImagePath = @"icon_call_off.png"; break;
        case MISSED: break;
    }
    
    UIImage *callTypeImage = [UIImage imageNamed:callTypeImagePath];
    callTypeImage = [self imageCompressWithSimple:callTypeImage scale:0.8];
    
    callTypeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(ORIGIN_X, ORIGIN_Y + CELL_HEIGHT*0.3, callTypeImage.size.width, callTypeImage.size.height)];
    [callTypeImageView setImage: callTypeImage];
    [self addSubview:callTypeImageView];
    
    nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(ORIGIN_X + CELL_WIDTH*0.1, ORIGIN_Y, CELL_WIDTH*0.35, CELL_HEIGHT/2)];
    nameLabel.text = ([_callRecord.name isEqualToString:@""]) ? @"<Unknown>" : _callRecord.name;
    [self addSubview:nameLabel];
    
    phoneNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(ORIGIN_X + CELL_WIDTH*0.1, ORIGIN_Y + CELL_HEIGHT*0.5, CELL_WIDTH*0.35, CELL_HEIGHT/2)];
    phoneNumberLabel.text = _callRecord.account;
    phoneNumberLabel.textColor = [UIColor grayColor];
    phoneNumberLabel.font = [UIFont fontWithName:@"Arial" size:14];
    [self addSubview:phoneNumberLabel];
    
    callTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(ORIGIN_X + CELL_WIDTH*0.4, ORIGIN_Y, CELL_WIDTH*0.45, CELL_HEIGHT/2)];
    callTimeLabel.text = _callRecord.callTime;
    callTimeLabel.textColor = [UIColor darkGrayColor];
    callTimeLabel.font = [UIFont fontWithName:@"Arial" size:14];
    callTimeLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:callTimeLabel];
    
    addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(ORIGIN_X + CELL_WIDTH*0.4, ORIGIN_Y + CELL_HEIGHT*0.5, CELL_WIDTH*0.45, CELL_HEIGHT/2)];
    if([_callRecord.attribution isEqualToString:@""]) addressLabel.text = _callRecord.domain;
    else addressLabel.text = _callRecord.attribution;
    addressLabel.textColor = [UIColor darkGrayColor];
    addressLabel.font = [UIFont fontWithName:@"Arial" size:14];
    addressLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:addressLabel];
    
    UIImage *expandImage = [UIImage imageNamed:@"icon_down.png"];
    expandImage = [self imageCompressWithSimple:expandImage scale:0.8];
    
    _expandImageView = [[UIImageView alloc] initWithFrame:CGRectMake(ORIGIN_X + CELL_WIDTH*0.87, ORIGIN_Y + CELL_HEIGHT*0.3, expandImage.size.width, expandImage.size.height)];
    [_expandImageView setImage: expandImage];
    [self addSubview:_expandImageView];
}

- (UIImage*)imageCompressWithSimple:(UIImage*)image scale:(float)scale {
    CGSize size = image.size;
    CGFloat width = size.width;
    CGFloat height = size.height;
    CGFloat scaledWidth = width * scale;
    CGFloat scaledHeight = height * scale;
    UIGraphicsBeginImageContext(size); // this will crop
    [image drawInRect:CGRectMake(0,0,scaledWidth,scaledHeight)];
    UIImage* newImage= UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end
