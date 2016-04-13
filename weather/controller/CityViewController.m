//
//  WeatherViewController.m
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import "CityViewController.h"
#import "WeatherDB.h"
#import "CountyViewController.h"
#import "AppDelegate.h"


@implementation CityViewController{
    NSMutableArray *cities;
    City *selectedCity;
    bool isVertical;
}

@synthesize areaTableView;
@synthesize activityIndicatorView;






- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
        return [cities count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    NSUInteger row = [indexPath row];
    City *city = (City*)cities[row];
    cell.textLabel.text = city.cityName;

    return cell;
}


//选中cell触发
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger row = [indexPath row];

    selectedCity = (City*)cities[row];

    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:selectedCity.id forKey:@"cityId"];
    [userDefaults setObject:selectedCity.cityCode forKey:@"cityCode"];
    [userDefaults setObject:selectedCity.cityName forKey:@"cityName"];
    
    CountyViewController *countyController = [[CountyViewController alloc] init];
    [self.navigationController pushViewController:countyController animated:true];

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
    
    [self loadCities];


}




- (void) loadCities{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSInteger provinceId = (NSInteger)[userDefaults objectForKey:@"provinceId"];
    NSString *provinceCode = (NSString *)[userDefaults objectForKey:@"provinceCode"];
    NSString *provinceName = (NSString *)[userDefaults objectForKey:@"provinceName"];

    self.title = provinceName;
    
    cities = [[WeatherDB defaultWeatherDB] getCities:provinceId];
    [self.view addSubview:areaTableView];
    NSLog(@"地市记录数：%d",[cities count]);
    if([cities count]==0){
       [self queryCitiesFromServerGCDASync:provinceCode parentId:provinceId];
    }else{

    }


}



-(void) queryCitiesFromServerAsync:(NSString *)provinceCode parentId:(int) provinceId {
    NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",provinceCode]];
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
            if(content!=nil){
                    NSArray *cityArray = [content componentsSeparatedByString:@","];
                    
                    for(NSString *pValue in cityArray){
                        NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                        City *city = [[City alloc] init];
                        city.cityCode=pArray[0];
                        city.cityName=pArray[1];
                        city.provinceId=provinceId;
                        
                        [[WeatherDB defaultWeatherDB] saveCity:city];
                    }
                    
                    cities = [[WeatherDB defaultWeatherDB] getCities:provinceId];
                    [self.areaTableView reloadData];
                    NSLog(@"地市记录数：%d",[cities count]);
            }
            NSLog(@" statusCode is %d on thread %@",[(NSHTTPURLResponse*)response  statusCode],[NSThread currentThread]);
        }
        [self.activityIndicatorView stopAnimating];
    }];
}



-(void) queryCitiesFromServerGCDASync:(NSString *)provinceCode parentId:(int) provinceId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
        
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.center = self.view.center;
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
        
        NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",provinceCode]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLResponse *response = nil;
        NSError *error;
        
        NSData *data =[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

        [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
        
        if (error) {
            NSLog(@"Request Error is: %@,  on thread %@!!",error,[NSThread currentThread]);
            [self.activityIndicatorView stopAnimating];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                if(content!=nil){
                    NSArray *cityArray = [content componentsSeparatedByString:@","];
                    
                    for(NSString *pValue in cityArray){
                        NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                        City *city = [[City alloc] init];
                        city.cityCode=pArray[0];
                        city.cityName=pArray[1];
                        city.provinceId=provinceId;
                        
                        [[WeatherDB defaultWeatherDB] saveCity:city];
                    }
                    
                    cities = [[WeatherDB defaultWeatherDB] getCities:provinceId];
                    [self.areaTableView reloadData];
                    NSLog(@"地市记录数：%d",[cities count]);
                    
                    [self.activityIndicatorView stopAnimating];
                }
            });
        }
    });
}




-(void) queryCitiesFromServerGCDSync:(NSString *)provinceCode parentId:(int) provinceId {

    [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
    
    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicatorView.center = self.view.center;
    [self.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",provinceCode]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLResponse *response = nil;
    NSError *error;
    
    NSData *data =[NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
    
    if (error) {
        NSLog(@"Request Error is: %@,  on thread %@!!",error,[NSThread currentThread]);
        [self.activityIndicatorView stopAnimating];
    }else{
        NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
        if(content!=nil){
            NSArray *cityArray = [content componentsSeparatedByString:@","];
            
            for(NSString *pValue in cityArray){
                NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                City *city = [[City alloc] init];
                city.cityCode=pArray[0];
                city.cityName=pArray[1];
                city.provinceId=provinceId;
                
                [[WeatherDB defaultWeatherDB] saveCity:city];
            }
            
            cities = [[WeatherDB defaultWeatherDB] getCities:provinceId];
            [self.areaTableView reloadData];
            NSLog(@"地市记录数：%d",[cities count]);
            
            [self.activityIndicatorView stopAnimating];
        }
        
    }

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
