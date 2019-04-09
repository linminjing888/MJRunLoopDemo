//
//  MXRCallStack.h
//  easywayout
//
//  Created by Martin.Liu on 17/1/19.
//  Copyright © 2017年 MAIERSI. All rights reserved.
//

#import <Foundation/Foundation.h>

//MXR_EXTERN_C_BEGIN

#define MXRLOG_Callstack_Current NSLog(@"%@",[BSBacktraceLogger mxr_backtraceOfCurrentThread]);
#define MXRLOG_Callstack_MAIN NSLog(@"%@",[BSBacktraceLogger mxr_backtraceOfMainThread]);
#define MXRLOG_Callstack_ALL NSLog(@"%@",[BSBacktraceLogger mxr_backtraceOfAllThread]);

/**
 获取函数调用栈
 Xcode 的调试输出不稳定，有时候存在调用 NSLog() 但没有输出结果的情况，建议前往 控制台 中根据设备的 UUID 查看完整输出。
 真机调试和使用 Release 模式时，为了优化，某些符号表并不在内存中，而是存储在磁盘上的 dSYM 文件中，无法在运行时解析，因此符号名称显示为 <redacted>。
 关于dSYM可以参考https://github.com/answer-huang/dSYMTools
 @see https://github.com/bestswifter/BSBacktraceLogger
 */
@interface MXRCallStack : NSObject

+ (NSString *)mxr_backtraceOfAllThread;
+ (NSString *)mxr_backtraceOfCurrentThread;
+ (NSString *)mxr_backtraceOfMainThread;
+ (NSString *)mxr_backtraceOfNSThread:(NSThread *)thread;

@end

//MXR_EXTERN_C_END
