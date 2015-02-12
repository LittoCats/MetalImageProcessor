//
//  MetalImageBaseFilter.m
//  MetalImageProcessor
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//
//  

#import "MetalImageBaseFilter.h"
#import "MetailImageProcessor+Private.h"

@implementation MetalImageBaseFilter

+ (id)alloc
{
    return [self kernelFunctionName] ? [super alloc] : nil;
}

- (void)updateState
{
    NSError *error;
    self.kernelFunction = [self.processor.library newFunctionWithName:[[self class] kernelFunctionName]];
    self.pipeline = [self.processor.device newComputePipelineStateWithFunction:_kernelFunction error:&error];
    if (!_pipeline)
        [NSException raise:[NSString stringWithFormat:@"Error occurred when building compute pipeline for function %@", [_kernelFunction name]] format:@""];
}

- (MetalImageProcessor *)processor
{
    return self.PROCESSOR;
}

+ (NSString *)kernelFunctionName
{
    return nil;
}

- (void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder
{
    
}

@end
