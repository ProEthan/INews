//
//  UIView+YYExtension.m
//  QRScan
//
//  Created by Jerry on 16/10/10.
//  Copyright © 2016年 yejunyou. All rights reserved.
//

#import "UIView+YYExtension.h"

@implementation UIView (YYExtension)

- (CGFloat)yy_height
{
    return self.frame.size.height;
}

- (void)setYy_height:(CGFloat)yy_height
{
    CGRect temp = self.frame;
    temp.size.height = yy_height;
    self.frame = temp;
}

- (CGFloat)yy_width
{
    return self.frame.size.width;
}

- (void)setYy_width:(CGFloat)yy_width
{
    CGRect temp = self.frame;
    temp.size.width = yy_width;
    self.frame = temp;
}


- (CGFloat)yy_y
{
    return self.frame.origin.y;
}

- (void)setYy_y:(CGFloat)yy_y
{
    CGRect temp = self.frame;
    temp.origin.y = yy_y;
    self.frame = temp;
}

- (CGFloat)yy_x
{
    return self.frame.origin.x;
}

- (void)setYy_x:(CGFloat)yy_x
{
    CGRect temp = self.frame;
    temp.origin.x = yy_x;
    self.frame = temp;
}

@end
