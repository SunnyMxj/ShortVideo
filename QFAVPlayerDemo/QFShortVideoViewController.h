//
//  QFShortVideoViewController.h
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 16/6/24.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QFShortVideoViewController : UIViewController

@property (nonatomic,assign)CGFloat minLenght;//视频最长时长 default is 1
@property (nonatomic,assign)CGFloat maxLenght;//视频最长时长 default is 6
@property (nonatomic,assign)BOOL dataOutput;//是否处理输出数据 default is NO(文件输出)
@property (nonatomic,assign)CGFloat widthHeightScale;//视频的宽高比(文件输出使用) default is 0.75 , ignored if dataOutput == YES
@property (nonatomic,assign)CGSize targetSize;//视频文件的目标分辨率(data输出使用) default is 320*240 , ignored if dataOutput == NO
@end

