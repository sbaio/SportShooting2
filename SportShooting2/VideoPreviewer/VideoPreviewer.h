//
//  VideoPreviewer.h
//  DJI
//
//  Copyright (c) 2013. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoFrameExtractor.h"
#import "MovieGLView.h"
#import "DJILinkQueues.h"
#import "Menu.h"
#import "DVFloatingWindow.h"
#import "AppDelegate.h"

#define RENDER_FRAME_NUMBER (4)

#define kDJIDecoderDataSoureNone                    (0)
#define kDJIDecoderDataSoureInspire                 (1)
#define kDJIDecoderDataSourePhantom3Advanced        (4)
#define kDJIDecoderDataSourePhantom3Professional    (5)

@class AppDelegate;

typedef struct{
    BOOL isInit:1;      // The initialized status
    BOOL isRunning:1;   // whether or not the decoding thread is running
    BOOL isPause:1;     // whether or not the decoding thread is paused
    BOOL isFinish:1;    // whether or not the decoding thread is finished
    BOOL hasImage:1;    // has image
    BOOL isGLViewInit:1;// OpenGLView is init
    BOOL isBackground:1;// enter background
    uint8_t other:1;    // Reserved
}VideoPreviewerStatus;

typedef NS_ENUM(NSUInteger, VideoPreviewerEvent){
    VideoPreviewerEventNoImage,     //
    VideoPreviewerEventHasImage,    //
};

@protocol VideoPreviewerDelegate <NSObject>

@optional

- (void)previewDidUpdateStatus;

- (void)previewDidReceiveEvent:(VideoPreviewerEvent)event;

@end

@interface VideoPreviewer : NSObject 
{
    NSThread *_decodeThread;
    MovieGLView *_glView;
    VideoFrameYUV *_renderYUVFrame[RENDER_FRAME_NUMBER];
    int _decodeFrameIndex;
    int _renderFrameIndex;
    
    dispatch_queue_t _dispatchQueue;
    
    __weak AppDelegate* appD;
    
}

@property(nonatomic, assign) BOOL isHardwareDecoding;

/**
 *  Frame extractor
 */
@property (retain) VideoFrameExtractor *videoExtractor;
/**
 *  Video data queue, used for cache raw video data.
 */
@property(retain) DJILinkQueues *dataQueue;
/**
 *  Status of previewer
 */
@property (assign,readonly) VideoPreviewerStatus status;

@property  MovieGLView * glView;

@property (weak,nonatomic) id<VideoPreviewerDelegate> delegate;

@property (nonatomic,strong) UITapGestureRecognizer* tapGRSwitching;
@property (nonatomic,strong) UITapGestureRecognizer* tapGROnLargeView;

+(VideoPreviewer*) instance;
+(void) removePreview;

/**
 *  Set the render view.
 *
 */
- (BOOL)setView:(UIView *)view;
-(void) updateGLviewWithFrame:(CGRect) frame;

/**
 *  Remove the render view
 */
- (void)unSetView;

/**
 *  Start decode thread
 *
 */
- (BOOL)start;

/**
 *  Resume decode thread
 */
- (void)resume;

/**
 *  Pause decode thread
 */
- (void)pause;

/**
 *  Close decode thread
 *
 *  @deprecated use stop instead
 */
- (void)close __attribute__ ((__deprecated__));

/**
 *  Stop decode thread
 *
 */
- (void)stop;

/**
 *  Reset decoder. Call when the decoder could not work correctly.
 *
 */
-(void) reset;

-(void) saveMovie;
-(void) startMovieWriting;

/**
 *  Set decoder's data source
 *
 *  @param type See reference kDJIDecoderDataSoureXXX
 */
- (void) setDecoderDataSource:(int)type;



-(void) setGLviewMaskImage:(BOOL) set isReceivingFlightControllerStatus:(BOOL) isReceivingFlightControllerStatus isLocEnabled:(BOOL) isLocationServicesAuth isReceivingCameraFeed:(BOOL) isReceivingCameraFeed isRCConnected:(BOOL) isRCConnected;

@end
