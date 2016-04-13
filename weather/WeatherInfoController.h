//
//  WeatherInfoController.h
//  weather
//
//  Created by jinmh on 16/3/15.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WeatherInfoController : UIViewController{
    UILabel *publishTimeLabel;
    UILabel *nowTimeLabel;
    UILabel *weatherDescLabel;
    UILabel *lowTempLabel;
    UILabel *splitTempLabel;
    UILabel *highTempLabel;
    
    UIButton *backButton;
    UIActivityIndicatorView *activityIndicatorView;
}


@property(nonatomic,retain) UILabel *publishTimeLabel;

@property(nonatomic,retain) UILabel *nowTimeLabel;

@property(nonatomic,retain) UILabel *weatherDescLabel;

@property(nonatomic,retain) UILabel *lowTempLabel;

@property(nonatomic,retain) UILabel *splitTempLabel;

@property(nonatomic,retain) UILabel *highTempLabel;

@property(nonatomic,retain) UIButton *backButton;

@property(nonatomic,retain) UIActivityIndicatorView *activityIndicatorView;



@end
