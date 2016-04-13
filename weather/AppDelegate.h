//
//  AppDelegate.h
//  weather
//
//  Created by jinmh on 16/3/11.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

#define screenHeight ([[UIScreen mainScreen] bounds].size.height)
#define screenWidth ([[UIScreen mainScreen] bounds].size.width)

@interface AppDelegate : UIResponder <UIApplicationDelegate>


@property (strong, nonatomic) UIWindow *window;


+ (AppDelegate *) appDeleaget;

- (void) printViewLevelTree;

@end

