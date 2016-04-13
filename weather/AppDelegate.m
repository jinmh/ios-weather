//
//  AppDelegate.m
//  weather
//
//  Created by jinmh on 16/3/11.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import "AppDelegate.h"
#import "ProvinceViewController.h"


@interface AppDelegate ()

@end

@implementation AppDelegate

static AppDelegate * _appDelegate;


+(AppDelegate *) appDeleaget{
    return _appDelegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    
    ProvinceViewController *mainViewController = [[ProvinceViewController alloc] init];
    UINavigationController *windowRootViewController = [[UINavigationController alloc] initWithRootViewController:mainViewController];
    
    self.window.rootViewController = windowRootViewController;

    _appDelegate=self;
    
    
   
    
    return YES;
}






- (void)dumpView:(UIView *)aView atIndent:(int)indent into:(NSMutableString *)outstring

{
    for (int i = 0; i < indent; i++){
        [outstring appendString:@"--"];
    }
    
    [outstring appendFormat:@"[%2d] %@\n", indent, [[aView class] description]];
    
    for (UIView *view in [aView subviews]){
        
        [self dumpView:view atIndent:indent + 1 into:outstring];
    }
    
}

// Start the tree recursion at level 0 with the root view

- (NSString *) displayViews: (UIView *) aView

{
    
    NSMutableString *outstring = [[NSMutableString alloc] init];
    
    [self dumpView: self.window atIndent:0 into:outstring];
    
    return outstring;
    
}

// Show the tree

- (void) printViewLevelTree

{
    
    //  CFShow([self displayViews: self.window]);
    
    NSLog(@"The view tree:\n%@", [self displayViews:self.window]);
    
}



@end
