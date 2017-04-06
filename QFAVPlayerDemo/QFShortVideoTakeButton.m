//
//  QFShortVideoTakeButton.m
//  QFLoadingIndicator
//
//  Created by QianFan_Ryan on 2017/4/5.
//  Copyright © 2017年 QianFan. All rights reserved.
//

#import "QFShortVideoTakeButton.h"

#define CIRCLE_WIDTH 2
#define PROGRESS_WIDTH 2
#define INIT_INER_RATE 0.7
#define TRAMSFORM_RATE 0.7

@interface QFShortVideoTakeButton ()

@property (assign, nonatomic) NSTimeInterval refreshRate;
@property (assign, nonatomic) NSTimeInterval currentTime;
@property (assign, nonatomic) NSTimeInterval timeLeft;//init is totalTime * refreshRate
@property (assign, nonatomic) BOOL isTap;
@property (strong, nonatomic) NSDate *startTime;

@property (weak  , nonatomic) CADisplayLink *displayLink;

@property (strong, nonatomic) UIView *inerView;
@end

@implementation QFShortVideoTakeButton

- (void)dealloc {
    [self displayLinkOFF];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _inerView = [[UIView alloc] initWithFrame:CGRectMake((1-INIT_INER_RATE)/2*frame.size.width, (1-INIT_INER_RATE)/2*frame.size.height, frame.size.width * INIT_INER_RATE, frame.size.height * INIT_INER_RATE)];
        _inerView.layer.cornerRadius = _inerView.frame.size.height/2;
        _inerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
        _inerView.userInteractionEnabled = NO;
        [self addSubview:_inerView];
        
        _delayTime = 0.3;//长按延迟时间
        _refreshRate = 30.0f;//肉眼能识别的刷新率
        _totalTime = 10.0f;
        _timeLeft = _refreshRate * _totalTime;
        
        [self addTarget:self action:@selector(touchDown) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpInside];
        [self addTarget:self action:@selector(touchUp) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(touchWithSender:event:) forControlEvents:UIControlEventAllTouchEvents];
    }
    return self;
}


- (void)touchDown{
    NSLog(@"touchDown");
    _isTap = NO;
    _startTime = [NSDate date];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_delayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (!_isTap) {
            [self displayLinkON];
            [UIView animateWithDuration:0.25 animations:^{
                _inerView.transform = CGAffineTransformMakeScale(TRAMSFORM_RATE, TRAMSFORM_RATE);
                _inerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.8];
            } completion:^(BOOL finished) {
                
            }];
            if ([self.delegate respondsToSelector:@selector(onTouchDown)]) {
                [self.delegate onTouchDown];
            }
        }
    });
}

- (void)touchUp{
    NSLog(@"touchUp");
    NSTimeInterval duration = [[NSDate date] timeIntervalSinceDate:_startTime];
    if (duration < _delayTime) {
        _isTap = YES;
        if ([self.delegate respondsToSelector:@selector(onTap)]) {
            [self.delegate onTap];
        }
    } else if ([self.delegate respondsToSelector:@selector(onTouchUp)]){
        [self displayLinkOFF];
        [UIView animateWithDuration:0.25 animations:^{
            _inerView.transform = CGAffineTransformIdentity;
            _inerView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
        } completion:^(BOOL finished) {
            
        }];
        _timeLeft = _refreshRate * _totalTime;
        [self setNeedsDisplay];
        [self.delegate onTouchUp];
    }
}

- (void)touchDragDown{
    NSLog(@"UIControlEventTouchDragEnter");
    if ([self.delegate respondsToSelector:@selector(onMoveBack)]) {
        [self.delegate onMoveBack];
    }
}

- (void)touchDragUp{
    NSLog(@"UIControlEventTouchDragExit");
    if ([self.delegate respondsToSelector:@selector(onMoveUp)]) {
        [self.delegate onMoveUp];
    }
}


- (void)touchWithSender:(UIButton *)sender event:(UIEvent *)event{
    if (![event isKindOfClass:[UIEvent class]]) {
        return;
    }
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint location = [touch locationInView:sender];
    CGPoint previewLocation = [touch previousLocationInView:sender];
    
    if (location.y > 0 && previewLocation.y <= 0) {
        [self touchDragDown];
    } else if (location.y <= 0 && previewLocation.y > 0) {
        [self touchDragUp];
    }
}


- (void)drawRect:(CGRect)rect {
    static CGFloat startAngle = -0.5 * M_PI;
    CGFloat endAngle = (1 - _timeLeft / (_refreshRate*_totalTime)) * 2 * M_PI + startAngle;
    
    UIBezierPath *circle = [UIBezierPath bezierPath];
    [circle addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                      radius:self.frame.size.width/2 - CIRCLE_WIDTH/2
                  startAngle:0
                    endAngle:2 * M_PI
                   clockwise:YES];
    circle.lineWidth = CIRCLE_WIDTH;
    [[UIColor colorWithWhite:1 alpha:0.6] setStroke];
    [circle stroke];
    
    
    UIBezierPath *progress = [UIBezierPath bezierPath];
    [progress addArcWithCenter:CGPointMake(rect.size.width / 2, rect.size.height / 2)
                        radius:self.frame.size.width/2 - CIRCLE_WIDTH/2
                    startAngle:startAngle
                      endAngle:endAngle
                     clockwise:YES];
    progress.lineWidth = PROGRESS_WIDTH;
    //    [[UIColor redColor] setStroke];
    [[UIColor colorWithRed:21/255.0f green:191/255.0f blue:255/255.0f alpha:1] set];
    [progress stroke];
}

- (void)displayLinkON {
    if (self.displayLink) {
        return;
    }
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkAction)];
    displayLink.frameInterval = rintf(60/_refreshRate);
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    self.displayLink = displayLink;
}

- (void)displayLinkOFF {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)displayLinkAction {
    _timeLeft -= 1;
    [self setNeedsDisplay];
    if (_timeLeft <= 0) {
        [self touchUp];
    }
}

@end
