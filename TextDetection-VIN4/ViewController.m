//
//  ViewController.m
//  TextDetection-VIN4
//
//  Created by Mac on 2022/6/20.
//

#import "ViewController.h"
#import "VINDetectionViewController.h"

@interface ViewController ()<VINDetectionViewControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"🚗";
    self.view.backgroundColor = [UIColor whiteColor];

}

- (IBAction)startButtonAction:(id)sender {
    
    //
    VINDetectionViewController *vinVC = [[VINDetectionViewController alloc] init];
    vinVC.delegate = self;
    [self.navigationController pushViewController:vinVC animated:YES];
}

/**
 识别成功之后，点击完成按钮的回调
 
 @param result VIN码
 */
- (void)recognitionComplete:(NSString *)result {
    
    NSLog(@"%@",result);
}


@end
