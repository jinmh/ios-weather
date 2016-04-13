//
//  County.h
//  weather
//
//  Created by jinmh on 16/3/14.
//  Copyright © 2016年 jinmh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface County : NSObject

@property(nonatomic) long id;
@property(nonatomic,strong) NSString *countyName;
@property(nonatomic,strong) NSString *countyCode;
@property(nonatomic) long cityId;


@end