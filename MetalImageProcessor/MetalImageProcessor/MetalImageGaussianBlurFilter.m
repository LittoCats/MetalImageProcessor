//
//  MetalImageGaussianBlurFilter.m
//  MetalImageProcessor
//
//  Created by 程巍巍 on 2/12/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "MetalImageGaussianBlurFilter.h"

@interface MetalImageGaussianBlurFilter ()

@property (nonatomic, strong) id<MTLTexture> blurWeightTexture;

@property (atomic, assign) BOOL needGenerateWeightexture;

@end

@implementation MetalImageGaussianBlurFilter

+ (NSString *)kernelFunctionName
{
    return @"gaussian_blur_2d";
}

- (void)configureArgumentTableWithCommandEncoder:(id<MTLComputeCommandEncoder>)commandEncoder
{
    if (self.needGenerateWeightexture){
        [self generateBlurWeightTexture];
    }
    
    [commandEncoder setTexture:self.blurWeightTexture atIndex:2];
}

- (id)init
{
    if (self = [super init]) {
        self.needGenerateWeightexture = YES;
    }
    return self;
}

- (void)setRadius:(float)radius
{
    _radius = radius;
    _sigma = radius / 2;
    self.needGenerateWeightexture = YES;
}

- (void)setSigma:(float)sigma
{
    _sigma = sigma;
    self.needGenerateWeightexture = YES;
}

- (void)generateBlurWeightTexture
{
    NSAssert(self.radius >= 0, @"Blur radius must be non-negative");
    
    const float radius = self.radius;
    const float sigma = self.sigma;
    const int size = (round(radius) * 2) + 1;
    
    float delta = 0;
    float expScale = 0;;
    if (radius > 0.0){
        delta = (radius * 2) / (size - 1);;
        expScale = -1 / (2 * sigma * sigma);
    }
    
    float *weights = malloc(sizeof(float) * size * size);
    
    float weightSum = 0;
    float y = -radius;
    for (int j = 0; j < size; ++j, y += delta){
        float x = -radius;
        
        for (int i = 0; i < size; ++i, x += delta){
            float weight = expf((x * x + y * y) * expScale);
            weights[j * size + i] = weight;
            weightSum += weight;
        }
    }
    
    const float weightScale = 1 / weightSum;
    for (int j = 0; j < size; ++j){
        for (int i = 0; i < size; ++i){
            weights[j * size + i] *= weightScale;
        }
    }
    
    MTLTextureDescriptor *textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatR32Float
                                                                                                 width:size
                                                                                                height:size
                                                                                             mipmapped:NO];
    
    self.blurWeightTexture = [self.processor.device newTextureWithDescriptor:textureDescriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, size, size);
    [self.blurWeightTexture replaceRegion:region mipmapLevel:0 withBytes:weights bytesPerRow:sizeof(float) * size];
    
    free(weights);
    self.needGenerateWeightexture = NO;
}

@end
