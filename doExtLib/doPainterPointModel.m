//
//  doPainterPointModel.m
//  Do_Test
//
//  Created by yz on 16/5/16.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import "doPainterPointModel.h"

@implementation doPainterPointModel
- (void)dealloc {
    CGPathRelease(_path);
}

- (void)setPath:(CGMutablePathRef)path {
    if (_path != path) {
        _path = (CGMutablePathRef)CGPathRetain(path);
    }
}
@end
