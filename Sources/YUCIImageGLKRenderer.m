//
//  YUCIImageGLKRender.m
//  CoreImageView
//
//  Created by YuAo on 2/24/16.
//  Copyright © 2016 YuAo. All rights reserved.
//

#import "YUCIImageGLKRenderer.h"

#if __has_include(<GLKit/GLKView.h>)

@interface YUCIImageGLKRenderer () <GLKViewDelegate, GLKViewControllerDelegate>

@property (nonatomic,strong) EAGLContext *GLContext;

@property (nonatomic,strong) GLKView *view;

@property (nonatomic,strong) CIImage *image;

@property (nonatomic, assign) BOOL inactive;
@property (nonatomic, assign) BOOL background;

@end

@implementation YUCIImageGLKRenderer

@synthesize context = _context;

- (instancetype)initWithEAGLContext:(EAGLContext *)GLContext {
    if (self = [super init]) {
        if (!GLContext) {
            GLContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        }
        CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
        self.context = [CIContext contextWithEAGLContext:GLContext
                                                 options:@{kCIContextWorkingColorSpace: CFBridgingRelease(colorSpaceRef)}];
        self.view = [[GLKView alloc] initWithFrame:CGRectZero context:GLContext];
        self.view.delegate = self;
        self.view.contentScaleFactor = UIScreen.mainScreen.scale;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(becomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.view.delegate = nil;
    self.view = nil;
    if ([NSThread isMainThread])
    {
        [EAGLContext setCurrentContext:nil];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [EAGLContext setCurrentContext:nil];
        });
    }
}

- (void)resignActive
{
    self.inactive = YES;
}

- (void)enterBackground
{
    self.background = YES;
}

- (void)willEnterForeground
{
    self.background = NO;
}

- (void)becomeActive
{
    self.inactive = NO;
}

- (instancetype)init {
    return [self initWithEAGLContext:nil];
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    if (self.inactive || self.background)
    {
        return;
    }
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    if (self.image)
    {
        [self.context drawImage:self.image inRect:(CGRect){CGPointZero,CGSizeApplyAffineTransform(rect.size, CGAffineTransformMakeScale(self.view.contentScaleFactor, self.view.contentScaleFactor))} fromRect:self.image.extent];
    }
}

- (void)renderImage:(CIImage *)image {
    if (self.inactive || self.background)
    {
        return;
    }
    self.image = image;
    [self.view setNeedsDisplay];
}

@end

#endif
