//
//  WeatherViewController.m
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import "CountyViewController.h"
#import "WeatherDB.h"
#import "WeatherInfoController.h"
#import "AppDelegate.h"


@implementation CountyViewController{
    NSMutableArray *counties;
    County *selectedCounty;
    bool isVertical;
}

@synthesize areaTableView;
@synthesize activityIndicatorView;







- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{

        return [counties count];

}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    NSUInteger row = [indexPath row];
    
    County *county = (County*)counties[row];
    cell.textLabel.text = county.countyName;

    
    return cell;
}


//选中cell触发
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger row = [indexPath row];
    
    selectedCounty = (County*)counties[row];
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    [userDefaults setObject:selectedCounty.countyCode forKey:@"countyCode"];
    [userDefaults setObject:selectedCounty.countyName forKey:@"countyName"];
        
    WeatherInfoController *infoController = [[WeatherInfoController alloc] init];
    [self.navigationController pushViewController:infoController animated:true];

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
    //[self.areaTableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];

    

    [areaTableView setDataSource:self];
    [areaTableView setDelegate:self];
    
    [self loadCounties];
}


- (void) loadCounties{
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSInteger cityId = (NSInteger)[userDefaults objectForKey:@"cityId"];
    NSString *cityCode = (NSString *)[userDefaults objectForKey:@"cityCode"];
    NSString *cityName = (NSString *)[userDefaults objectForKey:@"cityName"];
    
    self.title = cityName;

    counties = [[WeatherDB defaultWeatherDB] getCounties:cityId];
    
    [self.view addSubview:areaTableView];
    NSLog(@"区县记录数：%d",[counties count]);
    if([counties count]==0){
        [self queryCountiesFromServerGCDAsync:cityCode parentId:cityId];
    }


}




-(void) queryCountiesFromServerGCDAsync:(NSString *)cityCode parentId:(int) cityId{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;

        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.center = self.view.center;
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
        
        NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",cityCode]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSURLResponse *response = nil;
        
        NSError *error;
        
        NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;

        if (error) {
            NSLog(@"Request Error is: %@,  on thread %@!!",error,[NSThread currentThread]);
            [self.activityIndicatorView stopAnimating];
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
                if(content!=nil){
                    NSArray *countyArray = [content componentsSeparatedByString:@","];
                    
                    for(NSString *pValue in countyArray){
                        NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                        County *county = [[County alloc] init];
                        county.countyCode=pArray[0];
                        county.countyName=pArray[1];
                        county.cityId=cityId;
                        
                        [[WeatherDB defaultWeatherDB] saveCounty:county];
                    }
                    
                    counties = [[WeatherDB defaultWeatherDB] getCounties:cityId];
                    [self.areaTableView reloadData];
                    NSLog(@"区县记录数：%d",[counties count]);
                    [self.activityIndicatorView stopAnimating];
                }
            });
        }
    });
}



-(void) queryCountiesFromServerSync:(NSString *)cityCode parentId:(int) cityId{

    self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.activityIndicatorView.center = self.view.center;
    [self.view addSubview:self.activityIndicatorView];
    [self.activityIndicatorView startAnimating];
    
    NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",cityCode]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLResponse *response = nil;
    
    NSError *error;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        NSLog(@"Request Error is: %@,  on thread %@!!",error,[NSThread currentThread]);
        [self.activityIndicatorView stopAnimating];
    }else{
        
        NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
        if(content!=nil){
            NSArray *countyArray = [content componentsSeparatedByString:@","];
            
            for(NSString *pValue in countyArray){
                NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                County *county = [[County alloc] init];
                county.countyCode=pArray[0];
                county.countyName=pArray[1];
                county.cityId=cityId;
                
                [[WeatherDB defaultWeatherDB] saveCounty:county];
            }
            
            counties = [[WeatherDB defaultWeatherDB] getCounties:cityId];
            [self.areaTableView reloadData];
            NSLog(@"区县记录数：%d",[counties count]);
            [self.activityIndicatorView stopAnimating];
        }
        
    }

}



-(void) queryCountiesFromServerAsync:(NSString *)cityCode parentId:(int) cityId{
    NSURL * url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",cityCode]];
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
                NSArray *countyArray = [content componentsSeparatedByString:@","];
                
                for(NSString *pValue in countyArray){
                    NSArray *pArray = [pValue componentsSeparatedByString:@"|"];
                    County *county = [[County alloc] init];
                    county.countyCode=pArray[0];
                    county.countyName=pArray[1];
                    county.cityId=cityId;
                    
                    [[WeatherDB defaultWeatherDB] saveCounty:county];
                }
                
                counties = [[WeatherDB defaultWeatherDB] getCounties:cityId];
                [self.areaTableView reloadData];
                NSLog(@"区县记录数：%d",[counties count]);
            }
            NSLog(@" statusCode is %d on thread %@",[(NSHTTPURLResponse*)response  statusCode],[NSThread currentThread]);
        }
        [self.activityIndicatorView stopAnimating];
    }];
    
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
    //
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
