//
//  NewTakeVideoViewController.m
//  QFShortVideoDemo
//
//  Created by QianFan_Ryan on 2017/4/6.
//  Copyright © 2017年 QianFan. All rights reserved.
//

#import "NewTakeVideoViewController.h"
#import "QFShortVideoToolView.h"

@interface NewTakeVideoViewController ()

@end

@implementation NewTakeVideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    QFShortVideoToolView *toolView = [QFShortVideoToolView new];
    [self.view addSubview:toolView];
}


@end
