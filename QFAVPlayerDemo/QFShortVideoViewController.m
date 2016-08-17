//
//  QFShortVideoViewController.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 16/6/24.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "QFShortVideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "QFPlayerView.h"
#import "QFTakeVideoButton.h"

#define kScreenWidth    [UIScreen mainScreen].bounds.size.width
#define kScreenHeight   [UIScreen mainScreen].bounds.size.height

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

@interface QFShortVideoViewController ()<AVCaptureFileOutputRecordingDelegate,QFTakeVideoButtonDelegate,AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (nonatomic,assign)CGFloat prePublishVideoWidth;//发布前预览视频宽度

@property (nonatomic,strong)AVCaptureSession *captureSession;//负责输入和输入设备之间的数据传递
@property (nonatomic,strong)AVCaptureDeviceInput *captureDeviceInput;//负责从captureDevice获得输入数据
@property (nonatomic,strong)AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;//相机拍摄预览图层
//fileOutput
@property (nonatomic,strong)AVCaptureMovieFileOutput *captureMovieFileOutput;//视频输出流
//dataOutput
@property (nonatomic,strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic,strong) dispatch_queue_t audioDataOutputQueue;
@property (nonatomic,strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic,strong) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic,strong) AVCaptureConnection *audioConnection;
@property (nonatomic,strong) AVCaptureConnection *videoConnection;
@property (nonatomic,strong) AVAssetWriter *assetWriter;
@property (nonatomic,strong) AVAssetWriterInput *videoInput;
@property (nonatomic,strong) AVAssetWriterInput *audioInput;
@property (nonatomic,assign) BOOL isRecording;
@property (nonatomic,assign) BOOL startRecording;

@property (nonatomic,strong)UIView *preView;//上部预览视图
@property (nonatomic,strong)UILabel *tipLabel;//提示label
@property (nonatomic,strong)UILabel *illegalLabel;//手指不要松开
@property (nonatomic,strong)UIView *processLineView;//录制进度条提醒
@property (nonatomic,strong)UIColor *recordingColor;//录制时的进度颜色
@property (nonatomic,strong)UIColor *cancelColor;//准备取消的进度颜色
@property (nonatomic,strong)UIImageView *focusCursor;//聚焦光标
@property (nonatomic,strong)QFTakeVideoButton *takeButton;//摄像按钮

@property (nonatomic,weak)NSTimer *timer;
@property (nonatomic,strong)NSDate *lastStartDate;//上次开始录制时间
@property (nonatomic,assign)BOOL isCanceled;//是否取消录制了

@end

@implementation QFShortVideoViewController

- (void)dealloc{
    [self removeTimer];
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup{
    _widthHeightScale = 0.75f;
    _prePublishVideoWidth = 100;
    _minLenght = 1.0f;
    _maxLenght = 6.0f;
    _recordingColor = [UIColor greenColor];
    _cancelColor = [UIColor redColor];
    _targetSize = CGSizeMake(320, 240);
    _dataOutput = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self makeUI];
    
    [self prepareToRecord];

}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    if (_captureSession) {
        [_captureSession startRunning];
        _tipLabel.alpha = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (!self.lastStartDate) {
                _tipLabel.alpha = 0;
            }
        });
    }
    [self setFocusCursorWithPoint:_preView.center];
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
    }];
}

- (void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if (_captureSession && [_captureSession isRunning]) {
        [_captureSession stopRunning];
    }
}

- (void)makeUI{
    self.view.backgroundColor = [UIColor lightGrayColor];
    _preView = [[UIView alloc]initWithFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height + 20, kScreenWidth, kScreenWidth*_widthHeightScale)];
    _preView.backgroundColor = [UIColor blackColor];
    _preView.layer.masksToBounds = YES;
    [self.view addSubview:_preView];
    
    CGFloat preViewBottom = _preView.frame.origin.y + _preView.frame.size.height;
    
    _tipLabel = [[UILabel alloc]initWithFrame:CGRectMake((kScreenWidth - 80)/2, preViewBottom - 30, 80, 20)];
    _tipLabel.textAlignment = NSTextAlignmentCenter;
    _tipLabel.font = [UIFont systemFontOfSize:16];
    _tipLabel.text = @"双击放大";
    _tipLabel.textColor = [UIColor whiteColor];
    _tipLabel.alpha = 0;
    [self.view addSubview:_tipLabel];
    
    _illegalLabel = [[UILabel alloc]initWithFrame:CGRectMake((kScreenWidth - 100)/2, preViewBottom - 30, 100, 20)];
    _illegalLabel.textAlignment = NSTextAlignmentCenter;
    _illegalLabel.font = [UIFont systemFontOfSize:16];
    _illegalLabel.text = @"手指不要松开";
    _illegalLabel.textColor = [UIColor whiteColor];
    _illegalLabel.alpha = 0;
    _illegalLabel.backgroundColor = _cancelColor;
    [self.view addSubview:_illegalLabel];
    
    
    _processLineView = [[UIView alloc]initWithFrame:CGRectMake(0, preViewBottom, kScreenWidth, 3)];
    _processLineView.alpha = 0;
    [self.view addSubview:_processLineView];
    
    _focusCursor = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 60, 60)];
    _focusCursor.image = [UIImage imageNamed:@"focus"];
    [_preView addSubview:_focusCursor];
    _focusCursor.center = _preView.center;
    _focusCursor.alpha = 0;
    
    _takeButton = [[QFTakeVideoButton alloc]initWithFrame:CGRectMake((kScreenWidth - 130)/2, preViewBottom + 50, 130, 130)];
    [_takeButton setTitle:@"按住拍" forState:UIControlStateNormal];
    _takeButton.titleLabel.font = [UIFont systemFontOfSize:20];
    _takeButton.layer.cornerRadius = 65.0f;
    _takeButton.layer.borderWidth = 2.0f;
    _takeButton.layer.borderColor = _recordingColor.CGColor;
    _takeButton.delegate = self;
    [self.view addSubview:_takeButton];
    
    [self addTapGesture];
}

- (void)addTapGesture{
    UITapGestureRecognizer *aTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(focusAction:)];
    [self.preView addGestureRecognizer:aTap];
    
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(zoomAction:)];
    doubleTap.numberOfTapsRequired = 2;
    [aTap requireGestureRecognizerToFail:doubleTap];
    [self.preView addGestureRecognizer:doubleTap];
}

/**
 *  添加点按手势，点按时聚焦
 */
- (void)focusAction:(UITapGestureRecognizer *)tap{
    CGPoint point = [tap locationInView:self.preView];
    //将UI坐标转化为摄像头坐标
    CGPoint cameraPoint= [self.captureVideoPreviewLayer captureDevicePointOfInterestForPoint:point];
    [self setFocusCursorWithPoint:point];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposureMode:AVCaptureExposureModeAutoExpose atPoint:cameraPoint];
}

- (void)zoomAction:(UITapGestureRecognizer *)doubleTap{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if (captureDevice.videoZoomFactor == 1.0) {
            [captureDevice rampToVideoZoomFactor:2.0 withRate:2];
        } else {
            [captureDevice rampToVideoZoomFactor:1.0 withRate:2];
        }
    }];
}

/**
 *  设置聚焦光标位置
 *
 *  @param point 光标位置
 */
-(void)setFocusCursorWithPoint:(CGPoint)point{
    self.focusCursor.center = point;
    self.focusCursor.transform = CGAffineTransformMakeScale(1.5, 1.5);
    self.focusCursor.alpha = 1.0;
    [UIView animateWithDuration:0.4 animations:^{
        self.focusCursor.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.focusCursor.alpha = 0;
    }];
}

/**
 *  改变设备属性的统一操作方法
 *
 *  @param propertyChange 属性改变操作
 */
-(void)changeDeviceProperty:(PropertyChangeBlock)propertyChange{
    AVCaptureDevice *captureDevice = [self.captureDeviceInput device];
    NSError *error;
    //注意改变设备属性前一定要首先调用lockForConfiguration:调用完之后使用unlockForConfiguration方法解锁
    if ([captureDevice lockForConfiguration:&error]) {
        propertyChange(captureDevice);
        [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程发生错误，错误信息：%@",error.localizedDescription);
    }
}

/**
 *  设置聚焦点
 *
 *  @param point 聚焦点
 */
-(void)focusWithMode:(AVCaptureFocusMode)focusMode exposureMode:(AVCaptureExposureMode)exposureMode atPoint:(CGPoint)point{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        if ([captureDevice isFocusModeSupported:focusMode]) {
            [captureDevice setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        if ([captureDevice isFocusPointOfInterestSupported]) {
            [captureDevice setFocusPointOfInterest:point];
        }
        if ([captureDevice isExposureModeSupported:exposureMode]) {
            [captureDevice setExposureMode:AVCaptureExposureModeAutoExpose];
        }
        if ([captureDevice isExposurePointOfInterestSupported]) {
            [captureDevice setExposurePointOfInterest:point];
        }
    }];
}

- (void)prepareToPublishWithFileURL:(NSURL *)fileURL{
    for (UIView *subView in self.view.subviews) {
        [subView removeFromSuperview];
    }
    QFPlayerView *playerView = [[QFPlayerView alloc]initWithFrame:CGRectMake(kScreenWidth - _prePublishVideoWidth - 20, self.navigationController.navigationBar.frame.size.height + 20 + 10, _prePublishVideoWidth, _prePublishVideoWidth * _widthHeightScale)];
    playerView.muted = YES;
    [self.view addSubview:playerView];
    playerView.URL = fileURL;
}

- (void)prepareToRecord{
    //初始化会话
    _captureSession = [[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]) {//设置分辨率
        [_captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
    }
    
    //获取输入设备
    AVCaptureDevice *captureDevice = [self getCameraDeviceWithPositon:AVCaptureDevicePositionBack];//后置摄像头
    if (!captureDevice) {
        NSLog(@"获取摄像头失败");
        return;
    }
    
    //添加音频输入设备
    AVCaptureDevice *audiocaptureDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio]firstObject];
    if (!audiocaptureDevice) {
        NSLog(@"获取音频设备失败");
        return;
    }
    
    //初始化输入对象
    NSError *error = nil;
    _captureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:captureDevice error:&error];
    if (error) {
        NSLog(@"获取设备输入对象失败，error:%@",error.localizedDescription);
        return;
    }
    
    AVCaptureDeviceInput *audiocaptureDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:audiocaptureDevice error:&error];
    if (error) {
        NSLog(@"获取音频输入对象失败，error:%@",error.localizedDescription);
        return;
    }
    
    //将设备输入添加到会话中
    if ([_captureSession canAddInput:_captureDeviceInput]) {
        [_captureSession addInput:_captureDeviceInput];
        [_captureSession addInput:audiocaptureDeviceInput];
    }
    
    //创建视频预览层
    _captureVideoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    _captureVideoPreviewLayer.frame = _preView.bounds;
    _captureVideoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;//填充模式
    [_preView.layer insertSublayer:_captureVideoPreviewLayer below:_focusCursor.layer];
    
    //初始化输出对象
    if (_dataOutput) {
        [self initDataOutput];
    } else {
        _captureMovieFileOutput = [[AVCaptureMovieFileOutput alloc]init];
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([captureConnection isVideoStabilizationSupported]) {
            captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
        }
        //将设备输出添加到会话中
        if ([_captureSession canAddOutput:_captureMovieFileOutput]) {
            [_captureSession addOutput:_captureMovieFileOutput];
        }
    }
}

- (void)initDataOutput{
    _videoDataOutputQueue = dispatch_queue_create( "com.qianfan.videodata", DISPATCH_QUEUE_SERIAL);
    //        dispatch_set_target_queue(_videoDataOutputQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
    _audioDataOutputQueue = dispatch_queue_create( "com.qianfan.audiodata", DISPATCH_QUEUE_SERIAL);
    
    _videoDataOutput = [AVCaptureVideoDataOutput new];
    _videoDataOutput.videoSettings = nil;
    _videoDataOutput.alwaysDiscardsLateVideoFrames = NO;
    [_videoDataOutput setSampleBufferDelegate:self queue:_videoDataOutputQueue];
    if ([_captureSession canAddOutput:_videoDataOutput]) {
        [_captureSession addOutput:_videoDataOutput];
    }
    _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    
    _audioDataOutput = [AVCaptureAudioDataOutput new];
    [_audioDataOutput setSampleBufferDelegate:self queue:_audioDataOutputQueue];
    if ([_captureSession canAddOutput:_audioDataOutput]) {
        [_captureSession addOutput:_audioDataOutput];
    }
    _audioConnection = [_audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
}

- (AVAssetWriterInput *)videoInput{
    if (!_videoInput) {
        NSInteger numPixels = _targetSize.width * _targetSize.height;
        //每像素比特
        CGFloat bitsPerPixel = 6.0;
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        
        //码率和帧率设置
        NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),
                                                 AVVideoExpectedSourceFrameRateKey : @(30) };
        NSDictionary *videoOutputSetting = @{ AVVideoCodecKey : AVVideoCodecH264,
                                             AVVideoScalingModeKey : AVVideoScalingModeResizeAspectFill,
                                             AVVideoWidthKey : @(_targetSize.height),
                                             AVVideoHeightKey : @(_targetSize.width),
                                             AVVideoCompressionPropertiesKey : compressionProperties};
        _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSetting];
        _videoInput.expectsMediaDataInRealTime = YES;
        _videoInput.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    return _videoInput;
}

- (AVAssetWriterInput *)audioInput{
    if (!_audioInput) {
        _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
        _audioInput.expectsMediaDataInRealTime = YES;
    }
    return _audioInput;
}

- (void)startRecord{
    NSURL *fileURL = [NSURL fileURLWithPath:[self tempFilePath]];
    if (_dataOutput) {
        NSError *error = nil;
        _assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
        if ([_assetWriter canAddInput:self.videoInput]) {
            [_assetWriter addInput:self.videoInput];
        }
        if ([_assetWriter canAddInput:self.audioInput]) {
            [_assetWriter addInput:self.audioInput];
        }
        [_assetWriter startWriting];
        _startRecording = NO;
        _isRecording = YES;
        [self setupTimer];
        [self startAnimation];
    } else {
        //根据设备输出获得连接
        AVCaptureConnection *captureConnection = [_captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
        //根据连接取得设备输出的数据
        if (!_captureMovieFileOutput.isRecording) {
            //预览图层和视频方向保持一致
            captureConnection.videoOrientation = AVCaptureVideoOrientationPortrait;//[self.captureVideoPreviewLayer connection].videoOrientation;
            [_captureMovieFileOutput startRecordingToOutputFileURL:fileURL recordingDelegate:self];
            [self setupTimer];
            [self startAnimation];
        } else {
            //停止保存
            [_captureMovieFileOutput stopRecording];
        }
    }
}


- (void)cancelRecord{
    self.isCanceled = YES;
    if (_dataOutput) {
        _isRecording = NO;
        [_assetWriter cancelWriting];
        _assetWriter = nil;
    } else {
        [_captureMovieFileOutput stopRecording];
    }
    [self removeTimer];
    [self stopAnimation];
}

- (void)saveRecord{
    if (_dataOutput) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            __weak typeof(self) weakSelf = self;
            [_assetWriter finishWritingWithCompletionHandler:^{
                [weakSelf cropVideoWithFilrURL:weakSelf.assetWriter.outputURL];
                weakSelf.assetWriter = nil;
            }];
        });
        [_captureSession stopRunning];
    } else {
        self.isCanceled = NO;
        [_captureSession stopRunning];
    }
}

- (void)setupTimer{
    if (self.timer && self.timer.isValid) {
        return;
    }
    [[NSRunLoop currentRunLoop]addTimer:(self.timer = [NSTimer timerWithTimeInterval:_maxLenght target:self selector:@selector(saveRecord) userInfo:nil repeats:NO]) forMode:NSRunLoopCommonModes];
}

- (void)startAnimation{
    self.processLineView.frame = CGRectMake(0, self.processLineView.frame.origin.y, kScreenWidth, self.processLineView.frame.size.height);
    self.processLineView.backgroundColor = _recordingColor;
    self.processLineView.alpha = 1;
    [UIView animateWithDuration:_maxLenght animations:^{
        self.processLineView.frame = CGRectMake(kScreenWidth/2, self.processLineView.frame.origin.y, 0, self.processLineView.frame.size.height);
    } completion:^(BOOL finished) {
        self.processLineView.alpha = 0;
    }];
    self.illegalLabel.alpha = 0;
    self.tipLabel.alpha = 1;
    self.tipLabel.text = @"↑上移取消";
    self.tipLabel.textColor = _recordingColor;
    self.tipLabel.backgroundColor = nil;
}

- (void)removeTimer{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)stopAnimation{
    [self.processLineView.layer removeAllAnimations];
    self.processLineView.alpha = 0;
    [UIView animateWithDuration:0.4 animations:^{
        self.tipLabel.alpha = 0;
    }];
}

#pragma mark -- QFTakeVideoButtonDelegate
- (void)QFTakeVideoButtonDidTouchDown{//按下
    self.lastStartDate = [NSDate date];
    //开始录制：上移取消
    [self startRecord];
}
- (void)QFTakeVideoButtonDidTouchUpInside{//手指在范围内离开
    NSTimeInterval timeinterval = [[NSDate date]timeIntervalSinceDate:self.lastStartDate];
    if (timeinterval < _minLenght) {
        //时间太短：手指不要放开
        self.illegalLabel.alpha = 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.illegalLabel.alpha = 0;
        });
        [self cancelRecord];
    } else {
        //结束录制
        [self stopAnimation];
        [self saveRecord];
    }
}
- (void)QFTakeVideoButtonDidTouchUpOutside{//手指在范围外离开
    //取消录制
    [self cancelRecord];
}
- (void)QFTakeVideoButtonDidTouchDragEnter{//手指拖动进入范围
    //上移取消
    self.tipLabel.text = @"↑上移取消";
    self.tipLabel.textColor = _recordingColor;
    self.tipLabel.backgroundColor = nil;
}
- (void)QFTakeVideoButtonDidTouchDragExit{//手指拖动离开范围
    //松手取消
    self.tipLabel.text = @"松手取消";
    self.tipLabel.textColor = [UIColor whiteColor];
    self.tipLabel.backgroundColor = _cancelColor;
}

#pragma mark -- AVCaptureVideoDataOutputSampleBufferDelegate / AVCaptureAudioDataOutputSampleBufferDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    if (!_isRecording) {
        return;
    }
    if (connection == _videoConnection) {
        if (!_startRecording) {
            _startRecording = YES;
            [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        }
        if (self.videoInput.readyForMoreMediaData) {
            [self.videoInput appendSampleBuffer:sampleBuffer];
        }
    } else if (connection == _audioConnection) {
        if (self.audioInput.readyForMoreMediaData) {
            [self.audioInput appendSampleBuffer:sampleBuffer];
        }
    }
}

#pragma mark -- AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections{
    NSLog(@"开始save了，地址是：%@",fileURL);
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error{
    NSLog(@"结束save  error：%@",error);
    if (self.isCanceled) {
        [self deleteVideoFileWithFileURL:outputFileURL];
    } else {
        [self cropVideoWithFilrURL:outputFileURL];
    }
}

//获得指定位置的摄像头
- (AVCaptureDevice *)getCameraDeviceWithPositon:(AVCaptureDevicePosition)positon{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in cameras) {
        if (device.position == positon) {
            return device;
        }
    }
    return nil;
}

#pragma mark -- crop video
//crop video
- (void)cropVideoWithFilrURL:(NSURL *)fileURL {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[fileURL.absoluteString substringFromIndex:7]]){
        return;
    }
    // input file
    AVAsset *asset = [AVAsset assetWithURL:fileURL];
    AVMutableVideoComposition *videoComposition;
    // input clip
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    // make it square
    videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = CGSizeMake(clipVideoTrack.naturalSize.height, clipVideoTrack.naturalSize.height * _widthHeightScale);
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
    
    // rotate to portrait
    AVMutableVideoCompositionLayerInstruction *transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
    CGAffineTransform t1 = CGAffineTransformMakeTranslation(clipVideoTrack.naturalSize.height, -(clipVideoTrack.naturalSize.width - clipVideoTrack.naturalSize.height * _widthHeightScale) /2 );
    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
    CGAffineTransform finalTransform = t2;
    [transformer setTransform:finalTransform atTime:kCMTimeZero];
    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject:instruction];
    
    // export
    NSString *outputFilePath = [self outputFilePath];
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetMediumQuality];
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = videoComposition;
    exporter.outputURL = [NSURL fileURLWithPath:outputFilePath];
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self prepareToPublishWithFileURL:[NSURL fileURLWithPath:outputFilePath]];
        });
        [self deleteVideoFileWithFileURL:fileURL];
        NSLog(@"Export done!");
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
        [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:[NSURL fileURLWithPath:outputFilePath] completionBlock:NULL];
    }];
}

- (NSString *)tempFilePath{
    NSString *outputFileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/Library/tempVideo"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:outputFileDir isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)){
        [fileManager createDirectoryAtPath:outputFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/%@%@",outputFileDir,[[NSDate date].description stringByReplacingOccurrencesOfString:@" " withString:@"_"],@".mov"];
    NSLog(@"filePath create : %@",filePath);
    return filePath;
}

- (NSString *)outputFilePath{
    NSString *outputFileDir = [NSTemporaryDirectory() stringByAppendingPathComponent:@"/Library/outputVideo"];
    BOOL isDir = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL existed = [fileManager fileExistsAtPath:outputFileDir isDirectory:&isDir];
    if (!(isDir == YES && existed == YES)){
        [fileManager createDirectoryAtPath:outputFileDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *filePath = [NSString stringWithFormat:@"%@/%@%@",outputFileDir,[[NSDate date].description stringByReplacingOccurrencesOfString:@" " withString:@"_"],@".mp4"];
    NSLog(@"filePath create : %@",filePath);
    return filePath;
}

- (BOOL)deleteVideoFileWithFileURL:(NSURL *)fileURL{
    if ([[NSFileManager defaultManager] fileExistsAtPath:[fileURL.absoluteString substringFromIndex:7]]) {
        NSError *error = nil;
        [[NSFileManager defaultManager] removeItemAtPath:[fileURL.absoluteString substringFromIndex:7] error:&error];
        if (!error) {
            NSLog(@"delete success");
            return YES;
        } else {
            NSLog(@"delete error: %@",error);
            return NO;
        }
    }
    NSLog(@"delete file does not exist");
    return NO;
}

@end
