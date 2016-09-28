//
//  QFTakeVideoButton.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 16/6/30.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "QFTakeVideoButton.h"
#import "QFDevice.h"

@interface QFTakeVideoButton()

@property (nonatomic,assign)BOOL isTouchOutside;

@end

@implementation QFTakeVideoButton

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(touchWithSender:event:) forControlEvents:UIControlEventAllTouchEvents];
    }
    return self;
}

- (void)touchDown{
    NSLog(@"touchDown");
    if (![QFDevice isSingleCore]) {
        [UIView animateWithDuration:0.3 animations:^{
            self.transform = CGAffineTransformMakeScale(2, 2);
            self.alpha = 0;
        } completion:^(BOOL finished) {
            self.transform = CGAffineTransformIdentity;
        }];
    }
    if ([self.delegate respondsToSelector:@selector(QFTakeVideoButtonDidTouchDown)]) {
        [self.delegate QFTakeVideoButtonDidTouchDown];
    }
}

- (void)touchUp{
    if (self.isTouchOutside) {
        [self touchUpOutside];
    } else {
        [self touchUpInside];
    }
    if ([QFDevice isSingleCore]) {
        return;
    }
    self.transform = CGAffineTransformMakeScale(2, 2);
    [UIView animateWithDuration:0.3 animations:^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = 1;
    }];
}

- (void)touchUpInside{
    NSLog(@"touchUpInside");
    if ([self.delegate respondsToSelector:@selector(QFTakeVideoButtonDidTouchUpInside)]) {
        [self.delegate QFTakeVideoButtonDidTouchUpInside];
    }
}

- (void)touchUpOutside{
    NSLog(@"touchUpOutside");
    if ([self.delegate respondsToSelector:@selector(QFTakeVideoButtonDidTouchUpOutside)]) {
        [self.delegate QFTakeVideoButtonDidTouchUpOutside];
    }
}

- (void)touchDragEnter{
    NSLog(@"UIControlEventTouchDragEnter");
    self.isTouchOutside = NO;
    if ([self.delegate respondsToSelector:@selector(QFTakeVideoButtonDidTouchDragEnter)]) {
        [self.delegate QFTakeVideoButtonDidTouchDragEnter];
    }
}

- (void)touchDragExit{
    NSLog(@"UIControlEventTouchDragExit");
    self.isTouchOutside = YES;
    if ([self.delegate respondsToSelector:@selector(QFTakeVideoButtonDidTouchDragExit)]) {
        [self.delegate QFTakeVideoButtonDidTouchDragExit];
    }
}


- (void)touchWithSender:(UIButton *)sender event:(UIEvent *)event{
    if (![event isKindOfClass:[UIEvent class]]) {
        return;
    }
    UITouch *touch = [[event allTouches] anyObject];
    CGFloat boundsExtension = 10.0f;
    CGRect outerBounds = CGRectInset(sender.bounds, -1 * boundsExtension, -1 * boundsExtension);
    CGPoint location = [touch locationInView:sender];
    CGPoint previewLocation = [touch previousLocationInView:sender];
    BOOL touchInside = CGRectContainsPoint(outerBounds, location);
    BOOL previewTouchInside = CGRectContainsPoint(outerBounds, previewLocation);
    
    if ((location.x == previewLocation.x) && (location.y == previewLocation.y)) {
        //这个情况不是touchDown就是touchUpInside
        self.isTouchOutside = NO;
        return;
    }
    if (touchInside) {
        if (previewTouchInside) {
            // UIControlEventTouchDragInside
            // NSLog(@"UIControlEventTouchDragInside");
        } else {
            // UIControlEventTouchDragEnter
            [self touchDragEnter];
        }
    } else {
        if (previewTouchInside) {
            // UIControlEventTouchDragExit
            [self touchDragExit];
        } else {
            // UIControlEventTouchDragOutside
            // NSLog(@"UIControlEventTouchDragOutside");
        }
    }
}

@end
