//
//  WeatherInfoController.m
//  weather
//
//  Created by jinmh on 16/3/15.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import "WeatherInfoController.h"
#import "AppDelegate.h"



@implementation WeatherInfoController{
    bool isVertical;
}

@synthesize publishTimeLabel;
@synthesize nowTimeLabel;
@synthesize weatherDescLabel;
@synthesize lowTempLabel;
@synthesize splitTempLabel;
@synthesize highTempLabel;
@synthesize backButton;
@synthesize activityIndicatorView;



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) loadView{
    [super loadView];
    
    NSLog(@"navigationBar's width:%f",self.navigationController.navigationBar.frame.size.width);
    
    if(screenWidth < self.navigationController.navigationBar.frame.size.width){
        isVertical = false;
    }else{
        isVertical = true;
    }
    
    NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
    NSString *countyCode = (NSString *)[userDefaults objectForKey:@"countyCode"];
    NSString *countyName = (NSString *)[userDefaults objectForKey:@"countyName"];
    
    self.title=countyName;
    
    NSString *weatherCode =[self queryWeatherCodeFromServer:countyCode];
    [self queryWeatherInfoFromServer:weatherCode];
}




#pragma mark- 到天气服务器上获取天气数据


-(NSString *) queryWeatherCodeFromServer:(NSString *) countyCode {
    //www.weather.com.cn/data/list3/city050801.xml
    [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
    
    NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",countyCode]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    NSURLResponse *response = nil;
    
    NSError *error;
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];

    [UIApplication sharedApplication].networkActivityIndicatorVisible=NO;
    
    if (error) {
        NSLog(@"Request Error is: %@,  on thread %@!!",error,[NSThread currentThread]);
        return nil;
    }else{
        NSString *content = [[NSString alloc] initWithData:data encoding:(NSUTF8StringEncoding)];
        NSArray *array = [content componentsSeparatedByString:@"|"];
        
        return  array[1];
    }
    

}



-(void) queryWeatherInfoFromServer:(NSString *) weatherCode {
    //www.weather.com.cn/data/cityinfo/101050801.html
    //{"weatherinfo":{"city":"浼婃槬","cityid":"101050801","temp1":"5鈩�","temp2":"-6鈩�","weather":"鏅磋浆澶氫簯","img1":"d0.gif","img2":"n1.gif","ptime":"08:00"}}
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        self.activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        self.activityIndicatorView.center = self.view.center;
        [self.view addSubview:self.activityIndicatorView];
        [self.activityIndicatorView startAnimating];
        
        [UIApplication sharedApplication].networkActivityIndicatorVisible=YES;
        
        NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/cityinfo/%@.html",weatherCode]];
        
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
                NSError *jsonError;
                NSDictionary *weatherDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableLeaves error:&jsonError];
                NSDictionary  *weatherInfo = [weatherDic objectForKey:@"weatherinfo"];
                if(weatherInfo!=nil){
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initPublishTimeLabel:(NSString *)[weatherInfo objectForKey:@"ptime"]];
                        [self initNowTimeLabel];
                        [self initWeatherDescLabel:(NSString *)[weatherInfo objectForKey:@"weather"]];
                        [self initLowTempLabel:(NSString *)[weatherInfo objectForKey:@"temp2"]];
                        [self initSplitTempLabel];
                        [self initHighTempLabel:(NSString *)[weatherInfo objectForKey:@"temp1"]];
                    });
                }
               [self.activityIndicatorView stopAnimating];
            });
        }
        
    });
}



#pragma mark- 编码初始化显示天气信息的UILabel

-(void) initPublishTimeLabel:(NSString *) publishTime{
    publishTimeLabel = [[UILabel alloc] init];
    publishTimeLabel.text = [[NSString alloc] initWithFormat:@"今天 %@ 发布",publishTime];
    
    UIDeviceOrientation orientaition = [[UIDevice currentDevice] orientation];
    if(orientaition==UIDeviceOrientationLandscapeLeft || orientaition==UIDeviceOrientationLandscapeRight || !isVertical){
        publishTimeLabel.frame = CGRectMake(0, 60, screenHeight-20, 20);
        isVertical = false;
    }else{
        publishTimeLabel.frame = CGRectMake(0, 80, screenWidth-20, 40);
        isVertical = true;
    }
    

    publishTimeLabel.textAlignment = NSTextAlignmentRight;
    
    
    [self.view addSubview:publishTimeLabel];
}



-(void) initNowTimeLabel{
    //实例化一个NSDateFormatter对象
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    //设定时间格式,这里可以设置成自己需要的格式
    [dateFormatter setDateFormat:@"yyyy年MM月dd日 HH:mm:ss"];
    //用[NSDate date]可以获取系统当前时间
    NSString *currentDateStr = [dateFormatter stringFromDate:[NSDate date]];
    
    nowTimeLabel = [[UILabel alloc] init];
    nowTimeLabel.text = currentDateStr;
    
    
    if(isVertical){
        nowTimeLabel.frame = CGRectMake(0, screenHeight/2-60, screenWidth, 40);
    }else{
        nowTimeLabel.frame = CGRectMake(0, screenWidth/2-40, screenHeight, 40);

    }
    

    nowTimeLabel.font = [UIFont systemFontOfSize:20];
    nowTimeLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:nowTimeLabel];
}


-(void) initWeatherDescLabel:(NSString *) weatherDesc{
    weatherDescLabel = [[UILabel alloc] init];
    weatherDescLabel.text = weatherDesc;
    
    if(isVertical){
        weatherDescLabel.frame = CGRectMake(0, screenHeight/2-20, screenWidth, 40);

    }else{
        weatherDescLabel.frame = CGRectMake(0, screenWidth/2, screenHeight, 40);
    }
    

    weatherDescLabel.font = [UIFont systemFontOfSize:30];
    weatherDescLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:weatherDescLabel];
}


-(void) initLowTempLabel:(NSString *) lowTemp{
    lowTempLabel = [[UILabel alloc] init];
    lowTempLabel.text = lowTemp;
    

    if(isVertical){
        lowTempLabel.frame = CGRectMake(0, screenHeight/2+20, screenWidth/2-20, 40);

    }else{
        lowTempLabel.frame = CGRectMake(0, screenWidth/2+40, screenHeight/2-20, 40);

    }
    
    
    lowTempLabel.font = [UIFont systemFontOfSize:30];
    lowTempLabel.textAlignment = NSTextAlignmentRight;
    
    [self.view addSubview:lowTempLabel];
}

-(void) initSplitTempLabel{
    splitTempLabel = [[UILabel alloc] init];
    splitTempLabel.text = @"~";
    
    if(isVertical){
        splitTempLabel.frame = CGRectMake(screenWidth/2-20, screenHeight/2+20, 40, 40);

    }else{
        splitTempLabel.frame = CGRectMake(screenHeight/2-20, screenWidth/2+40, 40, 40);

    }
    
    splitTempLabel.font = [UIFont systemFontOfSize:30];
    splitTempLabel.textAlignment = NSTextAlignmentCenter;
    
    [self.view addSubview:splitTempLabel];
}


-(void) initHighTempLabel:(NSString *) highTemp{
   highTempLabel = [[UILabel alloc] init];
    highTempLabel.text = highTemp;
    
    if(isVertical){
        highTempLabel.frame = CGRectMake(screenWidth/2+20, screenHeight/2+20, screenWidth/2-20, 40);
    }else{
        highTempLabel.frame = CGRectMake(screenHeight/2+20, screenWidth/2+40, screenHeight/2-20, 40);
    }

    highTempLabel.font = [UIFont systemFontOfSize:30];
    highTempLabel.textAlignment = NSTextAlignmentLeft;
    
    [self.view addSubview:highTempLabel];
}




#pragma mark- 各类事件触发代码

//在进行旋转视图前的会执行的方法（用于调整旋转视图之用）
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    [self orientationChanged];
}

-(void) viewWillAppear:(BOOL)animated{
    //当收到视图在视窗将可见时的通知会呼叫的方法
    [self orientationChanged];
}



//屏幕旋转处理
- (void) orientationChanged{
    UIDeviceOrientation orientaition = [[UIDevice currentDevice] orientation];
    
    if(screenWidth < self.navigationController.navigationBar.frame.size.width){
        isVertical = false;
    }else{
        isVertical = true;
    }
    
    switch (orientaition) {
        case UIDeviceOrientationPortrait:
            publishTimeLabel.frame = CGRectMake(0, 80, screenWidth-20, 40);
            nowTimeLabel.frame = CGRectMake(0, screenHeight/2-60, screenWidth, 40);
            weatherDescLabel.frame = CGRectMake(0, screenHeight/2-20, screenWidth, 40);
            lowTempLabel.frame = CGRectMake(0, screenHeight/2+20, screenWidth/2-20, 40);
            splitTempLabel.frame = CGRectMake(screenWidth/2-20, screenHeight/2+20, 40, 40);
            highTempLabel.frame = CGRectMake(screenWidth/2+20, screenHeight/2+20, screenWidth/2-20, 40);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            publishTimeLabel.frame = CGRectMake(0, 80, screenWidth-20, 40);
            nowTimeLabel.frame = CGRectMake(0, screenHeight/2-60, screenWidth, 40);
            weatherDescLabel.frame = CGRectMake(0, screenHeight/2-20, screenWidth, 40);
            lowTempLabel.frame = CGRectMake(0, screenHeight/2+20, screenWidth/2-20, 40);
            splitTempLabel.frame = CGRectMake(screenWidth/2-20, screenHeight/2+20, 40, 40);
            highTempLabel.frame = CGRectMake(screenWidth/2+20, screenHeight/2+20, screenWidth/2-20, 40);
            break;
        case UIDeviceOrientationLandscapeLeft:
            //x,y,width,height
            publishTimeLabel.frame = CGRectMake(0, 60, screenHeight-20, 20);
            nowTimeLabel.frame = CGRectMake(0, screenWidth/2-40, screenHeight, 40);
            weatherDescLabel.frame = CGRectMake(0, screenWidth/2, screenHeight, 40);
            lowTempLabel.frame = CGRectMake(0, screenWidth/2+40, screenHeight/2-20, 40);
            splitTempLabel.frame = CGRectMake(screenHeight/2-20, screenWidth/2+40, 40, 40);
            highTempLabel.frame = CGRectMake(screenHeight/2+20, screenWidth/2+40, screenHeight/2-20, 40);
            break;
        case UIDeviceOrientationLandscapeRight:
            publishTimeLabel.frame = CGRectMake(0, 60, screenHeight-20, 20);
            nowTimeLabel.frame = CGRectMake(0, screenWidth/2-40, screenHeight, 40);
            weatherDescLabel.frame = CGRectMake(0, screenWidth/2, screenHeight, 40);
            lowTempLabel.frame = CGRectMake(0, screenWidth/2+40, screenHeight/2-20, 40);
            splitTempLabel.frame = CGRectMake(screenHeight/2-20, screenWidth/2+40, 40, 40);
            highTempLabel.frame = CGRectMake(screenHeight/2+20, screenWidth/2+40, screenHeight/2-20, 40);
            break;
        default:
            if(isVertical){
                //x,y,width,height
                publishTimeLabel.frame = CGRectMake(0, 80, screenWidth-20, 40);
                nowTimeLabel.frame = CGRectMake(0, screenHeight/2-60, screenWidth, 40);
                weatherDescLabel.frame = CGRectMake(0, screenHeight/2-20, screenWidth, 40);
                lowTempLabel.frame = CGRectMake(0, screenHeight/2+20, screenWidth/2-20, 40);
                splitTempLabel.frame = CGRectMake(screenWidth/2-20, screenHeight/2+20, 40, 40);
                highTempLabel.frame = CGRectMake(screenWidth/2+20, screenHeight/2+20, screenWidth/2-20, 40);
            }else{
                publishTimeLabel.frame = CGRectMake(0, 60, screenHeight-20, 20);
                nowTimeLabel.frame = CGRectMake(0, screenWidth/2-40, screenHeight, 40);
                weatherDescLabel.frame = CGRectMake(0, screenWidth/2, screenHeight, 40);
                lowTempLabel.frame = CGRectMake(0, screenWidth/2+40, screenHeight/2-20, 40);
                splitTempLabel.frame = CGRectMake(screenHeight/2-20, screenWidth/2+40, 40, 40);
                highTempLabel.frame = CGRectMake(screenHeight/2+20, screenWidth/2+40, screenHeight/2-20, 40);
            }
            break;
    }
}


@end
