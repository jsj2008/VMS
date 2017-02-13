#ifndef __VIDEO_FRAME_TYPE_H__
#define __VIDEO_FRAME_TYPE_H__

#define VIDEO_SPS_FRAME 0
#define VIDEO_PPS_FRAME 1
#define VIDEO_I_FRAME 2
#define VIDEO_P_FRAME 3
#define VIDEO_B_FRAME 4
#define VIDEO_UNKNOWN_FRAME 5

int video_frame_type(unsigned char* video_data, int data_len);

#endif


