//
//  MetalImageSaturationAdjustFilter.h
//  MetalImageProcessor
//
//  Created by 程巍巍 on 2/12/15.
//  Copyright (c) 2015 Littocats. All rights reserved.
//

#import "MetalImageBaseFilter.h"

@interface MetalImageSaturationAdjustFilter : MetalImageBaseFilter

@property (nonatomic, assign) float saturationFactor; // Default 1.0

@end
