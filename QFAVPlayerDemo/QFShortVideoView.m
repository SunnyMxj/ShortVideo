//
//  QFShortVideoView.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/10/10.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "QFShortVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import "QFVideoDecoder.h"

static NSString *kAnimationName = @"contents";

@interface QFShortVideoView()<QFVideoDecoderDelegate>

@property (nonatomic,strong)QFVideoDecoder *decoder;

@end

@implementation QFShortVideoView

- (void)setVideoPath:(NSString *)videoPath placeHolderImage:(UIImage *)image {
    [self.layer removeAnimationForKey:kAnimationName];
    [self.decoder startDecodeWithVideoURL:[NSURL fileURLWithPath:videoPath]];
}


#pragma mark -- property
- (QFVideoDecoder *)decoder {
    if (!_decoder) {
        _decoder = [[QFVideoDecoder alloc]init];
        _decoder.delegate = self;
    }
    return _decoder;
}

#pragma mark -- QFVideoDecoderDelegate
- (void)decoder:(QFVideoDecoder *)decoder onNewVideoFrameReady:(CGImageRef)imgRef {
//    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.contents = (__bridge id _Nullable)(imgRef);
//    });
}

- (void)decoder:(QFVideoDecoder *)decoder didFinishDecodeWithImages:(NSArray *)images duration:(float)duration {
    if (!images || images.count == 0) {
        return;
    }
//    dispatch_async(dispatch_get_main_queue(), ^{
        self.layer.contents = nil;
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
        animation.calculationMode = kCAAnimationDiscrete;
        animation.duration = duration;
        animation.repeatCount = HUGE; //循环播放
        animation.values = images; // NSArray of CGImageRefs
        [self.layer addAnimation:animation forKey:kAnimationName];
//    });
}

@end
