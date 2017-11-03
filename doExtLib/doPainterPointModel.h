//
//  doPainterPointModel.h
//  Do_Test
//
//  Created by yz on 16/5/16.
//  Copyright © 2016年 DoExt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface doPainterPointModel : NSObject
@property (nonatomic,strong) UIColor *color;
@property (nonatomic,assign) CGFloat width;
@property (nonatomic,assign) CGMutablePathRef path;

@end
