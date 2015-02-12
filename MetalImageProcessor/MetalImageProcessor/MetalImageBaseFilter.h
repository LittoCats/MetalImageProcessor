//
//  MetalImageBaseFilter.h
//  MetalImageProcessor
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//
//  abstract 该类不能直接实例化

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#import "MetalImageProcessor.h"

NS_AVAILABLE_IOS(8_0)
@interface MetalImageBaseFilter : NSObject

@property (nonatomic, readonly) MetalImageProcessor *processor;
@property (nonatomic, readonly) id<MTLComputePipelineState> pipeline;
@property (nonatomic, readonly) id<MTLFunction> kernelFunction;

@property (atomic, readonly, getter=isBusy) BOOL busy;

/**
 *  abstract 子类必须实现该法。
 *  @discussion commandEncoder 中第一个 texture 为输入图像(inputTexture) , 第二个 texture 为输出图像(outputTexture)
 */
- (void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder;

/**
 *  abstract 子类必须实现该法。
 */
+ (NSString *)kernelFunctionName;
@end
