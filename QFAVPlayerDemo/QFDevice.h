//
//  QFDevice.h
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/9/28.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QFDevice : NSObject


/**
 iPhone设备是否单核心

 @return YES：单核  NO：多核
 */
+ (BOOL)isSingleCore;

@end
