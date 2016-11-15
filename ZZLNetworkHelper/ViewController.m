//
//  ViewController.m
//  ZZLNetworkHelper
//
//  Created by lei on 16/9/24.
//  Copyright © 2016年 lei. All rights reserved.
//

#import "ViewController.h"
#import "HttpManagerHelper.h"
#import "ZZLNetObsercer.h"
#import "NSTimer+Kit.h"
@interface ViewController ()
@property (nonatomic,strong) UIButton *codeButton;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.codeButton = [[UIButton alloc]initWithFrame:CGRectMake(200, 200, 100, 30)];
    [self.view addSubview:self.codeButton];
    [self.codeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
    [self.codeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.codeButton.backgroundColor=[UIColor redColor];
    [self.codeButton addTarget:self action:@selector(playInpu) forControlEvents:UIControlEventTouchUpInside];
    
    
}
-(void)playInpu{
    __block NSUInteger count = 60;
    [NSTimer scheduledTimerWithTimeInterval:1 count:60 callback:^(NSTimer *timer) {
        if (count <= 1) {
            self.codeButton.enabled = YES;
            [self.codeButton setTitle:@"获取验证码" forState:UIControlStateNormal];
            [self.codeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.codeButton.backgroundColor=[UIColor redColor];
        } else {
            [self.codeButton setTitle:[NSString stringWithFormat:@"%lds后获取", --count] forState:UIControlStateNormal];
            [self.codeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            self.codeButton.backgroundColor = [UIColor grayColor];
            self.codeButton.enabled = NO;
        }
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
