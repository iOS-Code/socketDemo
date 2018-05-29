//
//  EHWebSocketManager.h
//  socketDemo
//
//  Created by 岳琛 on 2018/5/29.
//  Copyright © 2018年 KMF-Engineering. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SocketRocket/SocketRocket.h>

extern NSString * const kWebSocketDidOpenNote;
extern NSString * const kWebSocketDidCloseNote;
extern NSString * const kWebSocketdidReceiveMessageNote;

@interface EHWebSocketManager : NSObject

// 获取连接状态
@property (nonatomic,assign,readonly) SRReadyState socketReadyState;

+ (instancetype)shareManager;

- (void)SRWebSocketOpenWithURLString:(NSString *)urlString;//开启连接
- (void)SRWebSocketClose;//关闭连接
- (void)sendData:(id)data;//发送数据

@end
