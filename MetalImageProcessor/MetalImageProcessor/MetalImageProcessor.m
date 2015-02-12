//
//  MetalImageProcessor.m
//  MetalImageProcessor
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#import "MetailImageProcessor+Private.h"

@implementation MetalImageProcessor

- (id)init
{
    return [self initWithCustomLibraryData:nil];
}

- (id)initWithCustomLibraryData:(NSData *)data
{
    if (self = [super init]) {
        self.filterTable = [NSMapTable strongToStrongObjectsMapTable];
        self.excuteQueue = dispatch_queue_create([[NSString stringWithFormat:@"MetalImageProcessor_excuteQueue_%p",self] UTF8String], NULL);
        
        self.device = MTLCreateSystemDefaultDevice();
        
        if (data) {
            NSError *error;
            dispatch_data_t dispatch_data = dispatch_data_create([data bytes], data.length, _excuteQueue, DISPATCH_DATA_DESTRUCTOR_DEFAULT);
            self.library = [_device newLibraryWithData:dispatch_data error:&error];
            if (error) return nil;
        }else
            self.library = [_device newDefaultLibrary];
        
        self.commandQueue = [_device newCommandQueue];
    }
    return self;
}

- (void)generateSourceImage:(CGImageRef)imageRef
{
    NSUInteger width            = CGImageGetWidth(imageRef);
    NSUInteger height           = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace  = CGColorSpaceCreateDeviceRGB();
    uint8_t *rawData            = (uint8_t *)calloc(height * width * 4, sizeof(uint8_t));
    NSUInteger bytesPerPixel    = 4;
    NSUInteger bytesPerRow      = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef bitmapContext  = CGBitmapContextCreate(rawData, width, height,
                                                        bitsPerComponent, bytesPerRow, colorSpace,
                                                        kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(bitmapContext, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(bitmapContext);
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
                                                                                                 width:width
                                                                                                height:height
                                                                                             mipmapped:NO];
    id<MTLTexture> texture = [_device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, width, height);
    [texture replaceRegion:region mipmapLevel:0 withBytes:rawData bytesPerRow:bytesPerRow];
    free(rawData);
    
    self.sourceTexture = texture;
}

- (BOOL)addFilter:(MetalImageBaseFilter *)filter
{
    if (filter.processor) return NO;
    
    [self.filterTable setObject:filter forKey:[filter class]];
    filter.PROCESSOR = self;
    [filter updateState];
    
    [self setNeedCommit];
    
    return YES;
}

- (BOOL)removeFilter:(MetalImageBaseFilter *)filter afterRender:(BOOL)render
{
    if (filter.isBusy) return NO;
    filter = [self.filterTable objectForKey:[filter class]];
    if (render && filter) {
        // 如果
        self.inputTexture = self.sourceTexture;
        [self renderFilter:filter];
        self.sourceTexture = self.outputTexture;
        self.outputTexture = nil;
    }
    
    [self setNeedCommit];
    
    return YES;
}

- (void)commitWithCompleteHandler:(void (^)(CGImageRef))handler
{
    if (!handler || !self.isNeedCommit) return;
    
    uint64_t currentSerializeNo = ++_serializeNo;
    
    __weak typeof(self) weakself = self;
    
    dispatch_async(self.excuteQueue, ^{
        __strong typeof(weakself) strongself = weakself; if (!strongself || currentSerializeNo != strongself.serializeNo) return ;
        [strongself render:currentSerializeNo];
        [strongself callHandler:handler serializeNo:currentSerializeNo];
    });
}

- (void)render:(uint64_t)serializeNo
{
    // 队列中第一个滤镜渲染完成后，inputTexture 设为 nil ，后在的滤镜使用前面滤镜的 outputTexture 作为输入
    self.inputTexture = self.sourceTexture;
    
    // 把所有滤镜作务加入队列
    NSEnumerator *enumerator = [self.filterTable objectEnumerator];
    MetalImageBaseFilter *filter;
    __weak typeof(self) weakself = self;
    while (filter = [enumerator nextObject]) {
        filter.busy = YES;
        dispatch_async(self.excuteQueue, ^{
            __strong typeof(weakself) strongself = weakself; if (!strongself || serializeNo != strongself.serializeNo) return ;
            [strongself renderFilter:filter];
            filter.busy = NO;
        });
    }
}

- (void)callHandler:(void (^)(CGImageRef))handler serializeNo:(uint64_t)serializedNo
{
    __weak typeof(self) weakself = self;
    //提交输出任务
    dispatch_async(self.excuteQueue, ^{
        __strong typeof(weakself) strongself = weakself; if (!strongself || serializedNo != strongself.serializeNo) return ;
        
        id<MTLTexture> texture = strongself.outputTexture;
        CGImageRef imageRef = MTLTextureCreateCGImage(texture);
        handler(imageRef);
        CGImageRelease(imageRef);
    });
}

- (void)renderFilter:(MetalImageBaseFilter *)filter
{
    id<MTLTexture> inputTexture = self.inputTexture ?: self.outputTexture;     // 队列中第一个滤镜渲染完成后，inputTexture 设为 nil ，后在的滤镜使用前面滤镜的 outputTexture 作为输入
    
    if (!self.tempTexture ||
        [self.tempTexture width] != [inputTexture width] ||
        [self.tempTexture height] != [inputTexture height])
    {
        MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:[inputTexture pixelFormat]
                                                                                                     width:[inputTexture width]
                                                                                                    height:[inputTexture height]
                                                                                                 mipmapped:NO];
        self.tempTexture = [_device newTextureWithDescriptor:textureDescriptor];
    }
    
    MTLSize threadgroupCounts = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake([inputTexture width] / threadgroupCounts.width,
                                       [inputTexture height] / threadgroupCounts.height,
                                       1);
    
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    id<MTLComputeCommandEncoder> commandEncoder = [commandBuffer computeCommandEncoder];
    [commandEncoder setComputePipelineState:filter.pipeline];
    [commandEncoder setTexture:inputTexture atIndex:0];
    [commandEncoder setTexture:self.tempTexture atIndex:1];
    [filter configureArgumentTableWithCommandEncoder:commandEncoder];
    [commandEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadgroupCounts];
    [commandEncoder endEncoding];
    
    [commandBuffer commit];
    [commandBuffer waitUntilCompleted];
    
    // 将输出做为下一个滤镜的输入
    id temp = _outputTexture;
    self.outputTexture = _tempTexture;
    self.tempTexture = temp;
    self.inputTexture = nil;    // 队列中第一个滤镜渲染完成后，inputTexture 设为 nil ，后在的滤镜使用前面滤镜的 outputTexture 作为输入
}

- (void)setNeedCommit
{
    self.needCommit = YES;
}


// create image from MTLTexture
static CGImageRef MTLTextureCreateCGImage(id<MTLTexture> texture)
{
    //    NSAssert([texture pixelFormat] == MTLPixelFormatRGBA8Unorm, @"Pixel format of texture must be MTLPixelFormatBGRA8Unorm to create UIImage");
    if ([texture pixelFormat] != MTLPixelFormatRGBA8Unorm) {
        [NSException raise:@"Pixel format of texture must be MTLPixelFormatBGRA8Unorm to create UIImage" format:@""];
    }
    
    CGSize imageSize = CGSizeMake([texture width], [texture height]);
    size_t imageByteCount = imageSize.width * imageSize.height * 4;
    void *imageBytes = malloc(imageByteCount);
    NSUInteger bytesPerRow = imageSize.width * 4;
    MTLRegion region = MTLRegionMake2D(0, 0, imageSize.width, imageSize.height);
    [texture getBytes:imageBytes bytesPerRow:bytesPerRow fromRegion:region mipmapLevel:0];
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, imageBytes, imageByteCount, MBEReleaseDataCallback);
    int bitsPerComponent = 8;
    int bitsPerPixel = 32;
    CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
    CGImageRef imageRef = CGImageCreate(imageSize.width,
                                        imageSize.height,
                                        bitsPerComponent,
                                        bitsPerPixel,
                                        bytesPerRow,
                                        colorSpaceRef,
                                        bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        renderingIntent);
    
    CFRelease(provider);
    CFRelease(colorSpaceRef);
    
    return imageRef;
}

// memery manage
static void MBEReleaseDataCallback(void *info, const void *data, size_t size)
{
    free((void *)data);
}
@end
