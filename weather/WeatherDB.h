//
//  WeatherDB.h
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "Province.h"
#import "City.h"
#import "County.h"


@interface WeatherDB : NSObject 

+ (WeatherDB *) defaultWeatherDB;

- (void) createTables;

- (void) dropTables;

- (void) clearData;

- (void) saveProvince:(Province*) province;

- (void) saveCity:(City*) city;

- (void) saveCounty:(County*) county;

- (NSMutableArray*) getProvinces;

- (NSMutableArray*) getCities:(long) provinceId;

- (NSMutableArray*) getCounties:(long) cityId;

- (void) closeDatabaese;

@end
