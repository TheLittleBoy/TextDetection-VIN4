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
    
    self.title = @"ð";
    self.view.backgroundColor = [UIColor whiteColor];

}

- (IBAction)startButtonAction:(id)sender {
    
    //
    VINDetectionViewController *vinVC = [[VINDetectionViewController alloc] init];
    vinVC.delegate = self;
    [self.navigationController pushViewController:vinVC animated:YES];
}

/**
 è¯å«æåä¹åï¼ç¹å»å®ææé®çåè°
 
 @param result VINç 
 */
- (void)recognitionComplete:(NSString *)result {
    
    NSLog(@"%@",result);
}


@end
