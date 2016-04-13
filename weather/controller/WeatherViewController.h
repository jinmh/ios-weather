//
//  WeatherViewController.h
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WeatherViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>{
    UITableView *areaTableView;
    UIButton *backButton;

}

@property(nonatomic,retain) UITableView *areaTableView;
@property(nonatomic,retain) UIButton *backButton;



@end
