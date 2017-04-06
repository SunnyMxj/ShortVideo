//
//  QFShortVideoToolView.m
//  QFLoadingIndicator
//
//  Created by QianFan_Ryan on 2017/4/5.
//  Copyright © 2017年 QianFan. All rights reserved.
//

#import "QFShortVideoToolView.h"

static NSString *defaultTip = @"轻触拍照，按住摄像";
static NSString *upTip = @"向上放大";
static NSString *downTip = @"向下缩小";

@interface QFShortVideoToolView ()<QFShortVideoTakeDelegate>

@property (strong, nonatomic) UILabel *tipLabel;

@property (strong, nonatomic) QFShortVideoTakeButton *takeButton;

@property (strong, nonatomic) UIButton *dismissButton;//取消拍摄
@property (strong, nonatomic) UIButton *reMakeButton;//重新拍摄
@property (strong, nonatomic) UIButton *doneButton;//完成拍摄

@property (assign, nonatomic) BOOL cancelHidden;//取消tip隐藏

@end

@implementation QFShortVideoToolView

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, SCREEN_HEIGHT - QF_TRANSFER(310), SCREEN_WIDTH, QF_TRANSFER(310))];
    if (self) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, QF_TRANSFER(30))];
        _tipLabel.textAlignment = NSTextAlignmentCenter;
        _tipLabel.textColor = [UIColor whiteColor];
        _tipLabel.font = [UIFont systemFontOfSize:QF_TRANSFER(24)];
        _tipLabel.text = defaultTip;
        [self addSubview:_tipLabel];
        
        _takeButton = [[QFShortVideoTakeButton alloc] initWithFrame:CGRectMake((SCREEN_WIDTH-QF_TRANSFER(160))/2, QF_TRANSFER(60), QF_TRANSFER(160), QF_TRANSFER(160))];
        _takeButton.delegate = self;
        [self addSubview:_takeButton];
        
        _dismissButton = [[UIButton alloc] initWithFrame:CGRectMake(((SCREEN_WIDTH-QF_TRANSFER(160))/2 - QF_TRANSFER(80))/2, _takeButton.center.y - QF_TRANSFER(80)/2, QF_TRANSFER(80), QF_TRANSFER(80))];
        [_dismissButton setImage:[UIImage imageNamed:@"下箭头"] forState:UIControlStateNormal];
        _dismissButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        [_dismissButton addTarget:self action:@selector(onDismiss) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_dismissButton];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!_cancelHidden) {
                _tipLabel.hidden = YES;
            }
        });
    }
    return self;
}

- (void)onActionDone {
    _takeButton.hidden = YES;
    _dismissButton.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        _tipLabel.hidden = YES;
        self.reMakeButton.alpha = 1;
        self.reMakeButton.center = CGPointMake(SCREEN_WIDTH/4, _takeButton.center.y);
        
        self.doneButton.alpha = 1;
        self.doneButton.center = CGPointMake(SCREEN_WIDTH*3/4, _takeButton.center.y);
    } completion:^(BOOL finished) {
        
    }];
}

- (void)reMakeButtonClicked:(UIButton *)sender {
    [self reMakeVideo];
    _takeButton.hidden = NO;
    _dismissButton.hidden = NO;
    _reMakeButton.alpha = 0;
    _reMakeButton.center = _takeButton.center;
    _doneButton.alpha = 0;
    _doneButton.center = _takeButton.center;
}

- (void)doneButtonClicked:(UIButton *)sender {
    [self finishTakeVideo];
}

#pragma mark -- property
- (UIButton *)reMakeButton {
    if (!_reMakeButton) {
        _reMakeButton = [[UIButton alloc] initWithFrame:CGRectMake(_takeButton.center.x - QF_TRANSFER(130)/2, _takeButton.center.y - QF_TRANSFER(130)/2, QF_TRANSFER(130), QF_TRANSFER(130))];
        [_reMakeButton setBackgroundImage:[UIImage imageNamed:@"重新拍摄"] forState:UIControlStateNormal];
        _reMakeButton.alpha = 0;
        [_reMakeButton addTarget:self action:@selector(reMakeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_reMakeButton];
    }
    return _reMakeButton;
}

- (UIButton *)doneButton {
    if (!_doneButton) {
        _doneButton = [[UIButton alloc] initWithFrame:CGRectMake(_takeButton.center.x - QF_TRANSFER(130)/2, _takeButton.center.y - QF_TRANSFER(130)/2, QF_TRANSFER(130), QF_TRANSFER(130))];
        [_doneButton setBackgroundImage:[UIImage imageNamed:@"完成"] forState:UIControlStateNormal];
        _doneButton.center = _takeButton.center;
        _doneButton.alpha = 0;
        [_doneButton addTarget:self action:@selector(doneButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_doneButton];
    }
    return _doneButton;
}

#pragma mark -- QFShortVideoTakeButtonDelegate
- (void)onTap {//点击事件
    if ([self.delegate respondsToSelector:@selector(onTap)]) {
        [self.delegate onTap];
    }
    _tipLabel.hidden = YES;
    [self onActionDone];
}

- (void)onMoveUp {//向上移动
    if ([self.delegate respondsToSelector:@selector(onMoveUp)]) {
        [self.delegate onMoveUp];
    }
    static BOOL isShowed;
    if (!isShowed) {
        isShowed = YES;
        _tipLabel.hidden = NO;
        _tipLabel.text = downTip;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _tipLabel.hidden = YES;
        });
    }
}

- (void)onMoveBack {//取消向上移动
    if ([self.delegate respondsToSelector:@selector(onMoveBack)]) {
        [self.delegate onMoveBack];
    }
    _tipLabel.hidden = YES;
}

- (void)onTouchDown {//开始按下
    if ([self.delegate respondsToSelector:@selector(onTouchDown)]) {
        [self.delegate onTouchDown];
    }
    _cancelHidden = YES;
    static BOOL isShowed;
    if (!isShowed) {
        isShowed = YES;
        _tipLabel.hidden = NO;
        _tipLabel.text = upTip;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            _tipLabel.hidden = YES;
        });
    }
}

- (void)onTouchUp {//结束按下
    if ([self.delegate respondsToSelector:@selector(onTouchUp)]) {
        [self.delegate onTouchUp];
    }
    [self onActionDone];
}

- (void)onDismiss {//取消拍摄
    if ([self.delegate respondsToSelector:@selector(onDismiss)]) {
        [self.delegate onDismiss];
    }
}

- (void)reMakeVideo {//重新拍摄
    if ([self.delegate respondsToSelector:@selector(reMakeVideo)]) {
        [self.delegate reMakeVideo];
    }
}
- (void)finishTakeVideo {//完成拍摄
    if ([self.delegate respondsToSelector:@selector(finishTakeVideo)]) {
        [self.delegate finishTakeVideo];
    }
}

@end
