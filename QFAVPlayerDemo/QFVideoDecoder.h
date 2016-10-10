//
//  QFVideoDecoder.h
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/10/10.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CGImage.h>

@class QFVideoDecoder;

@protocol QFVideoDecoderDelegate <NSObject>

- (void)decoder:(QFVideoDecoder *)decoder onNewVideoFrameReady:(CGImageRef)imgRef;

- (void)decoder:(QFVideoDecoder *)decoder didFinishDecodeWithImages:(NSArray *)images duration:(float)duration;

@end

@interface QFVideoDecoder : NSObject

@property (nonatomic,weak)id <QFVideoDecoderDelegate> delegate;

- (void)startDecodeWithVideoURL:(NSURL *)url;

@end
