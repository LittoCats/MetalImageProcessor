//
//  MetalImageProcessor.h
//  MetalImageProcessor
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@class MetalImageBaseFilter;
@protocol MTLDevice;
@protocol MTLLibrary;
@protocol MTLCommandQueue;

NS_CLASS_AVAILABLE_IOS(8_0)
@interface MetalImageProcessor : NSObject

/**
 *  
 */
- (id)initWithCustomLibraryData:(NSData *)data;

/**
 *  设置源图像。源图像可能因为多次添加、移除滤镜而发生改变，如果需要重新从原始图像开始处理，需重新调用该方法
 */
- (void)generateSourceImage:(CGImageRef)imageRef;

/**
 *  添加一个滤镜
 *  @return bool 如果返回 NO, 说明 filter 正在被其它 Processor 使用
 *  @discussion 如果添加多个相同类型的filter，只有最后一个会被 Processor 记录，即只有最后一个被添加的起作用
 */
- (BOOL)addFilter:(MetalImageBaseFilter *)filter;

/**
 *  移除滤镜
 *  @param filter 将要移除的滤镜，若 filter 等于 nil，则移除所有滤镜
 *  @param afterRender 是否先渲染滤镜。NO , 则输出图像为剩余滤镜渲后的图像；YES，则提渲染该滤镜，并将结果作为原始图像。默认为 NO
 *  @return bool 如果返回 NO, 说明 filter 正在使用中，不能移除
 *  
 *  @discussion 渲染一个滤镜，需要的时间较短，因此该方法为同步执行。如果滤镜渲染需要较长时间，且 undo == NO ，可能会造成当前线程 wait 较长时间
 */
- (BOOL)removeFilter:(MetalImageBaseFilter *)filter afterRender:(BOOL)render;

/**
 *  提交滤镜效果
 *  @param handler 全部滤镜处理完成后，调用handler。handler 不在当前线程执行。imageRef 在 handler 执行完成后即被释放。
 */
- (void)commitWithCompleteHandler:(void (^)(CGImageRef imageRef))handler;

/**
 *  当 filter 设置发生变化时，需要调用该方法
 */
- (void)setNeedCommit;
@property (nonatomic, readonly, getter=isNeedCommit) BOOL needCommit;

@property (nonatomic, readonly) id<MTLDevice> device;
@property (nonatomic, readonly) id<MTLLibrary> library;
@property (nonatomic, readonly) id<MTLCommandQueue> commandQueue;

@end
