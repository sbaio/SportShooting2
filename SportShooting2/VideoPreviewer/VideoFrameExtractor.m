//
//  Video.m
//  iFrameExtractor
//
//  Created by lajos on 1/10/10.
//  Copyright 2010 www.codza.com. All rights reserved.
//

#import "VideoFrameExtractor.h"
#import <sys/time.h>

@implementation VideoFrameExtractor

-(void)getYuvFrame:(VideoFrameYUV *)yuv
{
    @synchronized (self) {
        if(!_pFrame) return ;
        
        if(yuv->luma != NULL && yuv->width != _pCodecCtx->width)
        {
            free(yuv->luma);
            free(yuv->chromaB);
            free(yuv->chromaR);
            
            yuv->luma = NULL;
            yuv->chromaB = NULL;
            yuv->chromaR = NULL;
        }
        
        if(yuv->luma == NULL)
        {
            yuv->luma = (uint8_t*) malloc(_pCodecCtx->width * _pCodecCtx->height);
            yuv->chromaB = (uint8_t*) malloc(_pCodecCtx->width * _pCodecCtx->height/4);
            yuv->chromaR = (uint8_t*) malloc(_pCodecCtx->width * _pCodecCtx->height/4);
        }
        
#define _CP_YUV_FRAME_(dst, src, linesize, width, height) \
do{ \
uint8_t * dd = (uint8_t* ) dst; \
uint8_t * ss = (uint8_t* ) src; \
int ll = linesize; \
int ww = width; \
int hh = height; \
for(int i = 0 ; i < hh ; ++i) \
{ \
memcpy(dd, ss, width); \
dd += ww; \
ss += ll; \
} \
}while(0)
        
        _CP_YUV_FRAME_(yuv->luma, _pFrame->data[0], _pFrame->linesize[0], _pCodecCtx->width, _pCodecCtx->height);
        
        _CP_YUV_FRAME_(yuv->chromaB, _pFrame->data[1], _pFrame->linesize[1], _pCodecCtx->width/2, _pCodecCtx->height/2);
        _CP_YUV_FRAME_(yuv->chromaR, _pFrame->data[2], _pFrame->linesize[2], _pCodecCtx->width/2, _pCodecCtx->height/2);
        
#undef _CP_YUV_FRAME_
        
        yuv->lz = _pCodecCtx->width*_pCodecCtx->height;
        yuv->bz = _pCodecCtx->width*_pCodecCtx->height/4;
        yuv->rz = _pCodecCtx->width*_pCodecCtx->height/4;
        yuv->width = _pCodecCtx->width;
        yuv->height = _pCodecCtx->height - 3;
    }
}

-(int)decode:(uint8_t*)buf length:(int)length callback:(void(^)(BOOL b))callback
{
    @synchronized (self)
    {
        if(_pCodecCtx == NULL) return false;
        int paserLength_In = length;
        int paserLen;
        int decode_data_length;
        int got_picture = 0;
        uint8_t *paserBuffer_In = buf;
        while (paserLength_In > 0)
        {
            AVPacket packet;
            av_init_packet(&packet);
            paserLen = av_parser_parse2(_pCodecPaser, _pCodecCtx, &packet.data, &packet.size, paserBuffer_In, paserLength_In, AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);
            paserLength_In -= paserLen;
            paserBuffer_In += paserLen;
            
            if (packet.size > 0)
            {
                if(_delegate!=nil && [_delegate respondsToSelector:@selector(processVideoData:length:)]){
                    [_delegate processVideoData:packet.data length:packet.size];
                }                
                
                decode_data_length = avcodec_decode_video2(_pCodecCtx, _pFrame, &got_picture, &packet);
            }
            else
            {
                break;
            }
            
            av_free_packet(&packet);
            _outputWidth = _pCodecCtx->width;
            
            
            if(!got_picture)
            {
                _frameNumber = 0;
                callback(NO);
            }
            else
            {
                _frameNumber ++;
                if(_delegate!=nil && [_delegate respondsToSelector:@selector(gotpFrame:number:)]){
                    
                    [_delegate gotpFrame:_pFrame number:_frameNumber]; //always in the dispatch queue?
                    //NSLog(@"framenumber %d",_frameNumber);
                }
                callback(YES);
                
            }
        }
        
        if(!got_picture)
            return NO;
        
        if (!_pFrame->data[0])
            return NO;
    }
    return  YES;
}

-(int)parse:(uint8_t*)buf length:(int)length callback:(void(^)(uint8_t* frame, int length, int frame_width, int frame_height))callback
{
    @synchronized (self)
    {
        if(_pCodecCtx == NULL) return false;
        
        int paserLength_In = length;
        int paserLen;
        uint8_t *paserBuffer_In = buf;
        
        while (paserLength_In > 0) {
            AVPacket packet;
            av_init_packet(&packet);
            paserLen = av_parser_parse2(_pCodecPaser, _pCodecCtx, &packet.data, &packet.size, paserBuffer_In, paserLength_In, AV_NOPTS_VALUE, AV_NOPTS_VALUE, AV_NOPTS_VALUE);
            paserLength_In -= paserLen;
            paserBuffer_In += paserLen;
            
            if (packet.size > 0) {
                if (callback) {
                    callback(packet.data, packet.size, _pCodecPaser->width_in_pixel, _pCodecPaser->height_in_pixel);
                }
            } else {
                break;
            }
            
            av_free_packet(&packet);
            _outputWidth = _pCodecPaser->width_in_pixel;
            _outputHeight = _pCodecPaser->height_in_pixel;
        }
    }
    return  YES;
}


-(id)initExtractor
{
    @synchronized (self)
    {
        AVCodec *pCodec;
        if(_pFrame == NULL)
        {
            av_register_all();
            
            pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
            _pCodecCtx = avcodec_alloc_context3(pCodec);
            _pFrame = avcodec_alloc_frame();
            _pCodecPaser = av_parser_init(AV_CODEC_ID_H264);
            if (_pCodecPaser == NULL) {
                 NSLog(@"Can't find H264 frame paser!");
            }
            _pCodecCtx->flags2|=CODEC_FLAG2_FAST;
            _pCodecCtx->thread_count = 2;
            _pCodecCtx->thread_type = FF_THREAD_FRAME;
            
            if(pCodec->capabilities&CODEC_FLAG_LOW_DELAY){
                _pCodecCtx->flags|=CODEC_FLAG_LOW_DELAY;
            }
            
            if (avcodec_open2(_pCodecCtx, pCodec, NULL) != 0) {
                 NSLog(@"Could not open codec");
            }
        }
    }
    return self;
}



-(void)freeExtractor
{
    @synchronized (self) {
        if (_pFrame)
            av_free(_pFrame);
        _pFrame = NULL;
        
        if (_pCodecCtx) {
            avcodec_close(_pCodecCtx);
            av_free(_pCodecCtx);
            _pCodecCtx = NULL;
        }
        if (_pCodecPaser) {
            av_parser_close(_pCodecPaser);
            av_free(_pCodecCtx);
            _pCodecPaser = NULL;
        }
    }
}

- (void)clearBuffer
{
    [self freeExtractor];
    @synchronized (self)
    {
        AVCodec *pCodec;
        if(_pFrame == NULL)
        {
            av_register_all();
            pCodec = avcodec_find_decoder(AV_CODEC_ID_H264);
            _pCodecCtx = avcodec_alloc_context3(pCodec);
            _pFrame = avcodec_alloc_frame();
            _pCodecPaser = av_parser_init(AV_CODEC_ID_H264);
            if (_pCodecPaser == NULL) {
                 NSLog(@"Can't find H264 frame paser!");
            }
            _pCodecCtx->flags2|=CODEC_FLAG2_FAST;
            _pCodecCtx->thread_count = 2;
            _pCodecCtx->thread_type = FF_THREAD_FRAME;
            
            if(pCodec->capabilities&CODEC_FLAG_LOW_DELAY){
                _pCodecCtx->flags|=CODEC_FLAG_LOW_DELAY;
            }
            
            if (avcodec_open2(_pCodecCtx, pCodec, NULL) != 0) {
                NSLog(@"Could not oped avcodec");
            }
        }
    }
}

-(void)dealloc
{
	[self freeExtractor];
}

@end
