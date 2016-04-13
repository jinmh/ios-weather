//
//  City.h
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface City : NSObject

@property(nonatomic) long id;
@property(nonatomic,strong) NSString *cityName;
@property(nonatomic,strong) NSString *cityCode;
@property(nonatomic) long provinceId;



@end

