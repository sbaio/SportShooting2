//
//  MovieWriter.h
//  SportShooting2
//
//  Created by Othman Sbai on 2/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface MovieWriter : NSObject
{
    dispatch_queue_t movieWriterQueue;
    
    NSURL *movieURL;
    NSString *pathToMovie;
    
    AVAssetWriter *videoWriter;
    AVAssetWriterInput *writerInput;
    AVAssetWriterInputPixelBufferAdaptor *assetWriterPixelBufferInput;
    
    CGSize videoSize;
    
    CMTime startTime, previousFrameTime;
    BOOL isMovieRecording;
    BOOL videoEncodingIsFinished;
}

@property BOOL isMovieRecording;

+(MovieWriter *) instance;

-(void) startRecording;
-(void) finishRecordingWithCompletion:(void (^)(void))handler;

-(void)newFrame:(CVPixelBufferRef) pixelBuffer ReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex;
@end
