//
//  WeatherViewController.m
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import "ProvinceViewController.h"
#import "WeatherDB.h"
#import "CityViewController.h"
#import "AppDelegate.h"


@implementation ProvinceViewController{
    NSMutableArray *provinces;
    Province *selectedProvince;
    bool isVertical;
}

@synthesize areaTableView;
@synthesize activityIndicatorView;





- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"全国";
    }
    return self;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [provinces count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    NSUInteger row = [indexPath row];
    Province *province = (Province*)provinces[row];
    cell.textLabel.text = province.provinceName;
    
    return cell;
}


//选中cell触发
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"cell Touched Begin:%@",[[NSDate alloc]init]);
    
    NSUInteger row = [indexPath row];
    
    selectedProvince = (Province*)provinces[row];
    
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:selectedProvince.id forKey:@"provinceId"];
    [userDefaults setObject:selectedProvince.provinceCode forKey:@"provinceCode"];
    [userDefaults setObject:selectedProvince.provinceName forKey:@"provinceName"];
    
    //[[AppDelegate appDeleaget] printViewLevelTree];
    
    CityViewController *cityController = [[CityViewController alloc] init];
    [self.navigationController pushViewController:cityController animated:true];
    
    NSLog(@"cell Touched End:%@",[[NSDate alloc]init]);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}




- (void) loadView{
    [super loadView];
    
    CGRect rect;
    
    if(screenWidth < self.navigationController.navigationBar.frame.size.width){
        rect = CGRectMake(0, 0, screenWidth, screenHeight);
        isVertical = false;
    }else{
        rect = CGRectMake(0, 0, screenHeight, screenWidth);
        isVertical = true;
    }
    
    areaTableView = [[UITableView alloc] initWithFrame:rect];

    
    
    [areaTableView setDataSource:self];
    [areaTableView setDelegate:self];

    [self loadProvices];
}




- (void) loadProvices{
    provinces = [[WeatherDB defaultWeatherDB] getProvinces];
    
    NSLog(@"省份记录数：%d",[provinces count]);
    [self.view addSubview:areaTableView];
    
    if([provinces count]==0){
        [self queryProvinceFromServerGCDAsync];
    }
}



-(void) queryProvinceFromServerAsync{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city.xml"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSOperationQueue *que = [[NSOperationQueue alloc] init];
        [NSURLConnection sendAsynchronousRequest:request queue:que completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            self.activityIndicatorView.center = self.view.center;
            [self.view addSubview:self.activityIndicatorView];
            [self.activityIndicatorView startAnimating];
            
            if (connectionError) {
                NSLog(@"Request Error is: %@,  on thread %@!!",connectionError,[NSThread currentThread]);
            }else{
                NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];                
                if(content!=nil && ![content isEqualToString:@""]){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSArray *provinceArray = [content componentsSeparatedByString:@","];
                        
                        for(NSString *pValue in provinceArray){
                            NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                            Province *province = [[Province alloc] init];
                            province.provinceCode=pArray[0];
                            province.provinceName=pArray[1];
                            
                            [[WeatherDB defaultWeatherDB] saveProvince:province];
                        }
                        
                        provinces = [[WeatherDB defaultWeatherDB] getProvinces];
                        [self.areaTableView reloadData];
                        NSLog(@"省份记录数：%d",[provinces count]);
                    });
                }
            }
            [self.activityIndicatorView stopAnimating];
        }];
    });
}
         


-(void) queryProvinceFromServerSync{
    [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
    
    NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city.xml"]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLResponse *response = nil;
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
    
    if (error) {
        NSLog(@"Request Error is: %@,  on thread %@!",error,[NSThread currentThread]);
    }else{
        NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
        if(content!=nil && ![content isEqualToString:@""]){
            NSArray *provinceArray = [content componentsSeparatedByString:@","];
            
            for(NSString *pValue in provinceArray){
                NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                Province *province = [[Province alloc] init];
                province.provinceCode=pArray[0];
                province.provinceName=pArray[1];
                
                [[WeatherDB defaultWeatherDB] saveProvince:province];
            }
            
            provinces = [[WeatherDB defaultWeatherDB] getProvinces];
            [self.areaTableView reloadData];
            NSLog(@"省份记录数：%d",[provinces count]);
        }
    }
}




-(void) queryProvinceFromServerGCDAsync{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.center = self.view.center;
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
        
        NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city.xml"]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLResponse *response = nil;
        NSError *error;
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
        
        if (error) {
            NSLog(@"Request Error is: %@,  on thread %@!",error,[NSThread currentThread]);
            [self.activityIndicatorView stopAnimating];
        }else{
            dispatch_async(dispatch_get_main_queue(),^{
                NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                if(content!=nil && ![content isEqualToString:@""]){
                    NSArray *provinceArray = [content componentsSeparatedByString:@","];
                    
                    for(NSString *pValue in provinceArray){
                        NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                        Province *province = [[Province alloc] init];
                        province.provinceCode=pArray[0];
                        province.provinceName=pArray[1];
                        
                        [[WeatherDB defaultWeatherDB] saveProvince:province];
                    }
                    
                    provinces = [[WeatherDB defaultWeatherDB] getProvinces];
                    [self.areaTableView reloadData];
                    NSLog(@"省份记录数：%d",[provinces count]);
                    [self.activityIndicatorView stopAnimating];
                }
            });
        }
        
    });
}




-(void) orientationChanged{
    UIDeviceOrientation orientaiton = [[UIDevice currentDevice] orientation];
    
    if(screenWidth < self.navigationController.navigationBar.frame.size.width){
        isVertical = false;
    }else{
        isVertical = true;
    }
    
    switch (orientaiton) {
        case UIDeviceOrientationPortrait:
            areaTableView.frame = CGRectMake(0, 0, screenWidth,screenHeight);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            areaTableView.frame = CGRectMake(0, 0, screenWidth,screenHeight);
            break;
        case UIDeviceOrientationLandscapeLeft:
            areaTableView.frame = CGRectMake(0, 0, screenHeight,screenWidth);
            break;
        case UIDeviceOrientationLandscapeRight:
            areaTableView.frame = CGRectMake(0, 0, screenHeight,screenWidth);
            break;
        default:
            if (isVertical){
                areaTableView.frame = CGRectMake(0, 0, screenWidth,screenHeight);
            }else{
                areaTableView.frame = CGRectMake(0, 0, screenHeight,screenWidth);
            }
            break;
    }
}

//在进行旋转视图前的会执行的方法（用于调整旋转视图之用）
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self orientationChanged];
}



-(void) viewWillAppear:(BOOL)animated{
    //当收到视图在视窗将可见时的通知会呼叫的方法
    [self orientationChanged];    
    
}

-(void) viewWillDisappear:(BOOL)animated{
    //当收到视图将去除、被覆盖或隐藏于视窗时的通知会呼叫的方法
    
}

-(void) viewWillLayoutSubviews{
    [self orientationChanged];
    [self.areaTableView reloadData];
}


-(void) viewDidAppear:(BOOL)animated{
    //当收到视图在视窗已可见时的通知会呼叫的方法
}


-(void) viewDidDisappear:(BOOL)animated{
    //当收到视图已去除、被覆盖或隐藏于视窗时的通知会呼叫的方法
}


-(void) viewDidLayoutSubviews{
    
}




@end
