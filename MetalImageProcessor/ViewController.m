//
//  ViewController.m
//  MetalImageProcessor
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#import "ViewController.h"

#import "MetalImageProcessor.h"
#import "MetalImageSaturationAdjustFilter.h"
#import "MetalImageGaussianBlurFilter.h"

@interface ViewController ()

@property (nonatomic, strong) MetalImageProcessor *processor;
@property (nonatomic, strong) MetalImageSaturationAdjustFilter *saturationFilter;
@property (nonatomic, strong) MetalImageGaussianBlurFilter *gaussianBlurFilter;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.view.layer.contents = (__bridge id)([[UIImage imageNamed:@"IMG_0001.JPG"] CGImage]);
    
    UISlider *slider = [[UISlider alloc] initWithFrame:CGRectMake(64, 64, 256, 32)];
    slider.tag = 0;
    slider.maximumValue = 3.0;
    [slider setValue:1];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];
    
    UISlider *slider0 = [[UISlider alloc] initWithFrame:CGRectMake(64, 128, 256, 32)];
    slider0.tag = 1;
    slider0.maximumValue = 7.0;
    [slider0 setValue:1];
    [slider0 addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider0];
    
    
    self.processor = [[MetalImageProcessor alloc] init];
    [self.processor generateSourceImage:[[UIImage imageNamed:@"IMG_0001.JPG"] CGImage]];
    
    self.saturationFilter = [[MetalImageSaturationAdjustFilter alloc] init];
    [self.processor addFilter:_saturationFilter];
    
    self.gaussianBlurFilter = [[MetalImageGaussianBlurFilter alloc] init];
    [self.processor addFilter:_gaussianBlurFilter];
}

- (void)sliderValueChanged:(UISlider *)slider
{
    if (slider.tag == 0) _saturationFilter.saturationFactor = slider.value;
    if (slider.tag == 1) _gaussianBlurFilter.radius = slider.value;
    [self.processor commitWithCompleteHandler:^(CGImageRef imageRef) {
        CGImageRetain(imageRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.view.layer.contents = (__bridge id)(imageRef);
            CGImageRelease(imageRef);
        });
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

FOUNDATION_EXPORT void ELog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
void ELog(NSString *format, ... ){
    va_list vl;
    va_start(vl, format);
    printf("%s\n",[[[NSString alloc] initWithFormat:format arguments:vl] UTF8String]);
    va_end(vl);
}

