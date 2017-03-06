//
//  ViewController.m
//  HHDownload
//
//  Created by aurorac on 2017/3/6.
//  Copyright © 2017年 xiaomaolv. All rights reserved.
//

#import "ViewController.h"
#define KfileName @"123.mp4"

@interface ViewController ()<NSURLSessionDataDelegate>

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (strong, nonatomic) UIProgressView *progress;
/** currentsize */
@property (nonatomic, assign) NSInteger currentSize;
@property (nonatomic, assign) NSInteger totalSize;
/** dataTask */
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
/** outPutStream */
@property (nonatomic, strong) NSOutputStream *outPutStream;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button setTitle:@"开始" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor cyanColor];
    button.frame = CGRectMake(100, 100, 100, 40);
    [button addTarget:self action:@selector(start) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *suspendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [suspendButton setTitle:@"暂停" forState:UIControlStateNormal];
    suspendButton.backgroundColor = [UIColor cyanColor];
    suspendButton.frame = CGRectMake(100, 200, 100, 40);
    [suspendButton addTarget:self action:@selector(suspend) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:suspendButton];
    
    UIButton *continueButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [continueButton setTitle:@"继续" forState:UIControlStateNormal];
    continueButton.backgroundColor = [UIColor cyanColor];
    continueButton.frame = CGRectMake(100, 300, 100, 40);
    [continueButton addTarget:self action:@selector(continueDownload) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:continueButton];

    self.progress = [[UIProgressView alloc] initWithFrame:CGRectMake(30, 400, 300, 30)];
    [self.view addSubview:self.progress];
}

- (void)start{
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    
    //确定是否存在已经下载的文件,如存在,继续下载.
    self.currentSize = [self getSize];
    
    //new dataTask
    NSURL *url = [NSURL URLWithString:@"http://120.25.226.186:32812/resources/videos/minion_02.mp4"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    
    //设置请求头信息
    NSString *header = [NSString stringWithFormat:@"bytes=%zd-",self.currentSize];
    [request setValue:header forHTTPHeaderField:@"Range"];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request];
    self.dataTask = dataTask;
    
    [self.dataTask resume];
}
- (void)suspend{
    [self.dataTask suspend];
}


- (void)continueDownload{
    [self.dataTask resume];
}

#pragma mark methods
- (NSInteger)getSize{
    //0.拼接文件全路径
    NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:KfileName];
    NSLog(@"fullPath  %@",fullPath);
    //先把沙盒中的文件大小取出来
    NSDictionary *dict = [[NSFileManager defaultManager]attributesOfItemAtPath:fullPath error:nil];
    NSInteger size = [[dict objectForKey:@"NSFileSize"]integerValue];
    return size;
}

#pragma mark -------------------------------
#pragma mark NSURLSessionDataDelegate

- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    //此处注意,不设置为allow,其它delegate methods将不被执行
    completionHandler(NSURLSessionResponseAllow);
    
    self.totalSize = response.expectedContentLength + self.currentSize;
    
    //0.拼接文件全路径
    
    NSString *fullPath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:KfileName];
    
    //1.创建输出流
    NSOutputStream *outPutStream = [NSOutputStream outputStreamToFileAtPath:fullPath append:YES];
    [outPutStream open];
    self.outPutStream = outPutStream;
}

//2.当接受到服务器返回的数据的时候调用,会调用多次
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data{
    
    self.currentSize += data.length;
    CGFloat rate = 1.0 * self.currentSize / self.totalSize;
    self.progress.progress = rate;
    self.label.text = [NSString stringWithFormat:@"%.2f", rate];
    [self.outPutStream write:data.bytes maxLength:data.length];
    
}

//3.当整个请求结束的时候调用,error有值的话,那么说明请求失败
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    
    [self.outPutStream close];
    self.outPutStream = nil;
}

@end
