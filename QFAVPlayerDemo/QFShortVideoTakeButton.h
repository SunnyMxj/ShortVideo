//
//  QFShortVideoTakeButton.h
//  QFLoadingIndicator
//
//  Created by QianFan_Ryan on 2017/4/5.
//  Copyright © 2017年 QianFan. All rights reserved.
//

#import <UIKit/UIKit.h>

#define SCREEN_WIDTH [[UIScreen mainScreen] bounds].size.width
#define SCREEN_HEIGHT [[UIScreen mainScreen] bounds].size.height

#define QF_TRANSFER_FORCE(x) rintf((x) * SCREEN_WIDTH / 750)
#define QF_TRANSFER(x) ((SCREEN_WIDTH>320)?((x)/2):rintf((x) * SCREEN_WIDTH / 750))


@protocol QFShortVideoTakeDelegate <NSObject>

- (void)onTap;//点击事件
- (void)onMoveUp;//向上移动
- (void)onMoveBack;//取消向上移动
- (void)onTouchDown;//开始按下（在原有touchDown基础上延迟_delayTime 响应）
- (void)onTouchUp;//结束按下

- (void)onDismiss;//取消拍摄
- (void)reMakeVideo;//重新拍摄
- (void)finishTakeVideo;//完成拍摄

@end

@interface QFShortVideoTakeButton : UIControl

@property (weak  , nonatomic) id<QFShortVideoTakeDelegate> delegate;

@property (assign, nonatomic) NSTimeInterval delayTime;//default is 0.5
@property (assign, nonatomic) NSTimeInterval totalTime;//default is 10

- (void)displayLinkON;

- (void)displayLinkOFF;

@end
