//
//  QFDevice.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/9/28.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "QFDevice.h"
#import <sys/utsname.h>

@implementation QFDevice

+ (BOOL)isSingleCore {
    static BOOL isSingleCore;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *deviceString = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        
        NSArray *deviceMessages = @[@"iPhone1,1",@"iPhone1,2",@"iPhone2,1",@"iPhone3,1",@"iPhone3,2",@"iPhone3,3"];
        if ([deviceMessages containsObject:deviceString]) {
            isSingleCore = YES;
        } else {
            isSingleCore = NO;
        }
    });
    return isSingleCore;
}

@end
