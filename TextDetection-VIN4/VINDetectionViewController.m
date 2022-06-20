//
//  VINDetectionViewController.m
//  TextDetection-VIN4
//
//  Created by Mac on 2022/6/20.
//

#import "VINDetectionViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Vision/Vision.h>

@interface VINDetectionViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    UILabel *textLabel;
    AVCaptureDevice *device;
    NSString *recognizedText;
    BOOL isFocus;
    BOOL isInference;
}
@property (nonatomic, assign) CGFloat m_width; //扫描框宽度
@property (nonatomic, assign) CGFloat m_higth; //扫描框高度
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureVideoDataOutput;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@property(nonatomic, strong) VNRecognizeTextRequest *textRecognitionRequest;
@end

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define m_scanViewY  250.0
#define m_scale [UIScreen mainScreen].scale

@implementation VINDetectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"扫一扫";
    self.view.backgroundColor = [UIColor whiteColor];    
    
    //给个默认值
    self.m_width = (SCREEN_WIDTH - 40);
    self.m_higth = 80.0;
    recognizedText = @"";
    
    //初始化
    [self initVNRecognizeTextRequest];
    
    //初始化摄像头
    [self initAVCaptureSession];
}

- (void)initVNRecognizeTextRequest {
    self.textRecognitionRequest = [[VNRecognizeTextRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        //
        NSArray<VNRecognizedTextObservation*> *result = [request results];
        for (VNRecognizedTextObservation *observation in result) {
            
            //取可信度最高的一个结果
            VNRecognizedText *candidate = [[observation topCandidates:1] firstObject];
            if (candidate) {
                
                NSString *elementText = candidate.string;
                
                //识别17位的VIN码
                if (elementText.length == 17 && candidate.confidence>0.8) {
                    //正则表达式，排除特殊字符
                    NSString *regex = @"[ABCDEFGHJKLMNPRSTUVWXYZ1234567890]{17}";
                    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
                    //识别成功
                    if ([test evaluateWithObject:elementText]) {

                        //连续两次识别结果一致，则输出最终结果
                        if ([self->recognizedText isEqualToString:elementText]) {

                            //播放音效
                            NSURL *url=[[NSBundle mainBundle]URLForResource:@"scanSuccess.wav" withExtension:nil];
                            SystemSoundID soundID=8787;
                            AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &soundID);
                            AudioServicesPlaySystemSound(soundID);
                            
                            //在屏幕上输入结果
                            dispatch_async(dispatch_get_main_queue(), ^{
                                self->textLabel.text = elementText;
                            });
                            
                            NSLog(@"%@",elementText);
                        
                            //停止扫描
                            [self.session stopRunning];
                        
                        }else
                        {
                            //马上再识别一次，对比结果
                            self->recognizedText = elementText;
                            self->isInference = NO;
                        }
                        return;
                    }
                }
            }
        }
    }];
    
    self.textRecognitionRequest.recognitionLevel = VNRequestTextRecognitionLevelAccurate; //精确的
    self.textRecognitionRequest.usesLanguageCorrection = NO;    //禁用语言更正，更具性能优势
}

- (void)initAVCaptureSession{
    
    self.session = [[AVCaptureSession alloc] init];
    NSError *error;
    
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"%@",error);
    }
    
    //输出流
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* value = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA];
    NSDictionary* videoSettings = [NSDictionary
                                   dictionaryWithObject:value forKey:key];
    self.captureVideoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureVideoDataOutput setVideoSettings:videoSettings];
    
    dispatch_queue_t queue;
    queue = dispatch_queue_create("cameraQueue", NULL);
    [self.captureVideoDataOutput setSampleBufferDelegate:self queue:queue];
    
    if ([self.session canAddInput:self.videoInput]) {
        [self.session addInput:self.videoInput];
    }
    if ([self.session canAddOutput:self.captureVideoDataOutput]) {
        [self.session addOutput:self.captureVideoDataOutput];
    }
    
    AVCaptureConnection* connection = [self.captureVideoDataOutput connectionWithMediaType:AVMediaTypeVideo];
    connection.videoOrientation = AVCaptureVideoOrientationPortrait;
    
    //输出照片铺满屏幕
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.session.sessionPreset = AVCaptureSessionPresetHigh;
    }
    
    //初始化预览图层
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    if (orientation == UIInterfaceOrientationPortrait) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
        
    }
    else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
    }
    else if (orientation == UIInterfaceOrientationLandscapeRight) {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
    }
    else {
        [[self.previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
    }
    
    self.previewLayer.frame = CGRectMake(0,0, SCREEN_WIDTH,SCREEN_HEIGHT);
    
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    self.view.layer.masksToBounds = YES;
    [self.view.layer addSublayer:self.previewLayer];
    
    //扫描框
    [self initScanView];
    
    //扫描结果label
    textLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, (SCREEN_HEIGHT - 100)/2.0, SCREEN_WIDTH, 100)];
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.numberOfLines = 0;
    
    textLabel.font = [UIFont systemFontOfSize:19];
    
    textLabel.textColor = [UIColor colorWithRed:1.00 green:0.50 blue:0.00 alpha:1.00];
    [self.view addSubview:textLabel];
    
    //完成按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.view addSubview:button];
    button.frame = CGRectMake((SCREEN_WIDTH - 100)/2.0, SCREEN_HEIGHT - 164, 100, 50);
    [button setTitle:@"完成" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(clickedFinishBtn:) forControlEvents:UIControlEventTouchUpInside];
    
    //对焦
    int flags =NSKeyValueObservingOptionNew;
    [device addObserver:self forKeyPath:@"adjustingFocus" options:flags context:nil];
}

- (void)initScanView
{
    // 中间空心洞的区域
    CGRect cutRect = CGRectMake((SCREEN_WIDTH - _m_width)/2.0,m_scanViewY, _m_width, _m_higth);
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:CGRectMake(0,0, SCREEN_WIDTH,SCREEN_HEIGHT)];
    // 挖空心洞 显示区域
    UIBezierPath *cutRectPath = [UIBezierPath bezierPathWithRect:cutRect];
    
    //将circlePath添加到path上
    [path appendPath:cutRectPath];
    path.usesEvenOddFillRule = YES;
    
    CAShapeLayer *fillLayer = [CAShapeLayer layer];
    fillLayer.path = path.CGPath;
    fillLayer.fillRule = kCAFillRuleEvenOdd;
    fillLayer.opacity = 0.6;//透明度
    fillLayer.backgroundColor = [UIColor blackColor].CGColor;
    [self.view.layer addSublayer:fillLayer];
    
    // 边界校准线
    CGFloat lineWidth = 2;
    CGFloat lineLength = 20;
    UIBezierPath *linePath = [UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                         cutRect.origin.y - lineWidth,
                                                                         lineLength,
                                                                         lineWidth)];
    //追加路径
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width - lineLength + lineWidth,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineLength,
                                                                     lineWidth)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width ,
                                                                     cutRect.origin.y - lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height - lineLength + lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x - lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height,
                                                                     lineLength,
                                                                     lineWidth)]];
    
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width,
                                                                     cutRect.origin.y + cutRect.size.height - lineLength + lineWidth,
                                                                     lineWidth,
                                                                     lineLength)]];
    [linePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(cutRect.origin.x + cutRect.size.width - lineLength + lineWidth,
                                                                     cutRect.origin.y + cutRect.size.height,
                                                                     lineLength,
                                                                     lineWidth)]];
    
    CAShapeLayer *pathLayer = [CAShapeLayer layer];
    pathLayer.path = linePath.CGPath;// 从贝塞尔曲线获取到形状
    pathLayer.fillColor = [UIColor colorWithRed:0. green:0.655 blue:0.905 alpha:1.0].CGColor; // 闭环填充的颜色
    [self.view.layer addSublayer:pathLayer];
    
    UILabel *tipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, m_scanViewY - 40, SCREEN_WIDTH, 25)];
    [self.view addSubview:tipLabel];
    tipLabel.text = @"请对准VIN码进行扫描";
    tipLabel.textAlignment = NSTextAlignmentCenter;
    tipLabel.textColor = [UIColor whiteColor];
}

-(void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context {
    if([keyPath isEqualToString:@"adjustingFocus"]){
        BOOL adjustingFocus =[[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];
        isFocus = adjustingFocus;
        NSLog(@"Is adjusting focus? %@", adjustingFocus ?@"YES":@"NO");
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    //
    if (!isFocus && !isInference) {
        isInference = YES;
        
        //直接去识别
        NSError *error;
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCVPixelBuffer:pixelBuffer options:@{}];
        [handler performRequests:@[self.textRecognitionRequest] error:&error];
        if (error) {
            NSLog(@"%@",error);
        }

        //延迟100毫秒再继续识别下一次，降低CPU功耗，省电‼️
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(50 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            //继续识别
            self->isInference = NO;
        });
    }
}

- (void)viewWillAppear:(BOOL)animated{
    
    [super viewWillAppear:YES];
    
    if (self.session) {
        [self.session startRunning];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:YES];
    
    if (self.session) {
        [self.session stopRunning];
    }
    
    [device removeObserver:self forKeyPath:@"adjustingFocus" context:nil];
}

/**
 完成按钮点击事件

 @param sender 按钮
 */
- (void)clickedFinishBtn:(UIButton *)sender {
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(recognitionComplete:)]) {
        [self.delegate recognitionComplete:textLabel.text];
    }
    
    [self.navigationController popViewControllerAnimated:YES];
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
