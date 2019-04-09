//
//  MJMonitorRunloop.m
//  RunLoopDemo
//
//  Created by MinJing_Lin on 2019/4/2.
//  Copyright © 2019 MinJing_Lin. All rights reserved.
//

#import "MJMonitorRunloop.h"
#import <execinfo.h>
#import "MXRCallStack.h"

// minimum
static const NSInteger MXRMonitorRunloopMinOneStandstillMillisecond = 20;
static const NSInteger MXRMonitorRunloopMinStandstillCount = 1;

// default
// 超过多少毫秒为一次卡顿
static const NSInteger MXRMonitorRunloopOneStandstillMillisecond = 400;
// 多少次卡顿纪录为一次有效卡顿
static const NSInteger MXRMonitorRunloopStandstillCount = 5;

@interface MJMonitorRunloop(){
    CFRunLoopObserverRef _observer;  // 观察者
    dispatch_semaphore_t _semaphore; // 信号量
    CFRunLoopActivity _activity;     // 状态
}

@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, assign) NSInteger countTime; // 耗时次数
@property (nonatomic, strong) NSMutableArray *backtrace;

@end

@implementation MJMonitorRunloop

+ (instancetype)sharedInstance
{
    static dispatch_once_t once;
    static MJMonitorRunloop *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
        
        sharedInstance.limitMillisecond = MXRMonitorRunloopOneStandstillMillisecond;
        sharedInstance.standstillCount  = MXRMonitorRunloopStandstillCount;
    });
    return sharedInstance;
}

- (void)setLimitMillisecond:(int)limitMillisecond
{
    [self willChangeValueForKey:@"limitMillisecond"];
    _limitMillisecond = limitMillisecond >= MXRMonitorRunloopMinOneStandstillMillisecond ? limitMillisecond : MXRMonitorRunloopMinOneStandstillMillisecond;
    [self didChangeValueForKey:@"limitMillisecond"];
}

- (void)setStandstillCount:(int)standstillCount
{
    [self willChangeValueForKey:@"standstillCount"];
    _standstillCount = standstillCount >= MXRMonitorRunloopMinStandstillCount ? standstillCount : MXRMonitorRunloopMinStandstillCount;
    [self didChangeValueForKey:@"standstillCount"];
}

- (void)startMonitor
{
    self.isCancel = NO;
    [self registerObserver];
}

- (void) endMonitor
{
    self.isCancel = YES;
    if(!_observer) return;
    CFRunLoopRemoveObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    CFRelease(_observer);
    _observer = NULL;
}

static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    MJMonitorRunloop *instance = [MJMonitorRunloop sharedInstance];
    // 记录状态值
    instance->_activity = activity;
    // 发送信号
    dispatch_semaphore_t semaphore = instance->_semaphore;
    dispatch_semaphore_signal(semaphore);
}

// 注册一个Observer来监测Loop的状态,回调函数是runLoopObserverCallBack
- (void)registerObserver
{
    // 设置Runloop observer的运行环境
    CFRunLoopObserverContext context = {0, (__bridge void *)self, NULL, NULL};
    // 创建Runloop observer对象
    _observer = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                        kCFRunLoopAllActivities,
                                        YES,
                                        0,
                                        &runLoopObserverCallBack,
                                        &context);
    // 将新建的observer加入到当前thread的runloop
    CFRunLoopAddObserver(CFRunLoopGetMain(), _observer, kCFRunLoopCommonModes);
    // 创建信号
    _semaphore = dispatch_semaphore_create(0);
    
    __weak __typeof(self) weakSelf = self;
    // 在子线程监控时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        while (YES) {
            if (strongSelf.isCancel) {
                return;
            }
            // N次卡顿超过阈值T记录为一次卡顿
            long dsw = dispatch_semaphore_wait(self->_semaphore, dispatch_time(DISPATCH_TIME_NOW, strongSelf.limitMillisecond * NSEC_PER_MSEC));
            if (dsw != 0) {
                if (self->_activity == kCFRunLoopBeforeSources || self->_activity == kCFRunLoopAfterWaiting) {
                    if (++strongSelf.countTime < strongSelf.standstillCount){
                        NSLog(@"%ld",strongSelf.countTime);
                        continue;
                    }
                    [strongSelf logStack];
                    [strongSelf printLogTrace];
                    
                    NSString *backtrace = [MXRCallStack mxr_backtraceOfMainThread];
                    NSLog(@"++++%@",backtrace);
                    
                    if (strongSelf.callbackWhenStandStill) {
                        strongSelf.callbackWhenStandStill();
                    }
                }
            }
            strongSelf.countTime = 0;
        }
    });
}

- (void)logStack
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    int i;
    _backtrace = [NSMutableArray arrayWithCapacity:frames];
    for ( i = 0 ; i < frames ; i++ ){
        [_backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
}

- (void)printLogTrace{
    NSLog(@"==========堆栈==========\n %@ \n",_backtrace);
}

@end
