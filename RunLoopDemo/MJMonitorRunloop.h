//
//  MJMonitorRunloop.h
//  RunLoopDemo
//
//  Created by MinJing_Lin on 2019/4/2.
//  Copyright © 2019 MinJing_Lin. All rights reserved.
//  卡顿检测

#import <Foundation/Foundation.h>

/**
 原理：利用观察Runloop各种状态变化的持续时间来检测计算是否发生卡顿
 一次有效卡顿采用了“N次卡顿超过阈值T”的判定策略，即一个时间段内卡顿的次数累计大于N时才触发采集和上报：举例，卡顿阈值T=500ms、卡顿次数N=1，可以判定为单次耗时较长的一次有效卡顿；而卡顿阈值T=50ms、卡顿次数N=5，可以判定为频次较快的一次有效卡顿
 */

NS_ASSUME_NONNULL_BEGIN

@interface MJMonitorRunloop : NSObject

+ (instancetype)sharedInstance;

/// 超过多少毫秒为一次卡顿 400毫秒
@property (nonatomic, assign) int limitMillisecond;

/// 多少次卡顿纪录为一次有效，默认为5次
@property (nonatomic, assign) int standstillCount;

/// 发生一次有效的卡顿回调函数
@property (nonatomic, copy) void (^callbackWhenStandStill)(void);

/**
 开始监听卡顿
 */
- (void)startMonitor;

/**
 结束监听卡顿
 */
- (void)endMonitor;

@end

NS_ASSUME_NONNULL_END
