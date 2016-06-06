//
//  ESGLView.h
//  kxmovie
//
//  Created by Kolyvan on 22.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import <UIKit/UIKit.h>
#include <sys/types.h>

#ifndef YUV_FRAME_
#define YUV_FRAME_

typedef struct
{
    uint8_t *luma;
    uint8_t *chromaB;
    uint8_t *chromaR;
    
    int lz, bz,rz;
    int width, height;
    
    int gray;
    
    pthread_rwlock_t mutex;
    
} VideoFrameYUV;

#endif

@protocol KxMovieGLRenderer
- (BOOL) isValid;
//Shaders

- (NSString *) YUVFragmentShader;
- (NSString *) passThroughFragmentShader;
- (NSString *) zoomShader;
- (NSString *) distorsionFragmentShader;


//- (void) resolveUniforms: (GLuint) program;
- (void) resolveUniformsYUVConversionProgram: (GLuint) program;


- (void) setFrame: (VideoFrameYUV *) frame;
- (void)adjustSize;
- (BOOL) prepareRenderYUV;
@end


@interface MovieGLView : UIView
{
    EAGLContext     *_context;
    
    // Framebuffers

//    GLuint          _offscreenFramebuffer;
    GLuint          YUVConversionOutputFramebuffer;
    GLuint          zoomOutputFramebuffer;
    GLuint          trackingFramebuffer; // final result which will contain the texture used by tracker
    GLuint          distorsionOutputFramebuffer;
    
    GLuint          _offscreenFramebuffer2; // for zoom
    GLuint          displayFramebuffer; // Display
    GLuint          displayRenderbuffer;
    
    //textures
    GLuint          YUV_offscreenRenderTexture;
    GLuint          zoomOffscreenRenderTexture;
    GLuint          trackingOffscreenRenderTexture;
    GLuint          distorsionOffscreenRenderTexture;
    GLuint          _offscreenRenderTexture2; // for zoom 
    
    GLuint          _renderbuffer;
    GLint           _backingWidth;
    GLint           _backingHeight;
    //Programs

    
    GLuint          yuvConversionProgram;
    GLuint          passThroughProgram;
    GLuint          zoomProgram;
    GLuint          distorsionProgram;
    
    GLint           renderedTextureUniformSampler;
    GLint           zoomTextureUniformSampler;
    GLint           distorsionInputTextureUniformSampler;
    GLint           passthroughInputTextureUniformSampler;

    
    GLint   centerZoomUniform, scaleUniform, zoomFlipYUniform;
    GLint passthroughFlipUniform;
    
    // Distorsion program stuff
    GLuint          LUTTextures[6];
    GLint           LUTTextureUniform[6];
    UIImage         *inputImage[6];
    GLubyte         *imageData [6];
    CGFloat widthOfImage;
    CGFloat heightOfImage;
    
    GLint           _uniformMatrix;
    GLfloat         _vertices[8];
    
    //core video Texture cache 
    CVOpenGLESTextureCacheRef coreVideoTextureCache;
    CVPixelBufferRef renderTarget;
    CVPixelBufferRef zoomRenderTarget;
    CVPixelBufferRef trackingRenderTarget;
    CVPixelBufferRef distorsionRenderTarget;
    
    CVPixelBufferRef renderTarget2;
    CVOpenGLESTextureRef renderTexture;
    CVOpenGLESTextureRef zoomRenderTexture;
    CVOpenGLESTextureRef trackingRenderTexture;
    CVOpenGLESTextureRef distorsionRenderTexture;
    
    CVOpenGLESTextureRef renderTexture2;
    
    // output texture
    uint8_t *_rawBytesForImage;
    int frameNumber;
    // CMTime ????
    
    int imageWidth;//1280
    int imageHeight;//720
    
    int trackingImageWidth;
    int trackingImageHeight;
    
    
    float _width;
    float _height;
    int _flag;
    id<KxMovieGLRenderer> _renderer;
}

@property BOOL isMovieWritingPaused;
@property BOOL Distort;
@property BOOL zoomEnabled;
@property BOOL zoomForTrackingEnabled;
@property(readwrite, nonatomic) CGFloat zoomScale;
@property(readwrite,nonatomic) CGFloat targetZoomScale;
@property(readwrite,nonatomic) CGFloat zoomSpeed;
@property(readwrite, nonatomic) CGPoint centerZoom;

@property (nonatomic,strong) UIImageView* maskImage;

- (id)initWithFrame:(CGRect)frame;

- (void)render: (VideoFrameYUV *) frame;

- (void)finish;

- (void)adjustSize;

@end
