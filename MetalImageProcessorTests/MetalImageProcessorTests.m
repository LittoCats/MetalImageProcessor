//
//  MetalImageProcessorTests.m
//  MetalImageProcessorTests
//
//  Created by 程巍巍 on 15/2/12.
//  Copyright (c) 2015年 Littocats. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface MetalImageProcessorTests : XCTestCase

@end

@implementation MetalImageProcessorTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    
    printf("round : %f\n",round(10.5));
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
