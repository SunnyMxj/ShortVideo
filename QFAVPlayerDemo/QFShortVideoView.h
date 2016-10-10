//
//  QFShortVideoView.h
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/10/10.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QFShortVideoView : UIView

/**
 设置视频源

 @param videoPath 本地视频地址
 @param image     默认图片
 */
- (void)setVideoPath:(NSString *)videoPath placeHolderImage:(UIImage *)image;


@end
