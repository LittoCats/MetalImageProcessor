//
//  MetailImageProcessor+Private.h
//  MetalImageProcessor
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#ifndef MetalImageProcessor_MetailImageProcessor_Private_h
#define MetalImageProcessor_MetailImageProcessor_Private_h

#import "MetalImageProcessor.h"
#import "MetalImageBaseFilter.h"

#import <Metal/Metal.h>

@interface MetalImageProcessor ()

// MTL
@property (strong) id<MTLDevice> device;
@property (strong) id<MTLLibrary> library;
@property (strong) id<MTLCommandQueue> commandQueue;

/**
 *  @sourceTexture  原始图像资源，只有在移除 filter ，并应用 filter 的效果时，将使 sourceTexture ＝ outputTexture， 并设置 outputTextture 为 nil
 *  @inputTexture   commit 时，渲染的输入图像，当其为 nil 时，直接将当前的 outputTexture 设置为 inputTexture。在 commit 开始时，将其设置为 sourceTexture
 *  @tempTexture    渲染的输出图像，当一个 filter  渲染完成后，将其与 outputTexture 互换
 *  @outputText     processor 的输出图像，
 */
@property (strong) id<MTLTexture> sourceTexture;
@property (strong) id<MTLTexture> inputTexture;
@property (strong) id<MTLTexture> tempTexture;
@property (strong) id<MTLTexture> outputTexture;

// filter 管理
@property (nonatomic, strong) NSMapTable *filterTable;

// processor  滤镜的执行队列
@property (nonatomic, strong) dispatch_queue_t excuteQueue;
@property (nonatomic, assign, getter=isNeedCommit) BOOL needCommit;

/**
 *  serializeNo 在 commit 时自增 1 ，提交 block 任务时，block 会捕获当前的 serializeNo,当提交的任务在串行队列中执行时，检查捕获的 serializeNo 与 processor 当前的serializeNo 时否相等，不相等，则直接返回，不再执行后面的代码。由于同一次提交的任务捕获的 serializeNo 相同，因此当 serializeNo 改变时，相当于取消了已提交的渲染任务
 */
@property (nonatomic, assign) uint64_t serializeNo;

@end

@interface MetalImageBaseFilter ()

@property (nonatomic, strong) id<MTLComputePipelineState> pipeline;
@property (nonatomic, strong) id<MTLFunction> kernelFunction;

@property (nonatomic, assign, getter=isBusy) BOOL busy;
@property (nonatomic, weak) MetalImageProcessor *PROCESSOR;

- (void)updateState;

@end

#endif
