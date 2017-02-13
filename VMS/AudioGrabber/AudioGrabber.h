//
//  Record.h
//  AudioTest
//
//  Created by webseat2 on 13-10-15.
//  Copyright (c) 2013年 WebSeat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "AudioConstant.h"

// use Audio Queue

typedef struct AQCallbackStruct
{
    AudioStreamBasicDescription mDataFormat;
    AudioQueueRef               queue;
    AudioQueueBufferRef         mBuffers[kNumberBuffers];
    AudioFileID                 outputFile;
    
    UInt32               bufferSize;
    long long                   recPtr;
    int                         run;
    
} AQCallbackStruct;


@protocol AudioGrabberProtocol <NSObject>
- (void)audioDataArrived :(void *)bytes length :(int)length;
@end

@interface AudioGrabber : NSObject
{
    AQCallbackStruct aqc;
    AudioFileTypeID fileFormat;
    long audioDataLength;
    Byte audioByte[999999];
    long audioDataIndex;
}

- (id) init;
- (void) start;
- (void) stop;
- (void) pause;
- (Byte *) getBytes;
- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue;
- (void)addObserver :(id<AudioGrabberProtocol>)observer;

@property (assign) AudioQueueInputCallback inputCallback;
@property (nonatomic, assign) AQCallbackStruct aqc;
@property (nonatomic, assign) long audioDataLength;

@end




