//
//  MetalImageSaturationAdjustFilter.m
//  MetalImageProcessor
//
//  Created by 程巍巍 on 2/12/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "MetalImageSaturationAdjustFilter.h"

struct AdjustSaturationUniforms{
    float saturationFactor;
};

@interface MetalImageSaturationAdjustFilter ()

@property (nonatomic, strong) id<MTLBuffer> uniformBuffer;

@end

@implementation MetalImageSaturationAdjustFilter

+ (NSString *)kernelFunctionName
{
    return @"adjust_saturation";
}

- (void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder
{
    struct AdjustSaturationUniforms uniforms;
    uniforms.saturationFactor = self.saturationFactor;
    
    if (!self.uniformBuffer)
    {
        self.uniformBuffer = [self.processor.device newBufferWithLength:sizeof(uniforms)
                                                              options:MTLResourceOptionCPUCacheModeDefault];
    }
    
    memcpy([self.uniformBuffer contents], &uniforms, sizeof(uniforms));
    
    [commandEncoder setBuffer:self.uniformBuffer offset:0 atIndex:0];
}

- (id)init
{
    if (self = [super init]) {
        self.saturationFactor = 1.0;
    }
    return self;
}

@end
