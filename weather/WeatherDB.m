//
//  WeatherDB.m
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WeatherDB.h"




@implementation WeatherDB{
    sqlite3 *weatherDB;
    
}

static WeatherDB *defaultDB = nil;

+(WeatherDB *)defaultWeatherDB{
    if(!defaultDB){
        defaultDB = [[self alloc] init];
    }
    return defaultDB;
}


-(id) init{
    if(self=[super init]){
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documents = [paths objectAtIndex:0];
        NSString *path = [documents stringByAppendingPathComponent:@"weather.db"];
        NSLog(@"数据文件路径：%@",path);
        
        if(sqlite3_open([path UTF8String],&weatherDB)==SQLITE_OK){
            NSLog(@"Opened Database weather!");
            [self dropTables];
            [self createTables];
            //[self clearData];
        }else{
            sqlite3_close(weatherDB);
            NSAssert(0, @"Failed to open database:'%s'.", sqlite3_errmsg(weatherDB));
        }
    }
    
    return self;
}


- (void) closeDatabaese {
    if(sqlite3_close(weatherDB)!=SQLITE_OK){
        NSAssert(0,@"Failed to close database: '%s' .",sqlite3_errmsg(weatherDB));
    }else{
        NSLog(@"Closed Database weather!");        
    }
}

- (void) executeSQL:(NSString*) sql{
    char *errorMsg;
    @try {
        if(sqlite3_exec(weatherDB, [sql UTF8String], NULL, NULL, &errorMsg) != SQLITE_OK){
            NSAssert(0,@"SQL执行失败，%s",errorMsg);
            NSLog(@"%s",errorMsg);
            
            sqlite3_free(errorMsg);
        }
    }
    @catch (NSException *exception) {
        NSLog(@"捕获到异常:%@",exception);
    }
    @finally {
        
    }

}

- (void) createTables {
    [self executeSQL:@"create table province (id integer primary key autoincrement, province_name text,province_code text)"];
    
    [self executeSQL:@"create table city (id integer primary key autoincrement,city_name text,city_code text,province_id integer)"];
    
    [self executeSQL:@"create table county (id integer primary key autoincrement,county_name text,county_code text,city_id integer)"];
}


- (void) dropTables {
    [self executeSQL:@"drop table province;"];
    [self executeSQL:@"drop table city;"];
    [self executeSQL:@"drop table county;"];
}


- (void) clearData {
    [self executeSQL:@"delete from province;"];
    [self executeSQL:@"delete from city;"];
    [self executeSQL:@"delete from county;"];
}


- (void) saveProvince:(Province*) province {
    NSString *insertProvince = [[NSString alloc] initWithFormat:@"insert into province(province_name,province_code) values('%@','%@');",province.provinceName,province.provinceCode];
    
    
    [self executeSQL:insertProvince];

}


- (void) saveCity:(City*) city {
     NSString *insertCity = [[NSString alloc] initWithFormat:@"insert into city(city_name,city_code,province_id) values('%@','%@',%ld);",city.cityName,city.cityCode,city.provinceId];
    [self executeSQL:insertCity];
}

- (void) saveCounty:(County*) county {
     NSString *insertCounty = [[NSString alloc] initWithFormat:@"insert into county(county_name,county_code,city_id) values('%@','%@',%ld);",county.countyName,county.countyCode,county.cityId];
    
    [self executeSQL:insertCounty];
    
}


-(NSMutableArray*)getProvinces {
    NSMutableArray *provinces = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmt;
    NSString *queryProvince=@"select * from province";
    
    int result = sqlite3_prepare_v2(weatherDB, [queryProvince UTF8String], -1, &stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            Province *province = [[Province alloc] init];
            province.id=sqlite3_column_int(stmt,0);
            province.provinceName=[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(stmt,1)];
            province.provinceCode=[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(stmt,2)];
            
            [provinces addObject:province];
        }

        sqlite3_finalize(stmt);
    }else{
        NSLog(@"查询省份数据出错，错误号：%d",result);
    }
    
    return provinces;
}


-(NSMutableArray*)getCities:(long)provinceId {
    NSMutableArray *cities= [[NSMutableArray alloc] init];
    sqlite3_stmt *stmt;
    NSString *queryCities= [[NSString alloc] initWithFormat:@"select * from city where province_id=%ld",provinceId];
    
    int result = sqlite3_prepare_v2(weatherDB, [queryCities UTF8String], -1, &stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            City *city = [[City alloc] init];
            city.id=sqlite3_column_int(stmt,0);
            city.cityName=[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(stmt,1)];
            city.cityCode=[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(stmt,2)];
            city.provinceId = sqlite3_column_int(stmt,3);
            
            [cities addObject:city];
        }
        
        sqlite3_finalize(stmt);
    }else{
        NSLog(@"查询地市数据出错，错误号：%d",result);
    }
    
    
    return cities;
}



-(NSMutableArray*)getCounties:(long)cityId {
    NSMutableArray *counties = [[NSMutableArray alloc] init];
    sqlite3_stmt *stmt;
    NSString *queryCities= [[NSString alloc] initWithFormat:@"select * from county where city_id=%ld",cityId];
    
    int result = sqlite3_prepare_v2(weatherDB, [queryCities UTF8String], -1, &stmt, nil);
    if(result==SQLITE_OK){
        while (sqlite3_step(stmt)==SQLITE_ROW) {
            County *county = [[County alloc] init];
            county.id=sqlite3_column_int(stmt,0);
            county.countyName=[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(stmt,1)];
            county.countyCode=[[NSString alloc] initWithUTF8String:(char *)sqlite3_column_text(stmt,2)];
            county.cityId = sqlite3_column_int(stmt,3);
            
            [counties addObject:county];
        }
        
        sqlite3_finalize(stmt);
    }else{
        NSLog(@"查询区县数据出错，错误号：%d",result);
    }

    
    
    
    return counties;
}



@end