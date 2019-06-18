//
//  AppDelegate.h
//  新闻
//
//  Created by gyh on 15/9/21.
//  Copyright © 2015年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/**
 *  选择进入哪一个tabbar控制器
 *
 *  @param index index从0开始
 */
- (void)selectTabbarIndex:(int)index;

@end

