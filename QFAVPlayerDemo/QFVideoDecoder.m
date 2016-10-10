//
//  QFVideoDecoder.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/10/10.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "QFVideoDecoder.h"
#import <AVFoundation/AVFoundation.h>

@implementation QFVideoDecoder

- (void)startDecodeWithVideoURL:(NSURL *)url {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    AVAssetTrack *videoTrack = [videoTracks objectAtIndex:0];
    
    int m_pixelFormatType = kCVPixelFormatType_32BGRA;
    NSDictionary *options = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt: (int)m_pixelFormatType] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
    [reader addOutput:videoReaderOutput];
    [reader startReading];
    
    // 读取视频每一个buffer转换成CGImageRef
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *imageArray = [NSMutableArray array];
        
        CMSampleBufferRef audioSampleBuffer = NULL;
        while ([reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
            CMSampleBufferRef sampleBuffer = [videoReaderOutput copyNextSampleBuffer];
            CGImageRef image = [self imageFromSampleBuffer:sampleBuffer];
            if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:onNewVideoFrameReady:)]) {
                [self.delegate decoder:self onNewVideoFrameReady:image];
            }
            if(sampleBuffer) {
                if(audioSampleBuffer) { // release old buffer.
                    CFRelease(audioSampleBuffer);
                    audioSampleBuffer = nil;
                }
                audioSampleBuffer = sampleBuffer;
            } else {
                break;
            }
            
            // 休眠的间隙刚好是每一帧的间隔
#warning TODO cadisplaylink
            [NSThread sleepForTimeInterval:CMTimeGetSeconds(videoTrack.minFrameDuration)];
            [imageArray addObject:(__bridge id _Nullable)image];
        }
        // decode finish
        float durationInSeconds = CMTimeGetSeconds(asset.duration);
        if (self.delegate && [self.delegate respondsToSelector:@selector(decoder:didFinishDecodeWithImages:duration:)]) {
            [self.delegate decoder:self didFinishDecodeWithImages:imageArray duration:durationInSeconds];
        }
    });
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
    return [self CGImageRotatedByAngle:image angle:-90];
}

- (CGImageRef)CGImageRotatedByAngle:(CGImageRef)imgRef angle:(CGFloat)angle{
#warning TODO
    CGFloat angleInRadians = angle * (M_PI / 180);
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    
    CGRect imgRect = CGRectMake(0, 0, width, height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(angleInRadians);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                   rotatedRect.size.width,
                                                   rotatedRect.size.height,
                                                   8,
                                                   0,
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedFirst);
//    CGContextSetAllowsAntialiasing(bmContext, YES);
//    CGContextSetShouldAntialias(bmContext, YES);
//    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    CGColorSpaceRelease(colorSpace);
    CGContextTranslateCTM(bmContext, +(rotatedRect.size.width/2), +(rotatedRect.size.height/2));
    CGContextRotateCTM(bmContext, angleInRadians);
    CGContextTranslateCTM(bmContext, -(rotatedRect.size.height/2), -(rotatedRect.size.width/2));
    CGContextDrawImage(bmContext, CGRectMake(0, 0, rotatedRect.size.width, rotatedRect.size.height), imgRef);
    
    
    CGImageRef rotatedImage = CGBitmapContextCreateImage(bmContext);
    CFRelease(bmContext);
    
    return rotatedImage;
}

@end
