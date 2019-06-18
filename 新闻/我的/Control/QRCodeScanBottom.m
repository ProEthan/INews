//
//  QRCodeScanBottom.m
//  QRScan
//
//  Created by Jerry on 16/10/10.
//  Copyright © 2016年 yejunyou. All rights reserved.
//

#import "QRCodeScanBottom.h"

@implementation QRCodeScanBottom

- (instancetype)initWithFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        
        // 相册
        _albumn = [[YYBottomButton alloc] init];
        [_albumn setImage:[UIImage imageNamed:@"qrcode_albumn_normal"] forState:UIControlStateNormal];
        [_albumn setTitle:@"相册" forState:UIControlStateNormal];
        [self addSubview:_albumn];
        
        
        _light = [[YYBottomButton alloc] init];
        [_light setImage:[UIImage imageNamed:@"qrcode_light_off"] forState:UIControlStateNormal];
        [_light setImage:[UIImage imageNamed:@"qrcode_light_on"] forState:UIControlStateSelected];
        [_light setTitle:@"开灯" forState:UIControlStateNormal];
        [_light setTitle:@"关灯" forState:UIControlStateSelected];
        [self addSubview:_light];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    CGSize size = CGSizeMake(34, 34);
    CGFloat offX = 40;
    CGFloat centerX = self.frame.size.width / 2;
    CGFloat centerY = self.frame.size.height / 2;
    _albumn.frame = (CGRect){{centerX - size.width  - offX, centerY}, size};
    _light.frame = (CGRect){{centerX  + offX, centerY}, size};
}

@end
