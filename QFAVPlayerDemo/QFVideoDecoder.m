//
//  QFVideoDecoder.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/10/10.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "QFVideoDecoder.h"
#import <AVFoundation/AVFoundation.h>

@interface QFVideoDecoder()

@property (nonatomic,assign)BOOL finishReading;
@property (nonatomic,assign)float durationInSeconds;
@property (nonatomic,assign)NSUInteger currentIndex;
@property (nonatomic,strong)NSMutableArray *imageArray;
@property (nonatomic,strong)CADisplayLink *displayLink;
@property (nonatomic,strong)AVAssetReader *reader;

@end

@implementation QFVideoDecoder

- (void)startDecodeWithVideoURL:(NSURL *)url {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *error;
    if (_reader) {
        [_reader cancelReading];
        _reader = nil;
    }
    _reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    
    int m_pixelFormatType = kCVPixelFormatType_32BGRA;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt: (int)m_pixelFormatType] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
    [_reader addOutput:videoReaderOutput];
    [_reader startReading];
    
    _finishReading = NO;
    _currentIndex = 0;
    _durationInSeconds = CMTimeGetSeconds(asset.duration);
    
    if (!_imageArray) {
        _imageArray = [NSMutableArray array];
    } else {
        for (id image in _imageArray) {
            CGImageRelease((CGImageRef)image);
        }
        [_imageArray removeAllObjects];
    }
    
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    
    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(fakeplay)];
    self.displayLink.frameInterval = rintf(60/videoTrack.nominalFrameRate);
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    // 读取视频每一个buffer转换成CGImageRef
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        CMSampleBufferRef audioSampleBuffer = NULL;
        while ([_reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
            CMSampleBufferRef sampleBuffer = [videoReaderOutput copyNextSampleBuffer];
            CGImageRef image = [self imageFromSampleBuffer:sampleBuffer];
            if(sampleBuffer) {
                if(audioSampleBuffer) { // release old buffer.
                    CFRelease(audioSampleBuffer);
                    audioSampleBuffer = nil;
                }
                audioSampleBuffer = sampleBuffer;
            } else {
                break;
            }
//            for test
//            [NSThread sleepForTimeInterval:CMTimeGetSeconds(videoTrack.minFrameDuration)];
            [_imageArray addObject:(__bridge id _Nullable)image];
        }
        _finishReading = YES;
        CFRelease(audioSampleBuffer);
    });
}

- (void)fakeplay {
    if (_imageArray.count > _currentIndex) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:onNewVideoFrameReady:)]) {
            [self.delegate decoder:self onNewVideoFrameReady:(CGImageRef)_imageArray[_currentIndex]];
        }
        _currentIndex++;
    }
    if (_finishReading && (_currentIndex >= _imageArray.count-1)) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:didFinishDecodeWithImages:duration:)]) {
            [self.delegate decoder:self didFinishDecodeWithImages:_imageArray duration:_durationInSeconds];
        }
        if (self.displayLink) {
            [self.displayLink invalidate];
            self.displayLink = nil;
        }
    }
}

- (CGImageRef)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    //Generate image to edit
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little|kCGImageAlphaPremultipliedFirst);
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    if (width < height) {//需要顺时针旋转90 ⤼
        return [self CGImageRotatedByAngle:image angle:-90 fitSize:YES];
    } else{
        return image;
    }
}

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle fitSize:(BOOL)fitSize{
    CGFloat radians = angle * (M_PI / 180);
    size_t width = (size_t)CGImageGetWidth(imgRef);
    size_t height = (size_t)CGImageGetHeight(imgRef);
    CGRect newRect = CGRectApplyAffineTransform(CGRectMake(0., 0., width, height),
                                                fitSize ? CGAffineTransformMakeRotation(radians) : CGAffineTransformIdentity);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 (size_t)newRect.size.width,
                                                 (size_t)newRect.size.height,
                                                 8,
                                                 (size_t)newRect.size.width * 4,
                                                 colorSpace,
                                                 kCGBitmapByteOrderDefault | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    if (!context) return nil;
    
    CGContextSetShouldAntialias(context, true);
    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    CGContextTranslateCTM(context, +(newRect.size.width * 0.5), +(newRect.size.height * 0.5));
    CGContextRotateCTM(context, radians);
    
    CGContextDrawImage(context, CGRectMake(-(width * 0.5), -(height * 0.5), width, height), imgRef);
    CGImageRef targetImageRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGImageRelease(imgRef);
    return targetImageRef;
}

@end
