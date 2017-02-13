#import "AudioGrabber.h"
//#import "WAVFileWriter.h"




@interface AudioGrabber()

@property (nonatomic,strong) NSMutableArray *observers;
@end




@implementation AudioGrabber
@synthesize aqc;
@synthesize audioDataLength;

static void AQInputCallback (void                   * inUserData,
                             AudioQueueRef          inAudioQueue,
                             AudioQueueBufferRef    inBuffer,
                             const AudioTimeStamp   * inStartTime,
                             UInt32          inNumPackets,
                             const AudioStreamPacketDescription * inPacketDesc)
{
    AudioGrabber * engine = (__bridge AudioGrabber *) inUserData;
    if (inNumPackets > 0)
    {
        [engine processAudioBuffer:inBuffer withQueue:inAudioQueue];
    }
    
    if (engine.aqc.run)
    {
        AudioQueueEnqueueBuffer(engine.aqc.queue, inBuffer, 0, NULL);
    }
}

- (id) init
{
    self = [super init];
    if (self)
    {
        aqc.mDataFormat.mSampleRate = kSamplingRate;
        aqc.mDataFormat.mFormatID = kAudioFormatLinearPCM;
        aqc.mDataFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger |kLinearPCMFormatFlagIsPacked;
        aqc.mDataFormat.mFramesPerPacket = 1;
        aqc.mDataFormat.mChannelsPerFrame = kNumberChannels;
        aqc.mDataFormat.mBitsPerChannel = kBitsPerChannels;
        aqc.mDataFormat.mBytesPerPacket = kBytesPerFrame;
        aqc.mDataFormat.mBytesPerFrame = kBytesPerFrame;
        aqc.bufferSize = kFrameSize;
        
        AudioQueueNewInput(&aqc.mDataFormat,
                           AQInputCallback,
                           (__bridge void *)(self),
                           NULL,
                           kCFRunLoopCommonModes,
                           0,
                           &aqc.queue);
        
        for (int i=0;i<kNumberBuffers;i++)
        {
            AudioQueueAllocateBuffer(aqc.queue, aqc.bufferSize, &aqc.mBuffers[i]);
            AudioQueueEnqueueBuffer(aqc.queue, aqc.mBuffers[i], 0, NULL);
        }
        aqc.recPtr = 0;
        aqc.run = 1;
        
        audioDataIndex = 0;
        //WAV file
    }
    
    return self;
}

- (void) dealloc
{
    AudioQueueStop(aqc.queue, true);
    aqc.run = 0;
    AudioQueueDispose(aqc.queue, true);
}


- (void)addObserver:(id<AudioGrabberProtocol>)observer
{
    @synchronized(self){
        NSMutableArray *observers = self.observers;
        if (!observers) {
            observers = [[NSMutableArray alloc] init];
            self.observers = observers;
        }
        
        
        [observers addObject:observer];
    }
}

- (void) start
{
    //启用下段代码，来创建wav文件
    /*AudioFileID outputFile;
    CFURLRef outputFileURL =
    CFURLCreateWithFileSystemPath(kCFAllocatorDefault, CFSTR("/Users/mac_dev/Desktop/output.wav"), kCFURLPOSIXPathStyle, FALSE);
    AudioFileCreateWithURL(outputFileURL, kAudioFileWAVEType, &aqc.mDataFormat, kAudioFileFlags_EraseFile, &outputFile);
    CFRelease(outputFileURL);
    aqc.outputFile = outputFile;*/

    AudioQueueStart(aqc.queue, NULL);
}

- (void) stop
{
    AudioQueueStop(aqc.queue, true);
    AudioFileID outputFile = aqc.outputFile;
    AudioFileClose(outputFile);
}

- (void) pause
{
    AudioQueuePause(aqc.queue);
}

- (Byte *)getBytes
{
    return audioByte;
}

- (void) processAudioBuffer:(AudioQueueBufferRef) buffer withQueue:(AudioQueueRef) queue
{
    //if (len != 960)
    //NSLog(@"processAudioData :%u", buffer->mAudioDataByteSize);
    //处理data：忘记oc怎么copy内存了，于是采用的C++代码，记得把类后缀改为.mm。同Play
    audioDataIndex +=buffer->mAudioDataByteSize;
    //AudioFileWriteBytes(aqc.outputFile, FALSE, audioDataIndex, &buffer->mAudioDataByteSize, buffer->mAudioData);
    
    //Report
    @synchronized(self) {
        for (id<AudioGrabberProtocol> observer in self.observers) {
            if ([observer respondsToSelector:@selector(audioDataArrived:length:)]) {
                [observer audioDataArrived:buffer->mAudioData length:buffer->mAudioDataByteSize];
            }
        }
    }
}

@end
