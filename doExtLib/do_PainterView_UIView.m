//
//  do_PainterView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_PainterView_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doPainterPointModel.h"
#import "doJsonHelper.h"
#import "doMultitonModule.h"
#import "DoScriptEngineHelper.h"
#import "doIOHelper.h"
#import "doIBitmap.h"
#import "doEventCenter.h"

@interface do_PainterView_UIView()
{
    UIColor *_lineColor;
    CGFloat _lineWidth;
    CGMutablePathRef path;
    NSMutableArray *pathModalArray;
}

@end

@implementation do_PainterView_UIView
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    pathModalArray = [NSMutableArray array];
    //默认值处理
    _lineColor = [doUIModuleHelper GetColorFromString:[_model GetProperty:@"brushColor"].DefaultValue:[UIColor clearColor]];
    _lineWidth = [[_model GetProperty:@"brushWidth"].DefaultValue floatValue];
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    pathModalArray = nil;
    path = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_brushColor:(NSString *)newValue
{
    //自己的代码实现
    UIColor *color = [doUIModuleHelper GetColorFromString:newValue :[UIColor clearColor]];
    _lineColor = color;
}
- (void)change_brushWidth:(NSString *)newValue
{
    //自己的代码实现
    CGFloat width = [newValue floatValue];
    _lineWidth = width;
}
#pragma -mark view的方法

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, p.x, p.y);
    doInvokeResult* _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_model.EventCenter FireEvent:@"touch":_invokeResult];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint p = [touch locationInView:self];
    
    //点加至线上
    CGPathAddLineToPoint(path, NULL, p.x, p.y);
    //移动->重新绘图
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    doPainterPointModel *modal = [[doPainterPointModel alloc] init];
    modal.color = _lineColor;
    modal.width = _lineWidth;
    modal.path = path;
    
    [pathModalArray addObject:modal];
    CGPathRelease(path);
    path = nil;
    doInvokeResult* _invokeResult = [[doInvokeResult alloc]init:_model.UniqueKey];
    [_model.EventCenter FireEvent:@"touchUp":_invokeResult];
}

- (void)drawRect:(CGRect)rect {
    for (doPainterPointModel *modal in pathModalArray) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        [modal.color setStroke];
        CGContextSetLineWidth(context, modal.width);
        CGContextAddPath(context, modal.path);
        
        CGContextDrawPath(context, kCGPathStroke);
    }
    
    if (path != nil) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextAddPath(context, path);
        
        [_lineColor setStroke];
        CGContextSetLineWidth(context, _lineWidth);
        
        CGContextDrawPath(context, kCGPathStroke);
        
    }
}

- (void)undoAction {
    [pathModalArray removeLastObject];
    [self setNeedsDisplay];
}
- (void)clearAction {
    [pathModalArray removeAllObjects];
    [self setNeedsDisplay];
}
#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)clear:(NSArray *)parms
{
    [self clearAction];
}
- (void)undo:(NSArray *)parms
{
    [self undoAction];
}
//异步
- (void)saveAsBitmap:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    
    //自己的代码实现
    NSString *bitmapAddress = [doJsonHelper GetOneText:_dictParas :@"bitmap" :@""];
    
    UIImage *img = [self getImageFromView:self];
    
    doMultitonModule *_multitonModule = [doScriptEngineHelper ParseMultitonModule:_scritEngine :bitmapAddress];
    
    id<doIBitmap> bitmap = (id<doIBitmap>)_multitonModule;
    [bitmap setData:img];
    
    NSString *_callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    //_invokeResult设置返回值
    [_scritEngine Callback:_callbackName :_invokeResult];
}
- (void)saveAsImage:(NSArray *)parms
{
    //异步耗时操作，但是不需要启动线程，框架会自动加载一个后台线程处理这个函数
    NSDictionary *_dictParas = [parms objectAtIndex:0];
    //参数字典_dictParas
    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    //自己的代码实现
    NSString *format = @"JPEG";
    format = [doJsonHelper GetOneText:_dictParas :@"format" :@"JPEG"];
    if ([format compare:@"PNG" options:NSCaseInsensitiveSearch] == NSOrderedSame) {
        format = @"PNG";
    }
    else
    {
        format = @"JPEG";
    }
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",[doUIModuleHelper stringWithUUID],format];
    NSString *defaultPath = [NSString stringWithFormat:@"data://temp/do_PainterView/%@",fileName];
    NSString *parmsPath = [doJsonHelper GetOneText:_dictParas :@"outPath" :defaultPath];
    NSString *tempPath = [parmsPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if(tempPath.length == 0)
    {
        parmsPath = defaultPath;
    }
    NSInteger quality = [doJsonHelper GetOneInteger:_dictParas :@"quality" :100];
    //从view保存为image
    UIImage *img = [self getImageFromView:self];
    
    NSData *imageData;
    
    if ([format isEqualToString:@"PNG"])
    {
        imageData = UIImagePNGRepresentation(img);
    }
    else
    {
        imageData = UIImageJPEGRepresentation(img, quality);
    }
    NSString *filePath =  [doIOHelper GetLocalFileFullPath:_scritEngine.CurrentApp :parmsPath];
    NSString *dicPath = [filePath stringByDeletingLastPathComponent];
    //文件夹不存在，创建
    if (![doIOHelper ExistDirectory:dicPath]) {
        [doIOHelper CreateDirectory:dicPath];
    }
    
    NSLog(@"saveFilePath = %@",filePath);
    [imageData writeToFile:filePath atomically:YES];
    
    NSString *_callbackName = [parms objectAtIndex:2];
    //回调函数名_callbackName
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init];
    //_invokeResult设置返回值
    [_invokeResult SetResultText:parmsPath];
    [_scritEngine Callback:_callbackName :_invokeResult];
}
- (UIImage *)getImageFromView:(UIView *)view
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size,NO,0);
    CGContextRef ctx= UIGraphicsGetCurrentContext();
    [view.layer renderInContext:ctx ];
    //3从上下文当中生成一张图片
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    //4.关闭上下文
    UIGraphicsEndImageContext();
    return newImage;
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
