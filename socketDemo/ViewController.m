//
//  ViewController.m
//  socketDemo
//
//  Created by 岳琛 on 2018/5/24.
//  Copyright © 2018年 KMF-Engineering. All rights reserved.
//

#import "ViewController.h"

#import <CocoaAsyncSocket/GCDAsyncSocket.h>

#import <arpa/inet.h>
#import <netinet/in.h>
#import <sys/socket.h>

#import "EHWebSocketManager.h"

@interface ViewController ()<GCDAsyncSocketDelegate, NSStreamDelegate, SRWebSocketDelegate>
{
    NSInputStream *_inputStream;
    NSOutputStream *_outputSteam;
    int _socketClient;
}

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;

@end

/**
 长连接选择TCP协议还是UDP协议
 使用TCP进行数据传输的话，简单、安全、可靠，但是带来的是服务端承载压力比较大。
 使用UDP进行数据传输的话，效率比较高，带来的服务端压力较小，但是需要自己保证数据的可靠性，不作处理的话，会导致丢包、乱序等问题。
 如果技术团队实力过硬，可以选择UDP协议，否则还是使用TCP协议比较好。
 据说腾讯IM就是使用的UDP协议，然后还封装了自己的是有协议，来保证UDP数据包的可靠传输。
 
 长连接为什么要保持心跳？
 国内移动无线网络运营商在链路上一段时间内没有数据通讯后, 会淘汰NAT表中的对应项, 造成链路中断。而国内的运营商一般NAT超时的时间为5分钟，所以通常我们心跳设置的时间间隔为3-5分钟。
 
 */

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    [self testOCSocket];
    
//    [self testGCDAsynSocket];
    
//    [self startSocket:@"127.0.0.1" andPort:12345];
    
//    [self testWebsocket];
    
    [self testEHWebSocket];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - OC

- (void)testOCSocket
{
    
    self.view.backgroundColor = [UIColor redColor];
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 400, 300, 60)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"发送数据" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickBtn1111) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    /*
     1.AF_INET: ipv4 执行ip协议的版本
     2.SOCK_STREAM：指定Socket类型,面向连接的流式socket 传输层的协议
     3.IPPROTO_TCP：指定协议。 IPPROTO_TCP 传输方式TCP传输协议
     返回值 大于0 创建成功
     */
    _socketClient = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP);
    
    /*
     终端里面 命令模拟服务器 netcat  nc -lk 12345
     参数一：套接字描述符
     参数二：指向数据结构sockaddr的指针，其中包括目的端口和IP地址
     参数三：参数二sockaddr的长度，可以通过sizeof（struct sockaddr）获得
     返回值 int -1失败 0 成功
     */
    struct sockaddr_in addr;
    /* 填写sockaddr_in结构*/
    addr.sin_family = AF_INET;
    addr.sin_port = htons(12345);
    addr.sin_addr.s_addr = inet_addr("127.0.0.1");
    int connectResult = connect( _socketClient, (const struct sockaddr *)&addr, sizeof(addr));
    
    if (connectResult == 0) {
        NSLog(@"----> 链接成功");
    } else {
        NSLog(@"----> 链接失败");
    }
    
    
    /*
     第一个参数socket
     第二个参数存放数据的缓冲区
     第三个参数缓冲区长度。
     第四个参数指定调用方式,一般置0
     返回值 接收成功的字符数
     */
    char *buf[1024];
    ssize_t recvLen = recv( _socketClient, buf, sizeof(buf), 0);
    if (recvLen > 0) {
        NSLog(@"----> 收到新消息，共%ld个字符",recvLen);
    }
}

- (void)clickBtn1111
{
    /*
     第一个参数指定发送端套接字描述符；
     第二个参数指明一个存放应用程式要发送数据的缓冲区；
     第三个参数指明实际要发送的数据的字符数；
     第四个参数一般置0。
     成功则返回实际传送出去的字符数，失败返回－1，
     */
    char * str  = "发送数据: 你好\r\n";
    ssize_t sendLen = send( _socketClient, str, strlen(str), 0);
    if (sendLen == -1) {
        NSLog(@"----> 发送失败");
    } else {
        NSLog(@"----> 发送成功，共%ld个字符", sendLen);
    }
}


#pragma mark - GCDAsyncSocket

- (void)testGCDAsynSocket
{
    self.view.backgroundColor = [UIColor redColor];
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 400, 300, 60)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"发送数据" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickBtn2222) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    self.clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;
    [self.clientSocket connectToHost:@"127.0.0.1" onPort:12345 error:&error];
    if (error) {
        NSLog(@"error == %@",error);
    }
}

- (void)clickBtn2222
{
    NSString *msg = @"发送数据: 你好\r\n";
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    // withTimeout -1 : 无穷大,一直等
    // tag : 消息标记
    [self.clientSocket writeData:data withTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port
{
    NSLog(@"链接成功");
    NSLog(@"服务器IP: %@-------端口: %d",host,port);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"发送数据 tag = %zi",tag);
    [sock readDataWithTimeout:-1 tag:tag];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"读取数据 data = %@ tag = %zi",str,tag);
    // 读取到服务端数据值后,能再次读取
    [sock readDataWithTimeout:- 1 tag:tag];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    NSLog(@"断开连接");
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
}


#pragma mark - NSStream

- (void)startSocket:(NSString *)host andPort:(int)port
{
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 400, 300, 60)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"发送数据" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickBtn3333) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    // 使用C语言 1.与服务器通过三次握手建立连接
    
    // 2.定义输入输出流
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    
    // 3.分配输入输出流的内存空间
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    
    // 4.把C语言的输入输出流转成OC对象
    _inputStream = (__bridge NSInputStream *)readStream;
    _outputSteam = (__bridge NSOutputStream *)(writeStream);
    
    // 5.设置代理,监听数据接收的状态
    _outputSteam.delegate = self;
    _inputStream.delegate = self;
    
    // 把输入输入流添加到主运行循环(RunLoop)
    // 主运行循环是监听网络状态
    [_outputSteam scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    [_inputStream scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    
    // 6.打开输入输出流
    [_inputStream open];
    [_outputSteam open];
}

//代理的回调是在主线程
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    //    NSStreamEventOpenCompleted = 1UL << 0,
    //    NSStreamEventHasBytesAvailable = 1UL << 1,
    //    NSStreamEventHasSpaceAvailable = 1UL << 2,
    //    NSStreamEventErrorOccurred = 1UL << 3,
    //    NSStreamEventEndEncountered = 1UL << 4
    
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
            NSLog(@"%@",aStream);
            NSLog(@"成功连接建立，形成输入输出流的传输通道");
            break;
            
        case NSStreamEventHasBytesAvailable:
            NSLog(@"有数据可读");
            [self readData];
            break;
            
        case NSStreamEventHasSpaceAvailable:
            NSLog(@"可以发送数据");
            break;
            
        case NSStreamEventErrorOccurred:
            NSLog(@"有错误发生，连接失败");
            break;
            
        case NSStreamEventEndEncountered:
            NSLog(@"正常的断开连接");
            //把输入输入流关闭，而还要从主运行循环移除
            [_inputStream close];
            [_outputSteam close];
            [_inputStream removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            [_outputSteam removeFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
            
            break;
        default:
            break;
    }
}

- (void)clickBtn3333
{
    NSString *msg = @"发送数据: 你好\r\n";
    NSData *data = [msg dataUsingEncoding:NSUTF8StringEncoding];
    [_outputSteam write:data.bytes maxLength:data.length];
}

- (void)readData
{
    // 定义缓存区
    uint8_t buf[3072];
    // 读取数据
    NSInteger len = [_inputStream read:buf maxLength:sizeof(buf)];
    // 把缓冲区里的实现字节数转成字符串
    NSString *receiverStr = [[NSString alloc] initWithBytes:buf length:len encoding:NSUTF8StringEncoding];
    NSLog(@"%@",receiverStr);
}


#pragma mark - Websocket
- (void)testWebsocket
{
    SRWebSocket * socket = [[SRWebSocket alloc] initWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"ws://123.207.167.163:9010/ajaxchattest"]]];
    socket.delegate = self;
    [socket open];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"连接成功，可以立刻登录你公司后台的服务器了，还有开启心跳");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"连接失败，这里可以实现掉线自动重连");
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"连接断开，清空socket对象，清空该清空的东西，还有关闭心跳！");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload
{
    NSLog(@"收到peng %@",pongPayload);
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"收到消息  %@",message);
}


#pragma mark -
- (void)testEHWebSocket
{
    self.view.backgroundColor = [UIColor redColor];
    
    
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 400, 300, 60)];
    btn.backgroundColor = [UIColor orangeColor];
    [btn setTitle:@"发送数据" forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(clickBtn4444) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    [[EHWebSocketManager shareManager] SRWebSocketOpenWithURLString:@"ws://123.207.167.163:9010/ajaxchattest"];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SRWebSocketDidOpen) name:kWebSocketDidOpenNote object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SRWebSocketDidClose) name:kWebSocketDidCloseNote object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(kWebSocketdidReceiveMessageNote:) name:kWebSocketDidCloseNote object:nil];
}

- (void)clickBtn4444
{
    NSString *msg = @"发送数据: 你好";
    [[EHWebSocketManager shareManager] sendData:msg];
}

- (void)SRWebSocketDidOpen
{
    NSLog(@"SRWebSocketDidOpen");
}

- (void)SRWebSocketDidClose
{
    NSLog(@"SRWebSocketDidClose");
}

- (void)kWebSocketdidReceiveMessageNote:(NSNotification *)info
{
    NSLog(@"kWebSocketdidReceiveMessageNote:%@",info.userInfo);
}

@end
