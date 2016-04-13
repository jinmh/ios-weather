//
//  WeatherViewController.m
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import "WeatherViewController.h"
#import "WeatherDB.h"
#import "HttpUtil.h"
#import "WeatherInfoController.h"
#import "AppDelegate.h"


@implementation WeatherViewController

@synthesize areaTableView;
@synthesize backButton;

WeatherDB *db;
NSMutableArray *provinces;
NSMutableArray *cities;
NSMutableArray *counties;

Province *selectedProvince;
City *selectedCity;
County *selectedCounty;




- (id)init
{
    self = [super init];
    if (self) {
        self.title = @"全国";
    }
    return self;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if(currentLevel==LEVEL_PROVINCE){
        return [provinces count];
    }else if(currentLevel==LEVEL_CITY){
        return [cities count];
    }else if(currentLevel==LEVEL_COUNTY){
        return [counties count];
    }else{
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell =[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
    }
    NSUInteger row = [indexPath row];
    
    if(currentLevel==LEVEL_PROVINCE){
        Province *province = (Province*)provinces[row];
        cell.textLabel.text = province.provinceName;
    }else if(currentLevel==LEVEL_CITY){
        City *city = (City*)cities[row];
        cell.textLabel.text = city.cityName;
    }else if(currentLevel==LEVEL_COUNTY){
        County *county = (County*)counties[row];
        cell.textLabel.text = county.countyName;
    }
    
    return cell;
}


//选中cell触发
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSUInteger row = [indexPath row];
    
    if(currentLevel==LEVEL_PROVINCE){
        selectedProvince = (Province*)provinces[row];
        self.title = selectedProvince.provinceName;
        [self loadCities];
        [tableView reloadData];
    }else if(currentLevel==LEVEL_CITY){
        selectedCity = (City*)cities[row];
        self.title = selectedCity.cityName;
        [self loadCounties];
        [tableView reloadData];
    }else if(currentLevel==LEVEL_COUNTY){
        selectedCounty = (County*)counties[row];
        NSUserDefaults *userDefaults =[NSUserDefaults standardUserDefaults];
        [userDefaults setObject:selectedCounty.countyCode forKey:@"countyCode"];
        [userDefaults setObject:selectedCounty.countyName forKey:@"countyName"];
        
        WeatherInfoController *infoController = [[WeatherInfoController alloc] init];
        //[self presentViewController:infoController animated:YES completion:nil];
        [self.navigationController pushViewController:infoController animated:true];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view, typically from a nib.
    UIDevice *device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    //利用 NSNotificationCenter 获得旋转信号 UIDeviceOrientationDidChangeNotification
    NSNotificationCenter *ncenter = [NSNotificationCenter defaultCenter];
    [ncenter addObserver:self selector:@selector(orientationChanged) name:UIDeviceOrientationDidChangeNotification object:device];
    
}

//屏幕旋转处理
- (void) orientationChanged{
    UIDeviceOrientation orientaiton = [[UIDevice currentDevice] orientation];
    
    switch (orientaiton) {
        case UIDeviceOrientationPortrait:
            areaTableView.frame = CGRectMake(0, 0, [AppDelegate getScreenWidth],[AppDelegate getScreenHeight]-40);
            backButton.frame = CGRectMake(0, [AppDelegate getScreenHeight]-40, [AppDelegate getScreenWidth], 20);
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            areaTableView.frame = CGRectMake(0, 0, [AppDelegate getScreenWidth],[AppDelegate getScreenHeight]-40);
            backButton.frame = CGRectMake(0, [AppDelegate getScreenHeight]-40, [AppDelegate getScreenWidth], 20);
            
            break;
        case UIDeviceOrientationLandscapeLeft:
            areaTableView.frame = CGRectMake(0, 0, [AppDelegate getScreenHeight],[AppDelegate getScreenWidth]-40);
            backButton.frame = CGRectMake(0, [AppDelegate getScreenWidth]-40, [AppDelegate getScreenHeight], 20);
            break;
        case UIDeviceOrientationLandscapeRight:
            areaTableView.frame = CGRectMake(0, 0, [AppDelegate getScreenHeight],[AppDelegate getScreenWidth]-40);
            backButton.frame = CGRectMake(0, [AppDelegate getScreenWidth]-40, [AppDelegate getScreenWidth], 20);
            break;
        default:
            break;
    }
}



- (void) loadView{
    [super loadView];
    
    CGRect rect = CGRectMake(0, 0, [AppDelegate getScreenWidth], [AppDelegate getScreenHeight]-40);
    areaTableView = [[UITableView alloc] initWithFrame:rect];
    
    db = [[WeatherDB alloc] init];
    [self loadProvices];
    [areaTableView setDataSource:self];
    [areaTableView setDelegate:self];
  

    [self.view addSubview:areaTableView];
    [self initFooterButton];
    [backButton setTitle:@"退出" forState:UIControlStateNormal];
}



-(void)initFooterButton
{
    //初始化Button
    backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [backButton setTitle:@"返回" forState:UIControlStateNormal];
    backButton.frame = CGRectMake(0, [AppDelegate getScreenHeight]-40, [AppDelegate getScreenWidth], 20);
    backButton.titleEdgeInsets = UIEdgeInsetsMake(10,0,10,0);
    //backButton.titleLabel.font = [UIFont systemFontOfSize:20];
    
    //设置触发事件
    [backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:backButton];
}


- (void) backButtonClick {
    if(currentLevel==LEVEL_PROVINCE){
        exit(0);
    }else if(currentLevel==LEVEL_CITY){
        self.title = @"全国";
        [self loadProvices];
        [areaTableView reloadData];
        [self orientationChanged];
    }else if(currentLevel==LEVEL_COUNTY){
        self.title = selectedProvince.provinceName;
        [self loadCities];
        [areaTableView reloadData];
        [self orientationChanged];
    }
}



- (void) loadProvices{
    provinces = [db getProvinces];
    
    NSLog(@"省份记录数：%du",[provinces count]);
    
    if([provinces count]==0){
        [self queryProvinceFromServer];
    }
    //self.areaTableView.tableFooterView = nil;
    [backButton setTitle:@"退出" forState:UIControlStateNormal];
    currentLevel = LEVEL_PROVINCE;
}

- (void) loadCities{
    if(selectedProvince != nil){
        cities = [db getCities:selectedProvince.id];
        NSLog(@"地市记录数：%du",[cities count]);
        if([cities count]==0){
        [self queryCitiesFromServer:selectedProvince.provinceCode parentId:selectedProvince.id];
        }
        //self.areaTableView.tableFooterView = backButton;
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        currentLevel = LEVEL_CITY;
    }
}

- (void) loadCounties{
    if(selectedCity !=nil){
        counties = [db getCounties:selectedCity.id];
        NSLog(@"区县记录数：%du",[counties count]);
        if([counties count]==0){
            [self queryCountiesFromServer:selectedCity.cityCode parentId:selectedCity.id];
        }
        //self.areaTableView.tableFooterView = backButton;
        [backButton setTitle:@"返回" forState:UIControlStateNormal];
        currentLevel = LEVEL_COUNTY;
    }
}


-(void) queryProvinceFromServer{
    NSString *contet = [HttpUtil responseFromRequestByURL:@"http://www.weather.com.cn/data/list3/city.xml"];
    
    NSArray *provinceArray = [contet componentsSeparatedByString:@","];
    
    for(NSString *pVadue in provinceArray){
        NSArray *pArray = [pVadue componentsSeparatedByString:@"|"];
        Province *province = [[Province alloc] init];
        province.provinceCode=pArray[0];
        province.provinceName=pArray[1];
        
        [db saveProvince:province];
    }
    
    provinces = [db getProvinces];
    NSLog(@"省份记录数：%du",[provinces count]);
}


-(void) queryCitiesFromServer:(NSString *)provinceCode parentId:(int) provinceId {
    NSString *url = [[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",provinceCode];
    NSString *contet = [HttpUtil responseFromRequestByURL:url];
    
    NSArray *cityArray = [contet componentsSeparatedByString:@","];
    
    for(NSString *pVadue in cityArray){
        NSArray *pArray = [pVadue componentsSeparatedByString:@"|"];
        City *city = [[City alloc] init];
        city.cityCode=pArray[0];
        city.cityName=pArray[1];
        city.provinceId=provinceId;
        
        [db saveCity:city];
    }
    
    cities = [db getCities:provinceId];
    NSLog(@"地市记录数：%du",[cities count]);
}


-(void) queryCountiesFromServer:(NSString *)cityCode parentId:(int) cityId {
    NSString *url = [[NSString alloc] initWithFormat:@"http://www.weather.com.cn/data/list3/city%@.xml",cityCode];
    NSString *contet = [HttpUtil responseFromRequestByURL:url];
    
    NSArray *countyArray = [contet componentsSeparatedByString:@","];
    
    for(NSString *pVadue in countyArray){
        NSArray *pArray = [pVadue componentsSeparatedByString:@"|"];
        County *county = [[County alloc] init];
        county.countyCode=pArray[0];
        county.countyName=pArray[1];
        county.cityId=cityId;
        
        [db saveCounty:county];
    }
    
    counties = [db getCounties:cityId];
    NSLog(@"区县记录数：%du",[counties count]);
}



-(void) viewDidAppear:(BOOL)animated{
    //[self orientationChanged];
}


@end
