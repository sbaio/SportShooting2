//
//  KxMovieGLView.m
//  kxmovie
//
//  Created by Kolyvan on 22.10.12.
//  Copyright (c) 2012 Konstantin Boukreev . All rights reserved.
//
//  https://github.com/kolyvan/kxmovie
//  this file is part of KxMovie
//  KxMovie is licenced under the LGPL v3, see lgpl-3.0.txt

#import "MovieGLView.h"
#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#include <pthread.h>
//#import "Tracker.h"
#import "MovieWriter.h"

#import "DVFloatingWindow.h"

//#import "UtilsHelper.h"

//////////////////////////////////////////////////////////

#pragma mark - shaders

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)
#define sign(a) ( ( (a) < 0 )  ?  -1   : ( (a) > 0 ) )
#define bindBetween(a,b,c) ((a > c) ? c: ((a<b)? b:a))

NSString *const vertexShaderString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec2 texcoord;
 uniform mat4 modelViewProjectionMatrix;
 varying vec2 v_texcoord;
 
 void main()
 {
     gl_Position = modelViewProjectionMatrix * position;
     v_texcoord = texcoord.xy;
 }
);

NSString *const rgbFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture;
 
 void main()
 {
     gl_FragColor = texture2D(s_texture, v_texcoord);
 }
);

NSString *const yuvFragmentShaderString = SHADER_STRING
(
 varying highp vec2 v_texcoord;
 uniform sampler2D s_texture_y;
 uniform sampler2D s_texture_u;
 uniform sampler2D s_texture_v;
 void main()
 {
     highp vec2 coord1 = vec2(v_texcoord.x,1.0 -v_texcoord.y);
     
     highp float y = texture2D(s_texture_y, coord1).r * 1.0;
     highp float u = texture2D(s_texture_u, coord1).r - 0.5;
     highp float v = texture2D(s_texture_v, coord1).r - 0.5;
//
//     highp float y = texture2D(s_texture_y, v_texcoord).r * 1.0;
//     highp float u = texture2D(s_texture_u, v_texcoord).r - 0.5;
//     highp float v = texture2D(s_texture_v, v_texcoord).r - 0.5;
     
     highp float r = y +             1.402 * v;
     highp float g = y - 0.344 * u - 0.714 * v;
     highp float b = y + 1.772 * u;
     
//     highp float l = r * 0.2125 + g * 0.7154 + b * 0.0721;  //luminance
//     highp float s = -0.5; //sarturation
//     gl_FragColor = vec4( (r*(1.0-s)+l*s), (g*(1.0-s)+l*s), (b*(1.0-s)+l*s), 1.0);
     
     gl_FragColor = vec4(r,g,b,1.0);
 }
);

NSString *const passThrouhFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 v_texcoord;
 uniform sampler2D renderedTexture;
 uniform highp float flip;
 
 void main()
 {
     vec2 coord1 = vec2(v_texcoord.x,v_texcoord.y);
     
     if(flip == 1.0){
         coord1 = vec2(v_texcoord.x,1.0-v_texcoord.y);
     }
     gl_FragColor = texture2D(renderedTexture, coord1);
 }
 );
NSString *const zoomFragmentShaderString = SHADER_STRING
(
 precision highp float;
 varying highp vec2 v_texcoord;
 uniform sampler2D renderedTexture;
 
 uniform highp float scale;
 uniform highp float flip;
 uniform highp vec2 centerZoom;
 
 void main()
 {
     vec2 coord1 = vec2(v_texcoord.x,v_texcoord.y);
     
     if(flip == 1.0){
         coord1 = vec2(v_texcoord.x,1.0-v_texcoord.y);
     }
 
     
     vec2 zoomedCoord = vec2(scale*coord1.x+centerZoom.x-scale/2.0,scale*coord1.y+centerZoom.y-scale/2.0);
//     vec2 zoomedCoord = vec2(scale*coord1.x+0.5-scale/2.0,scale*coord1.y+0.5-scale/2.0);
//     vec2 zoomedCoord = vec2(0.5*coord1.x+centerZoom.x-0.5/2.0,0.5*coord1.y+centerZoom.y-0.5/2.0);
//     vec2 zoomedCoord = vec2(0.5*coord1.x+0.5-0.5/2.0,0.5*coord1.y+0.5-0.5/2.0);
     gl_FragColor = texture2D(renderedTexture, zoomedCoord);
     
 }
 );

NSString *const distorsionFragmentShaderString = SHADER_STRING
(
 precision highp float;
 
 varying highp vec2 v_texcoord;
 uniform sampler2D renderedTexture;
 
 uniform sampler2D LUT_XR;
 uniform sampler2D LUT_YR;
 uniform sampler2D LUT_XG;
 uniform sampler2D LUT_YG;
 uniform sampler2D LUT_XB;
 uniform sampler2D LUT_YB;
 
 float DecodeFloatRGB(vec3 rgb) {
     return dot(rgb, vec3(1.0,1.0/255.0,1.0/65025.0));
 }
 
 vec2 LUTDistortionR(vec2 coord)
 {
     vec3 lookupX = texture2D(LUT_XR, coord).rgb;
     vec3 lookupY = texture2D(LUT_YR, coord).rgb;
     return vec2(DecodeFloatRGB(lookupX),DecodeFloatRGB(lookupY));
 }
 vec2 LUTDistortionG(vec2 coord)
 {
     vec3 lookupX = texture2D(LUT_XG, coord).rgb;
     vec3 lookupY = texture2D(LUT_YG, coord).rgb;
     return vec2(DecodeFloatRGB(lookupX),DecodeFloatRGB(lookupY));
 }
 vec2 LUTDistortionB(vec2 coord)
 {
     vec3 lookupX = texture2D(LUT_XB, coord).rgb;
     vec3 lookupY = texture2D(LUT_YB, coord).rgb;
     return vec2(DecodeFloatRGB(lookupX),DecodeFloatRGB(lookupY));
 }
 
 
 void main()
 {
     vec2 coord1 = vec2(v_texcoord.x,v_texcoord.y); // flip coord
     
     if(coord1.x<0.5)
     {
         vec2 newTexcoord = vec2(coord1.x*2.0,coord1.y); // goes from 0 to 1 for
         
         vec2 coord = vec2(coord1.x*2.0,coord1.y);
         
         lowp vec4 textureColor = texture2D(renderedTexture,coord);
         lowp vec4 ColorXR = texture2D(LUT_XR, coord);
         lowp vec4 ColorYR = texture2D(LUT_YR, coord);
         lowp vec4 ColorXG = texture2D(LUT_XG, coord);
         lowp vec4 ColorYG = texture2D(LUT_YG, coord);
         lowp vec4 ColorXB = texture2D(LUT_XB, coord);
         lowp vec4 ColorYB = texture2D(LUT_YB, coord);
         
         
         vec3 res = vec3(0.0,0.0,0.0);
         
         vec2 xyR = LUTDistortionR(coord);
         vec2 xyG = LUTDistortionG(coord);
         vec2 xyB = LUTDistortionB(coord);
         
         res = vec3(texture2D(renderedTexture,xyR).r,
                    texture2D(renderedTexture,xyG).g,
                    texture2D(renderedTexture,xyB).b);
         
         gl_FragColor = vec4(res,1.0);
         
         
         if (xyR.x <= 0.0 || xyR.y <= 0.0 || xyR.x >= 1.0 || xyR.y >= 1.0) {
             // set alpha to 1 and return.
             gl_FragColor =  vec4(vec3(0.0,0.0,0.0), 1.0);
         }
         
         if (xyG.x <= 0.0 || xyG.y <= 0.0 || xyG.x >= 1.0 || xyG.y >= 1.0) {
             // set alpha to 1 and return.
             gl_FragColor = vec4(vec3(0.0,0.0,0.0), 1.0);
         }
         
         if (xyB.x <= 0.0 || xyB.y <= 0.0 || xyB.x >= 1.0 || xyB.y >= 1.0) {
             // set alpha to 1 and return.
             gl_FragColor = vec4(vec3(0.0,0.0,0.0), 1.0);
         }
     }
     else
     {
         //vec2 coord = vec2(v_texcoord.x*2.0,v_texcoord.y);
         vec2 coord = vec2((1.0-coord1.x)*2.0,coord1.y);
         
         lowp vec4 textureColor = texture2D(renderedTexture,coord);
         lowp vec4 ColorXR = texture2D(LUT_XR, coord);
         lowp vec4 ColorYR = texture2D(LUT_YR, coord);
         lowp vec4 ColorXG = texture2D(LUT_XG, coord);
         lowp vec4 ColorYG = texture2D(LUT_YG, coord);
         lowp vec4 ColorXB = texture2D(LUT_XB, coord);
         lowp vec4 ColorYB = texture2D(LUT_YB, coord);
         
         
         vec3 res = vec3(0.0,0.0,0.0);
         
         vec2 xyR = vec2(1.0-LUTDistortionR(coord).x,LUTDistortionR(coord).y);
         vec2 xyG = vec2(1.0-LUTDistortionG(coord).x,LUTDistortionG(coord).y);
         vec2 xyB = vec2(1.0-LUTDistortionB(coord).x,LUTDistortionB(coord).y);
         
         res = vec3(texture2D(renderedTexture,xyR).r,
                    texture2D(renderedTexture,xyG).g,
                    texture2D(renderedTexture,xyB).b);
         
         gl_FragColor = vec4(res,1.0);
         
         
         if (xyR.x <= 0.0 || xyR.y <= 0.0 || xyR.x >= 1.0 || xyR.y >= 1.0) {
             // set alpha to 1 and return.
             gl_FragColor =  vec4(vec3(0.0,0.0,0.0), 1.0);
         }
         
         if (xyG.x <= 0.0 || xyG.y <= 0.0 || xyG.x >= 1.0 || xyG.y >= 1.0) {
             // set alpha to 1 and return.
             gl_FragColor = vec4(vec3(0.0,0.0,0.0), 1.0);
         }
         
         if (xyB.x <= 0.0 || xyB.y <= 0.0 || xyB.x >= 1.0 || xyB.y >= 1.0) {
             // set alpha to 1 and return.
             gl_FragColor = vec4(vec3(0.0,0.0,0.0), 1.0);
         }
     }
     
     
 }
 );

static BOOL validateProgram(GLuint prog)
{
	GLint status;
	
    glValidateProgram(prog);
    
#ifdef DEBUG
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        //NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == GL_FALSE) {
		//NSLog(@"Failed to validate program %d", prog);
        return NO;
    }
	
	return YES;
}

static GLuint compileShader(GLenum type, NSString *shaderString)
{
	GLint status;
	const GLchar *sources = (GLchar *)shaderString.UTF8String;
	
    GLuint shader = glCreateShader(type);
    if (shader == 0 || shader == GL_INVALID_ENUM) {
       // NSLog(@"Failed to create shader %d", type);
        return 0;
    }
    
    glShaderSource(shader, 1, &sources, NULL);
    glCompileShader(shader);
	
#ifdef DEBUG
	GLint logLength;
    glGetShaderiv(shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(shader, logLength, &logLength, log);
        //NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(shader, GL_COMPILE_STATUS, &status);
    if (status == GL_FALSE) {
        glDeleteShader(shader);
		//NSLog(@"Failed to compile shader:\n");
        return 0;
    }
    
	return shader;
}

static void mat4f_LoadOrtho(float left, float right, float bottom, float top, float near, float far, float* mout)
{
	float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	mout[0] = 2.0f / r_l;
	mout[1] = 0.0f;
	mout[2] = 0.0f;
	mout[3] = 0.0f;
	
	mout[4] = 0.0f;
	mout[5] = 2.0f / t_b;
	mout[6] = 0.0f;
	mout[7] = 0.0f;
	
	mout[8] = 0.0f;
	mout[9] = 0.0f;
	mout[10] = -2.0f / f_n;
	mout[11] = 0.0f;
	
	mout[12] = tx;
	mout[13] = ty;
	mout[14] = tz;
	mout[15] = 1.0f;
}

//////////////////////////////////////////////////////////

#pragma mark - frame renderers


@interface KxMovieGLRenderer_YUV : NSObject<KxMovieGLRenderer> {
    
    GLint _uniformSamplers[3];
    GLuint _textures[3];
}
@end

@implementation KxMovieGLRenderer_YUV

- (BOOL) isValid
{
    return (_textures[0] != 0);
}

- (NSString *) YUVFragmentShader
{
    return yuvFragmentShaderString;
}
- (NSString *) passThroughFragmentShader
{
    return passThrouhFragmentShaderString;
}
- (NSString *) zoomShader
{
    return zoomFragmentShaderString;
}
- (NSString *) distorsionFragmentShader
{
    return distorsionFragmentShaderString;
}

- (void) resolveUniformsYUVConversionProgram: (GLuint) program
{
    _uniformSamplers[0] = glGetUniformLocation(program, "s_texture_y");
    _uniformSamplers[1] = glGetUniformLocation(program, "s_texture_u");
    _uniformSamplers[2] = glGetUniformLocation(program, "s_texture_v");
}

- (void) setFrame: (VideoFrameYUV *) yuvFrame
{
    const NSUInteger frameWidth = yuvFrame->width;
    const NSUInteger frameHeight = yuvFrame->height;

    glPixelStorei(GL_UNPACK_ALIGNMENT, 1);
    if (0 == _textures[0])
        glGenTextures(3, _textures);

    UInt8 *pixels[3] = { yuvFrame->luma, yuvFrame->chromaB, yuvFrame->chromaR };
    NSUInteger widths[3]  = { frameWidth, frameWidth / 2, frameWidth / 2 };
    NSUInteger heights[3] = { frameHeight, frameHeight / 2, frameHeight / 2 };
    
    for (int i = 0; i < 3; ++i) {
    
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_LUMINANCE,
                     (GLsizei)widths[i],
                     (GLsizei)heights[i],
                     0,
                     GL_LUMINANCE,
                     GL_UNSIGNED_BYTE,
                     pixels[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}
- (BOOL) prepareRenderYUV
{
    if (_textures[0] == 0)
        return NO;
    
    for (int i = 0; i < 3; ++i) {
        glActiveTexture(GL_TEXTURE0 + i);
        glBindTexture(GL_TEXTURE_2D, _textures[i]);
        glUniform1i(_uniformSamplers[i], i);
    }
    
    return YES;
}


- (void) dealloc
{
    if (_textures[0])
        glDeleteTextures(3, _textures);
//    [super dealloc];
}

@end

//////////////////////////////////////////////////////////

#pragma mark - gl view

enum {
	ATTRIBUTE_VERTEX,
   	ATTRIBUTE_TEXCOORD,
};

@implementation MovieGLView {
    
}

+ (Class) layerClass
{
	return [CAEAGLLayer class];
}

- (void)adjustSize{
    
    CGSize superSize = self.superview.frame.size;
    
    if(superSize.width*_height!=superSize.height*_width){
        if(superSize.width*_height < superSize.height*_width){
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setFrame:CGRectMake(0, (superSize.height-superSize.width*_height/_width)*0.5, superSize.width, superSize.width*_height/_width)];
            });
        }
        else{
            dispatch_async(dispatch_get_main_queue(), ^{
                [self setFrame:CGRectMake((superSize.width-superSize.height*_width/_height)*0.5, 0, superSize.height*_width/_height, superSize.height)];
            });
        }
    }
    else{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self setFrame:CGRectMake(0, 0, superSize.width, superSize.height)];
        });
    }
}



- (void)dealloc
{
    _renderer = nil;
    
    if (displayFramebuffer) {
        glDeleteFramebuffers(1, &displayFramebuffer);
        displayFramebuffer = 0;
    }
    
    if (displayRenderbuffer) {
        glDeleteRenderbuffers(1, &displayRenderbuffer);
        displayRenderbuffer = 0;
    }
    
    if (yuvConversionProgram) {
        glDeleteProgram(yuvConversionProgram);
        yuvConversionProgram = 0;
    }
    
    if ([EAGLContext currentContext] == _context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    _context = nil;
    
}

- (void)layoutSubviews
{
    return;
//    NSLog(@"gl layoutSubviews\n");
//    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
//    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
//	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
//    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);
//	
//    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
//	if (status != GL_FRAMEBUFFER_COMPLETE) {
//		
//      //  NSLog(@"failed to make complete framebuffer object %x", status);
//        
//	} else {
//        //NSLog(@"OK setup GL framebuffer %d:%d", _backingWidth, _backingHeight);
//    }
//    
//    [self updateVertices];
//    [self render: nil];
}

- (void)setContentMode:(UIViewContentMode)contentMode
{
    [super setContentMode:contentMode];
    [self updateVertices];
    if (_renderer.isValid)
        [self render:nil];
}
- (BOOL)loadYUVConversionShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    yuvConversionProgram = glCreateProgram();
    
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
    if (!vertShader)
        goto exit;
    
    fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.YUVFragmentShader);
    if (!fragShader)
        goto exit;
    
    glAttachShader(yuvConversionProgram, vertShader);
    glAttachShader(yuvConversionProgram, fragShader);
    glBindAttribLocation(yuvConversionProgram, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(yuvConversionProgram, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(yuvConversionProgram);
    
    GLint status;
    glGetProgramiv(yuvConversionProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        DVLog(@"Failed to link program yuvConversion");
        goto exit;
    }
    
    result = validateProgram(yuvConversionProgram);
    
    _uniformMatrix = glGetUniformLocation(yuvConversionProgram, "modelViewProjectionMatrix");
    [_renderer resolveUniformsYUVConversionProgram:yuvConversionProgram];
    
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        //NSLog(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(yuvConversionProgram);
        yuvConversionProgram = 0;
    }
    
    return result;
}

- (BOOL)loadZoomShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    zoomProgram = glCreateProgram();
    
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
    if (!vertShader)
        goto exit;
    
    fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.zoomShader);
    if (!fragShader)
        goto exit;
    
    glAttachShader(zoomProgram, vertShader);
    glAttachShader(zoomProgram, fragShader);
    glBindAttribLocation(zoomProgram, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(zoomProgram, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(zoomProgram);
    
    GLint status;
    glGetProgramiv(zoomProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        DVLog(@"Failed to link program passThrough");
        goto exit;
    }
    
    result = validateProgram(zoomProgram);
    
    _uniformMatrix = glGetUniformLocation(zoomProgram, "modelViewProjectionMatrix");
    
    zoomTextureUniformSampler =glGetUniformLocation(zoomProgram, "renderedTexture");
    centerZoomUniform = glGetUniformLocation(zoomProgram, "centerZoom");
    scaleUniform = glGetUniformLocation(zoomProgram, "scale");
    zoomFlipYUniform = glGetUniformLocation(zoomProgram, "flip");
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        //NSLog(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(zoomProgram);
        zoomProgram = 0;
    }
    
    return result;
}
- (BOOL)loadPassThroughShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    passThroughProgram = glCreateProgram();
    
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
    if (!vertShader)
        goto exit;
    
    fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.passThroughFragmentShader);
    if (!fragShader)
        goto exit;
    
    glAttachShader(passThroughProgram, vertShader);
    glAttachShader(passThroughProgram, fragShader);
    glBindAttribLocation(passThroughProgram, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(passThroughProgram, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(passThroughProgram);
    
    GLint status;
    glGetProgramiv(passThroughProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        DVLog(@"Failed to link program passThrough");
        goto exit;
    }
    
    result = validateProgram(passThroughProgram);
    
    _uniformMatrix = glGetUniformLocation(passThroughProgram, "modelViewProjectionMatrix");
    
//    renderedTextureUniformSampler =glGetUniformLocation(passThroughProgram, "renderedTexture");
    passthroughInputTextureUniformSampler = glGetUniformLocation(passThroughProgram, "renderedTexture");
    passthroughFlipUniform = glGetUniformLocation(passThroughProgram, "flip");
    
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        //NSLog(@"OK setup GL program");
        
    } else {
        
        glDeleteProgram(passThroughProgram);
        passThroughProgram = 0;
    }
    
    return result;
}

- (BOOL)loadDistorsionShaders
{
    BOOL result = NO;
    GLuint vertShader = 0, fragShader = 0;
    
    distorsionProgram = glCreateProgram();
    
    vertShader = compileShader(GL_VERTEX_SHADER, vertexShaderString);
    if (!vertShader)
        goto exit;
    
    fragShader = compileShader(GL_FRAGMENT_SHADER, _renderer.distorsionFragmentShader);
    if (!fragShader)
        goto exit;
    
    glAttachShader(distorsionProgram, vertShader);
    glAttachShader(distorsionProgram, fragShader);
    glBindAttribLocation(distorsionProgram, ATTRIBUTE_VERTEX, "position");
    glBindAttribLocation(distorsionProgram, ATTRIBUTE_TEXCOORD, "texcoord");
    
    glLinkProgram(distorsionProgram);
    
    GLint status;
    glGetProgramiv(distorsionProgram, GL_LINK_STATUS, &status);
    if (status == GL_FALSE) {
        DVLog(@"Failed to link program distorsion");
        goto exit;
    }
    
    result = validateProgram(distorsionProgram);
    
    _uniformMatrix = glGetUniformLocation(distorsionProgram, "modelViewProjectionMatrix");
    
    distorsionInputTextureUniformSampler =glGetUniformLocation(distorsionProgram, "renderedTexture");
    [self LoadLUTsAndGetUniformLocations];
    
exit:
    
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    if (result) {
        
        //NSLog(@"OK setup GL programm");
        
    } else {
        
        glDeleteProgram(distorsionProgram);
        distorsionProgram = 0;
    }
    
    return result;
}

-(void) LoadLUTsAndGetUniformLocations
{
    //Load image data from PNG
    
    CFDataRef dataFromImageDataProvider = NULL;
    CGImageRef newImageSource;
    
    CGSize pixelSizeOfImage;
    CGSize pixelSizeToUseForTexture;
    
    NSArray *uniformStrings = @[@"LUT_XR",@"LUT_YR",@"LUT_XG",@"LUT_YG",@"LUT_XB",@"LUT_YB"];
    for(int i =0; i<6;i++)
    {
        LUTTextureUniform[i] = glGetUniformLocation(distorsionProgram, [uniformStrings[i] UTF8String]);
        NSString *file = [NSString stringWithFormat:@"%@.png",uniformStrings[i]];
        
        inputImage[i] = [UIImage imageNamed:file];
        
        newImageSource = [inputImage[i] CGImage];
        widthOfImage = CGImageGetWidth(newImageSource);
        heightOfImage = CGImageGetHeight(newImageSource);
        pixelSizeOfImage = CGSizeMake(widthOfImage, heightOfImage);
        pixelSizeToUseForTexture = pixelSizeOfImage;
        
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(newImageSource));
        imageData[i] = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
        
        if (0 == LUTTextures[0])
            glGenTextures(6, LUTTextures);
        
        glActiveTexture(GL_TEXTURE2 + i);
        glBindTexture(GL_TEXTURE_2D, LUTTextures[i]);
        
        glTexImage2D(GL_TEXTURE_2D,
                     0,
                     GL_RGBA,
                     (int)pixelSizeToUseForTexture.width,
                     (int)pixelSizeToUseForTexture.height,
                     0,
                     GL_RGBA,
                     GL_UNSIGNED_BYTE,
                     imageData[i]);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
    if (dataFromImageDataProvider)
    {
        CFRelease(dataFromImageDataProvider);
    }
}

- (void)updateVertices
{
    const float dH      = (float)_backingHeight / _height;
    const float dW      = (float)_backingWidth	  / _width;
//    const float dd      = fit ? MIN(dH, dW) : MAX(dH, dW);
    const float h       = (_height * dH / (float)_backingHeight);//(height * dd / (float)_backingHeight);
    const float w       = (_width  * dW / (float)_backingWidth );//(width  * dd / (float)_backingWidth );
    
    _vertices[0] = - w;
    _vertices[1] = - h;
    _vertices[2] =   w;
    _vertices[3] = - h;
    _vertices[4] = - w;
    _vertices[5] =   h;
    _vertices[6] =   w;
    _vertices[7] =   h;
}

-(CVOpenGLESTextureCacheRef) coreVideoTextureCache{
    if (coreVideoTextureCache == NULL)
    {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, _context, NULL, &coreVideoTextureCache);
        if (err)
        {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return coreVideoTextureCache;
}

-(void) generateDistorsionRenderTexture_Target{
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)imageWidth, (int)imageHeight, kCVPixelFormatType_32BGRA, attrs, &distorsionRenderTarget); // renderTarget is a CVPixelBufferRef
    if (err)
    {
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self coreVideoTextureCache], distorsionRenderTarget,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)imageWidth,
                                                        (int)imageHeight,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &distorsionRenderTexture);
    
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindFramebuffer(GL_FRAMEBUFFER, distorsionOutputFramebuffer);
    glBindTexture(CVOpenGLESTextureGetTarget(distorsionRenderTexture), CVOpenGLESTextureGetName(distorsionRenderTexture));
    
    distorsionOffscreenRenderTexture = CVOpenGLESTextureGetName(distorsionRenderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(distorsionRenderTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete distorsion FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}
-(void) generateTrackingRenderTexture_Target{
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)trackingImageWidth, (int)trackingImageHeight, kCVPixelFormatType_32BGRA, attrs, &trackingRenderTarget); // renderTarget is a CVPixelBufferRef
    if (err)
    {
        DVLog(@"FBO size: %d, %d", (int)trackingImageWidth, (int)trackingImageHeight);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self coreVideoTextureCache], trackingRenderTarget,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)trackingImageWidth,
                                                        (int)trackingImageHeight,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &trackingRenderTexture);
    
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindFramebuffer(GL_FRAMEBUFFER, trackingFramebuffer);
    glBindTexture(CVOpenGLESTextureGetTarget(trackingRenderTexture), CVOpenGLESTextureGetName(trackingRenderTexture));
    
    trackingOffscreenRenderTexture = CVOpenGLESTextureGetName(trackingRenderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(trackingRenderTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete tracking FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
}
-(void) generateZoomRenderTexture_Target{
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)imageWidth, (int)imageHeight, kCVPixelFormatType_32BGRA, attrs, &zoomRenderTarget); // renderTarget is a CVPixelBufferRef
    if (err)
    {
        DVLog(@"FBO size: %d, %d", (int)imageWidth, (int)imageHeight);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self coreVideoTextureCache], zoomRenderTarget,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)imageWidth,
                                                        (int)imageHeight,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &zoomRenderTexture);
    
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindFramebuffer(GL_FRAMEBUFFER, zoomOutputFramebuffer);
    glBindTexture(CVOpenGLESTextureGetTarget(zoomRenderTexture), CVOpenGLESTextureGetName(zoomRenderTexture));
    
    zoomOffscreenRenderTexture = CVOpenGLESTextureGetName(zoomRenderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(zoomRenderTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete zoom FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}
-(void) generateOffscreenRenderTexture{
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)imageWidth, (int)imageHeight, kCVPixelFormatType_32BGRA, attrs, &renderTarget); // renderTarget is a CVPixelBufferRef
    if (err)
    {
        DVLog(@"FBO size: %d, %d", (int)imageWidth, (int)imageHeight);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }

    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self coreVideoTextureCache], renderTarget,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)imageWidth,
                                                        (int)imageHeight,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &renderTexture);
    
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    glBindFramebuffer(GL_FRAMEBUFFER, YUVConversionOutputFramebuffer);
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture), CVOpenGLESTextureGetName(renderTexture));
    
    YUV_offscreenRenderTexture = CVOpenGLESTextureGetName(renderTexture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete YUVConversion FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}
-(void) generateOffscreenRenderTexture2{
    
    CFDictionaryRef empty; // empty value for attr value.
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks); // our empty IOSurface properties dictionary
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);
    
    CVReturn err = CVPixelBufferCreate(kCFAllocatorDefault, (int)imageWidth, (int)imageHeight, kCVPixelFormatType_32BGRA, attrs, &renderTarget2);

    if (err)
    {
        DVLog(@"FBO size: %d, %d", (int)imageWidth, (int)imageHeight);
        NSAssert(NO, @"Error at CVPixelBufferCreate %d", err);
    }
    
    err = CVOpenGLESTextureCacheCreateTextureFromImage (kCFAllocatorDefault, [self coreVideoTextureCache], renderTarget2,
                                                        NULL, // texture attributes
                                                        GL_TEXTURE_2D,
                                                        GL_RGBA, // opengl format
                                                        (int)imageWidth,
                                                        (int)imageHeight,
                                                        GL_BGRA, // native iOS format
                                                        GL_UNSIGNED_BYTE,
                                                        0,
                                                        &renderTexture2);
    
    if (err)
    {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CFRelease(attrs);
    CFRelease(empty);
    
    // renderTarget2 --> bytes per row = 2688

    
    glBindFramebuffer(GL_FRAMEBUFFER, _offscreenFramebuffer2);
    glBindTexture(CVOpenGLESTextureGetTarget(renderTexture2), CVOpenGLESTextureGetName(renderTexture2));
    _offscreenRenderTexture2 = CVOpenGLESTextureGetName(renderTexture2);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(renderTexture2), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
}

-(void) updateZoomScale{
    
    float targetScale = _targetZoomScale;
    float currentScale = _zoomScale;
    float zoomSp = _zoomSpeed;
    
    
    float tweakScale = sign(targetScale - currentScale)*sqrt(fabsf(targetScale - currentScale))*zoomSp;
    
    _zoomScale += tweakScale;
    
}
- (id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    _Distort = NO;
    _isMovieWritingPaused = NO;
    _zoomEnabled = YES;
    _zoomScale = 1;
    _targetZoomScale = 1;
    _zoomSpeed = 0.02;
    _centerZoom = CGPointMake(0.5, 0.5);
    frameNumber = 0;
    
    imageWidth = 1280;
    imageHeight = 720; // should think about automaating here ....
    
    // zoom for tracking
    _zoomForTrackingEnabled = YES;
    
    trackingImageHeight = imageHeight/2;
    trackingImageWidth = imageWidth/2;
    
    if (self) {
         // size of the frame allocated for videoPreviewer :(667,375)
//        _width   = frame.size.width;
//        _height  = frame.size.height;
//        
        
        
        
//        NSLog(@"frame size at init: w: %d, h: %d",(int)_width,(int)_height); // 0 , 0 at init
        [self setBackgroundColor:[super backgroundColor]];
        
        //        _width = 640;
        //        _height = 480;
        
        _renderer = [[KxMovieGLRenderer_YUV alloc] init];
        // NSLog(@"OK use YUV GL renderer");
        
        
        CAEAGLLayer *eaglLayer = (CAEAGLLayer*) self.layer;
        eaglLayer.opaque = YES;
        eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                        [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                                        kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                                        nil];
        
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!_context ||
            ![EAGLContext setCurrentContext:_context]) {
            
            NSLog(@"failed to setup EAGLContext");
            self = nil;
            return nil;
        }
        
        
        // Onscreen framebuffer object
        
        glGenFramebuffers(1, &displayFramebuffer);
        glGenRenderbuffers(1, &displayRenderbuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
        [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth); // request the width of the current bound renderBuffer...
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight); // 667 .. 375 ... qqch comme ca la taille de l'écran
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, displayRenderbuffer);
        
        // Offscreen framebuffer object
        
        glGenFramebuffers(1, &YUVConversionOutputFramebuffer);
        [self generateOffscreenRenderTexture];
        
        glGenFramebuffers(1, &zoomOutputFramebuffer);
        [self generateZoomRenderTexture_Target];
        
        glGenFramebuffers(1, &trackingFramebuffer);
        [self generateTrackingRenderTexture_Target];
        
        glGenFramebuffers(1, &distorsionOutputFramebuffer);
        [self generateDistorsionRenderTexture_Target];
        
//        glGenFramebuffers(1, &_offscreenFramebuffer2);
//        [self generateOffscreenRenderTexture2];

        
        GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
        if (status != GL_FRAMEBUFFER_COMPLETE) {
            
             NSLog(@"failed to make complete framebuffer object %x", status);
            self = nil;
            return nil;
        }
        
        GLenum glError = glGetError();
        if (GL_NO_ERROR != glError) {
            
             NSLog(@"failed to setup GL %x", glError);
            self = nil;
            return nil;
        }
        
        if (![self loadYUVConversionShaders]|| ![self loadPassThroughShaders]|| ![self loadZoomShaders] || ![self loadDistorsionShaders]) {
            NSLog(@"failed to load shaders");
            self = nil;
            return nil;
        }
        
        _vertices[0] = -1.0f;  // x0
        _vertices[1] = -1.0f;  // y0
        _vertices[2] =  1.0f;  // ..
        _vertices[3] = -1.0f;
        _vertices[4] = -1.0f;
        _vertices[5] =  1.0f;
        _vertices[6] =  1.0f;  // x3
        _vertices[7] =  1.0f;  // y3
        
        // NSLog(@"OK setup GL");
    }
    
    return self;
}



- (void)render: (VideoFrameYUV *) frame{
    
  static const GLfloat texCoords[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };
    
    GLfloat modelviewProj[16];

    [EAGLContext setCurrentContext:_context];
    
    // **************  START YUV CONVERSION **************
    
    glBindFramebuffer(GL_FRAMEBUFFER, YUVConversionOutputFramebuffer);
    glViewport(0, 0, imageWidth, imageHeight); // resolution de l'image de sortie ... moitie pour moindre resolution.. cvpixelbuffer aussi doit avoir la mm taille... _backing width en cas de display à l'ecran
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glUseProgram(yuvConversionProgram);
    
    if (frame) {
        frameNumber ++;
      
        _width = frame->width; //1280
        _height = frame->height; //720

        [self adjustSize];
        
        [_renderer setFrame:frame];
        
        
    }
    else{
        NSLog(@"no frame");
    }
    
    if ([_renderer prepareRenderYUV]) {
        
        mat4f_LoadOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -1.0f, 1.0f, modelviewProj);
        
        glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
        
        glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
        glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
        glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
        glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
        
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    }
    
    // result YUV conversion ---> YUV_offscreenRenderTexture
    // **************  END YUV CONVERSION **************

    // ************** START ZOOM FOR DISPLAY AND MOVIE  **************
    
    glBindFramebuffer(GL_FRAMEBUFFER, zoomOutputFramebuffer);
    glViewport(0, 0, imageWidth, imageHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_zoomEnabled) {
        
        if (_targetZoomScale != _zoomScale) {
            [self updateZoomScale];
        }
        glUseProgram(zoomProgram);
        
        glActiveTexture(GL_TEXTURE0); // input texture and the uniform sampler where to attach it in the current program
        glBindTexture(GL_TEXTURE_2D, YUV_offscreenRenderTexture);
        glUniform1i(zoomTextureUniformSampler, 0);
        
        _zoomScale = bindBetween(_zoomScale, 0.2, 1);

        _centerZoom.x = bindBetween(_centerZoom.x, _zoomScale/2, 1.0-_zoomScale/2);
        _centerZoom.y = bindBetween(_centerZoom.y, _zoomScale/2, 1.0-_zoomScale/2);
        
        glUniform1f(scaleUniform, _zoomScale);
        glUniform1f(zoomFlipYUniform, 1.0); // flip YES because frame coming from yuv is upside down
        
        GLfloat positionArray[2];
        positionArray[0] = _centerZoom.x;
        positionArray[1] = _centerZoom.y;
        
        glUniform2fv(centerZoomUniform, 1, positionArray);
    }
    else{
        _zoomForTrackingEnabled = NO;
        glUseProgram(passThroughProgram);
        
        glActiveTexture(GL_TEXTURE0);
        glBindTexture(GL_TEXTURE_2D, YUV_offscreenRenderTexture); // output of the previous operation : zoom
        glUniform1i(passthroughInputTextureUniformSampler, 0);
        glUniform1f(passthroughFlipUniform, 1.0);
    }
    
    glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
    
    glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
    glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // result zoom for display ---->  zoomOffscreenRenderTexture
    // ************** END ZOOM FOR DISPLAY AND MOVIE  **************
    
    
    
    // ************** START ZOOM FOR TRACKING  **************
    
    glBindFramebuffer(GL_FRAMEBUFFER, trackingFramebuffer);
    glViewport(0, 0, trackingImageWidth, trackingImageHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(passThroughProgram);
    
    // different input
    if (_zoomForTrackingEnabled) {
        //DVLog(@"zoom tracking enabled");
        glActiveTexture(GL_TEXTURE0); // input texture from the previous zoom
        glBindTexture(GL_TEXTURE_2D, zoomOffscreenRenderTexture);
        glUniform1i(passthroughInputTextureUniformSampler, 0);
        glUniform1f(passthroughFlipUniform, 1.0); // no flip
    }
    else{
       // DVLog(@"no zoom tracking");
        glActiveTexture(GL_TEXTURE0); // input texture from the yuv conversion for resolution lowering
        glBindTexture(GL_TEXTURE_2D, YUV_offscreenRenderTexture);
        glUniform1i(passthroughInputTextureUniformSampler, 0);
        glUniform1f(passthroughFlipUniform, 1.0); // no flip
    }
    
    glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
    
    glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
    glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // result zoom for tracking in ----> trackingOffscreenRenderTexture
    // ************** END ZOOM FOR TRACKING  **************
    
    
    CMTime presentTime = CMTimeMake(frameNumber, 30);
    
//    [[MovieWriter instance] newFrame:distorsionRenderTarget ReadyAtTime:presentTime atIndex:0];
//        [[MovieWriter instance] newFrame:zoomRenderTarget ReadyAtTime:presentTime atIndex:0];
    if (!_isMovieWritingPaused) {
//        [[MovieWriter instance] newFrame:trackingRenderTarget ReadyAtTime:presentTime atIndex:0];
    }
    
//    frameNumber ++;
    // START UPDATE TRACKER FRAME
    
//    if([Tracker instance].needsNewFrame){
//        CVPixelBufferLockBaseAddress(renderTarget, 0);
//        
//        int pixelBufWidth =(int) CVPixelBufferGetWidth(renderTarget);
//        int pixelBufHeight = (int)CVPixelBufferGetHeight(renderTarget);
//        
//        // Here we don't copy data but just pass a pointer to the pixelBuffer which may be copied by _tld
//        [[Tracker instance] updateCurrentFrameWithRawData:(uint8_t*)CVPixelBufferGetBaseAddress(renderTarget) andWidth:pixelBufWidth andHeight:pixelBufHeight andFrameNumber:frameNumber];
//        CVPixelBufferUnlockBaseAddress(renderTarget, 0);
//    }
    // END UPDATE TRACKER FRAME
    
    // ************** START DISTORSION **************
    
    glBindFramebuffer(GL_FRAMEBUFFER, distorsionOutputFramebuffer);
    glViewport(0, 0, imageWidth, imageHeight);
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    if (_Distort) {
        glUseProgram(distorsionProgram);
        
        glActiveTexture(GL_TEXTURE0); // input texture and the uniform sampler where to attach it in the current program
        glBindTexture(GL_TEXTURE_2D, zoomOffscreenRenderTexture);
        glUniform1i(distorsionInputTextureUniformSampler, 0);
        
        for(int i = 0; i<6;i++)
        {
            glActiveTexture(GL_TEXTURE2+i);
            glBindTexture(GL_TEXTURE_2D, LUTTextures[i]);
            glUniform1i(LUTTextureUniform[i], 2+i);
        }
    }
    else{
        glUseProgram(passThroughProgram);
        
        glActiveTexture(GL_TEXTURE0); // input texture and the uniform sampler where to attach it in the current program
        glBindTexture(GL_TEXTURE_2D, zoomOffscreenRenderTexture);
        glUniform1i(passthroughInputTextureUniformSampler, 0);
        glUniform1f(passthroughFlipUniform, 1.0);
    }
    
    glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
    
    glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
    glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // result zoom for display ---->  distorsionOffscreenRenderTexture

    // ************** END DISTORSION **************
    // available targets : distorsionRenderTarget, zoomRenderTarget, trackingRenderTarget
    
    
    
    
    
    
    
    
    
    // ************** START DISPLAY **************
    // bind the display framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, displayFramebuffer);
    glViewport(0, 0, _backingWidth, _backingHeight); // here the viewPort size should be the screen size
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    glUseProgram(passThroughProgram);
    
    // use the texture from the distorsionOutput
    /****** different available textures
     - LUTTextures[0], LUTTextures[1], LUTTextures[2]
     - renderer -> texture[3] --> y,u,v .. ?
     - YUV_offscreenRenderTexture --> à l'endroit
     - zoomOffscreenRenderTexture
     - distorsionOffscreenRenderTexture
     
                                        zoomOffscreenRenderTexture -->  distorsionOffscreenRenderTexture --> display
     FLOW : YUV_offscreenRenderTexture  \
     -                                 \  ---->trackingOffscreenRenderTexture
     
     */
    glActiveTexture(GL_TEXTURE0);

    glBindTexture(GL_TEXTURE_2D, distorsionOffscreenRenderTexture); // see what happens in any texture


    glUniform1i(passthroughInputTextureUniformSampler, 0);
    glUniform1f(passthroughFlipUniform, 0.0);
    
    glUniformMatrix4fv(_uniformMatrix, 1, GL_FALSE, modelviewProj);
    
    glVertexAttribPointer(ATTRIBUTE_VERTEX, 2, GL_FLOAT, 0, 0, _vertices);
    glEnableVertexAttribArray(ATTRIBUTE_VERTEX);
    glVertexAttribPointer(ATTRIBUTE_TEXCOORD, 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray(ATTRIBUTE_TEXCOORD);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    // ************** END DISPLAY **************
    

    
    glBindRenderbuffer(GL_RENDERBUFFER, displayRenderbuffer);
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
}

-(void)finish
{
    glFinish();
}
@end
