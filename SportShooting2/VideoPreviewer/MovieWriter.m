//
//  MovieWriter.m
//  SportShooting2
//
//  Created by Othman Sbai on 2/9/16.
//  Copyright © 2016 Othman Sbai. All rights reserved.
//

#import "MovieWriter.h"
#import "DVFloatingWindow.h"

#define BEGIN_MOVIE_WRITING_QUEUE dispatch_async(movieWriterQueue, ^{
#define END_MOVIE_WRITING_QUEUE   });

@implementation MovieWriter

@synthesize isMovieRecording = _isMovieRecording;

-(id) initMovieWriter{
    self= [super init];
    
    videoEncodingIsFinished = NO;
    
    movieWriterQueue = dispatch_queue_create("movieWriterQueue", DISPATCH_QUEUE_SERIAL);
    
    DVLog(@"path creation sucess: %d",[self createPath]);

    NSError * error = nil;
    videoWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    
    if (error != nil){
        DVLog(@"Error init videoAssetWriter: %@", error);
    }
    
    videoWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);
//    videoSize = CGSizeMake(1280.0, 720.0);
    videoSize = CGSizeMake(640.0, 360.0);
    NSMutableDictionary *settings = [[NSMutableDictionary alloc] init];
    [settings setObject:AVVideoCodecH264 forKey:AVVideoCodecKey];
    
    [settings setObject:[NSNumber numberWithInt:videoSize.width] forKey:AVVideoWidthKey];
    [settings setObject:[NSNumber numberWithInt:videoSize.height] forKey:AVVideoHeightKey];
    
    writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:nil];
    //    writerInput.expectsMediaDataInRealTime = YES;
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey,
                                                           [NSNumber numberWithInt:videoSize.width], kCVPixelBufferWidthKey,
                                                           [NSNumber numberWithInt:videoSize.height], kCVPixelBufferHeightKey,
                                                           nil];
    
    assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    [videoWriter addInput:writerInput];
    
    return self;
}

+(MovieWriter *) instance{
    
    static MovieWriter * movieWriter = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        movieWriter = [[MovieWriter alloc] initMovieWriter];
    });
    
    return movieWriter;
}

-(BOOL) createPath{
    
    pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/OtosMovie.mov"];
    movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    NSError * error;
    
    if([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]){
        DVLog(@"INIT : file exists");
        
        if([[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:&error] != YES){
            DVLog(@"INIT : removing problem %@",error.localizedDescription);
            return NO;
            
        }
        else{
            DVLog(@"INIT : File was existing, removed successfully");
            return YES;
        }
    }
    else{
        DVLog(@"INIT : file wasn't existing");
        return YES;
    }
    
    return NO;
}

-(void) managePath{
    
    pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/OtosMovie.mov"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError * error = nil;
    
    if([fileMgr fileExistsAtPath:pathToMovie]){
        DVLog(@"START RECORD : file exists will be removed");
        
        if([fileMgr removeItemAtPath:pathToMovie error:&error] != YES){
            DVLog(@"START RECORD : remove problem %@",error.localizedDescription);
        }
        else{
            DVLog(@"START RECORD : file removed successfully");
        }
    }
    else{
        DVLog(@"START RECORD : path ok");
    }
    movieURL = [NSURL fileURLWithPath:pathToMovie];
}

-(void) startRecording{
    
    startTime = kCMTimeInvalid;
    BEGIN_MOVIE_WRITING_QUEUE
    
    [self managePath]; // check if file already exists
    
    [videoWriter startWriting];
    
    END_MOVIE_WRITING_QUEUE
    isMovieRecording = YES;
}

-(void) finishRecordingWithCompletion:(void (^)(void))handler{
    
    BEGIN_MOVIE_WRITING_QUEUE
    isMovieRecording = NO;
    
    if (videoWriter.status == AVAssetWriterStatusCompleted || videoWriter.status == AVAssetWriterStatusCancelled || videoWriter.status == AVAssetWriterStatusUnknown){
        NSLog(@"completed, canceled or unknown");
        return;
    }
    if( videoWriter.status == AVAssetWriterStatusWriting && ! videoEncodingIsFinished )
    {
        videoEncodingIsFinished = YES;
        [writerInput markAsFinished];
    }
    if ([videoWriter respondsToSelector:@selector(finishWritingWithCompletionHandler:)]) {
        // HERE
        [videoWriter finishWritingWithCompletionHandler:(handler ?: ^{
        })];
        DVLog(@"finished writing");
    }
    else {
        DVLog(@"see GPUImage");
    }

    //save the file
    
    [self checkFile];
    
    END_MOVIE_WRITING_QUEUE
}

-(void) checkFile{

    // assumes pathToMovie is set
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if([fileMgr fileExistsAtPath:pathToMovie]){
        DVLog(@"final check : YEAH video file created, will be exported");
        DVLog(@"final check : movie %d  compatible ?",UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (pathToMovie));
        
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum (pathToMovie)) {
            UISaveVideoAtPathToSavedPhotosAlbum (pathToMovie,self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
        
    }
    else{
        DVLog(@"final check : file dosen't exist");
    }
}

-(void)video:(NSString*)videoPath didFinishSavingWithError:(NSError*)error contextInfo:(void*)contextInfo{
    if (error) {
        DVLog(@"Video Saving Failed :%@",error.localizedDescription);
    }else{
        
        DVLog(@"Saved to photo album");
        if([[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:&error] != YES){
            DVLog(@"---> File already exists at pathToMovie");
        }
    }
}

-(void)newFrame:(CVPixelBufferRef) pixelBuffer ReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    if (!isMovieRecording /* or paused*/){// return and free pixel buffer
       // DVLog(@"movie recording not started yet");
        return;
    }
    
    if ( (CMTIME_IS_INVALID(frameTime)) || (CMTIME_COMPARE_INLINE(frameTime, ==, previousFrameTime)) || (CMTIME_IS_INDEFINITE(frameTime)) ){
        DVLog(@"frameTime problem");
        return;
    }
    
    if (CMTIME_IS_INVALID(startTime)) // first frame
    {
        DVLog(@"recording videoSize : %dx%d",(int)CVPixelBufferGetWidth(pixelBuffer),(int)CVPixelBufferGetHeight(pixelBuffer));
        BEGIN_MOVIE_WRITING_QUEUE

        if(videoWriter.status != AVAssetWriterStatusWriting)
        {
            [videoWriter startWriting];
        }
        
        [videoWriter startSessionAtSourceTime:frameTime];
        startTime = frameTime;
        END_MOVIE_WRITING_QUEUE
    }
    
    BEGIN_MOVIE_WRITING_QUEUE
    if (!writerInput.readyForMoreMediaData) // we are encoding live media
    {
        NSLog(@"1: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
        return;
    }
    
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    void(^write)() = ^() {
        if (!writerInput.readyForMoreMediaData)
        {
            NSLog(@"2: Had to drop a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
        }
        else if(videoWriter.status == AVAssetWriterStatusWriting)
        {
            if (![assetWriterPixelBufferInput appendPixelBuffer:pixelBuffer withPresentationTime:frameTime])
            {
                NSLog(@"Problem appending pixel buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
            }else{
                NSLog(@"writing ok");
            }
        }
        else
        {
            NSLog(@"Couldn't write a frame");
            //NSLog(@"Wrote a video frame: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, frameTime)));
        }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        
        previousFrameTime = frameTime;
    };
    write();
    
    END_MOVIE_WRITING_QUEUE
}

@end
