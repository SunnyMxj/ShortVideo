//
//  QFTakeVideoButton.h
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 16/6/30.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol QFTakeVideoButtonDelegate <NSObject>

- (void)QFTakeVideoButtonDidTouchDown;//按下
- (void)QFTakeVideoButtonDidTouchUpInside;//手指在范围内离开
- (void)QFTakeVideoButtonDidTouchUpOutside;//手指在范围外离开
- (void)QFTakeVideoButtonDidTouchDragEnter;//手指拖动进入范围
- (void)QFTakeVideoButtonDidTouchDragExit;//手指拖动离开范围

@end

@interface QFTakeVideoButton : UIButton

@property (nonatomic,weak)id<QFTakeVideoButtonDelegate> delegate;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;

@end
