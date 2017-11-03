//
//  do_PainterView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_PainterView_IView <NSObject>

@required
//属性方法
- (void)change_brushColor:(NSString *)newValue;
- (void)change_brushWidth:(NSString *)newValue;

//同步或异步方法
- (void)clear:(NSArray *)parms;
- (void)saveAsBitmap:(NSArray *)parms;
- (void)saveAsImage:(NSArray *)parms;
- (void)undo:(NSArray *)parms;

@end