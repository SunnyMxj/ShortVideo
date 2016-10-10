//
//  RootViewController.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2016/10/10.
//  Copyright © 2016年 QianFan. All rights reserved.
//

#import "RootViewController.h"
#import "QFShortVideoViewController.h"
#import "QFShortVideoView.h"

#define kScreenWidth [UIScreen mainScreen].bounds.size.width


@interface RootViewController ()

@property (nonatomic,strong)QFShortVideoView *shortVideoView;

@end

@implementation RootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    UIButton *button  = [[UIButton alloc]initWithFrame:CGRectMake((kScreenWidth - 100)/2, 250, 100, 50)];
    [button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [button setTitle:@"录制小视频" forState:UIControlStateNormal];
    button.layer.cornerRadius = 5;
    button.layer.borderWidth = 1;
    button.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.view addSubview:button];
    
    
    UIButton *play  = [[UIButton alloc]initWithFrame:CGRectMake((kScreenWidth - 100)/2, 350, 100, 50)];
    [play addTarget:self action:@selector(play) forControlEvents:UIControlEventTouchUpInside];
    [play setTitle:@"play" forState:UIControlStateNormal];
    play.layer.cornerRadius = 5;
    play.layer.borderWidth = 1;
    play.layer.borderColor = [UIColor whiteColor].CGColor;
    [self.view addSubview:play];
    
    _shortVideoView = [[QFShortVideoView alloc]initWithFrame:CGRectMake(kScreenWidth - 100, self.view.bounds.size.height - 75, 100, 75)];
    _shortVideoView.backgroundColor = [UIColor lightGrayColor];
    [self.view addSubview:_shortVideoView];
    
}

- (void)buttonClicked:(UIButton *)sender {
    [self.navigationController pushViewController:[QFShortVideoViewController new] animated:YES];
}

- (void)play {
    _shortVideoView.backgroundColor = [UIColor cyanColor];
    NSString *plistPath = [[NSBundle mainBundle] pathForResource:@"demo" ofType:@"mp4"];
    
    [_shortVideoView setVideoPath:plistPath placeHolderImage:nil];
}


@end
