//
//  MetalImageGaussianBlurFilter.h
//  MetalImageProcessor
//
//  Created by 程巍巍 on 2/12/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "MetalImageBaseFilter.h"

@interface MetalImageGaussianBlurFilter : MetalImageBaseFilter

@property (nonatomic, assign) float radius; // Default value 0.0
@property (nonatomic, assign) float sigma;  // Default value 0.0

@end
