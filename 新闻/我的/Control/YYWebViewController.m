//
//  YYWebViewController.m
//  QRScan
//
//  Created by Jerry on 16/10/10.
//  Copyright © 2016年 yejunyou. All rights reserved.
//

#import "YYWebViewController.h"

@interface YYWebViewController ()<UIWebViewDelegate>
@property (nonatomic, strong) UIWebView *webView;
@end
@implementation YYWebViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    
    _webView = [[UIWebView alloc] init];
    _webView.delegate = self;
    _webView;
    [self.view addSubview:_webView];
}
@end
