#include <iostream>
#include <fstream>

extern "C" {
#include <libavformat/avformat.h>
#include <libavcodec/avcodec.h>     // 🔥 REQUIRED
#include <libavutil/motion_vector.h>
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        std::cout << "Usage: ./extract_mvs input_video\n";
        return -1;
    }

    AVFormatContext *fmt_ctx = nullptr;
    avformat_open_input(&fmt_ctx, argv[1], nullptr, nullptr);
    avformat_find_stream_info(fmt_ctx, nullptr);

    int video_stream_index = -1;
    for (unsigned int i = 0; i < fmt_ctx->nb_streams; i++) {
        if (fmt_ctx->streams[i]->codecpar->codec_type == AVMEDIA_TYPE_VIDEO) {
            video_stream_index = i;
            break;
        }
    }

    // 🔥 FIX: const AVCodec*
    const AVCodec *dec = avcodec_find_decoder(
        fmt_ctx->streams[video_stream_index]->codecpar->codec_id
    );

    AVCodecContext *dec_ctx = avcodec_alloc_context3(dec);
    avcodec_parameters_to_context(dec_ctx,
        fmt_ctx->streams[video_stream_index]->codecpar);

    // 🔥 ENABLE MOTION VECTOR EXPORT
    AVDictionary *opts = nullptr;
    av_dict_set(&opts, "flags2", "+export_mvs", 0);

    avcodec_open2(dec_ctx, dec, &opts);

    AVPacket pkt;
    AVFrame *frame = av_frame_alloc();

    std::ofstream outfile("data/mvs.txt");

    int frame_num = 0;
    while (av_read_frame(fmt_ctx, &pkt) >= 0) {
        if (pkt.stream_index == video_stream_index) {

            avcodec_send_packet(dec_ctx, &pkt);

            while (avcodec_receive_frame(dec_ctx, frame) == 0) {
                frame_num++;

                AVFrameSideData *sd =
                    av_frame_get_side_data(frame, AV_FRAME_DATA_MOTION_VECTORS);

                if (sd) {
                    const AVMotionVector *mvs =
                        (const AVMotionVector *)sd->data;

                    int mv_count = sd->size / sizeof(*mvs);

                    for (int i = 0; i < mv_count; i++) {
                        // Only extract 16x16 blocks (matching x264 embedding)
                        if (mvs[i].w == 16 && mvs[i].h == 16) {
                            outfile << frame_num << " "
                                    << mvs[i].dst_x << " "
                                    << mvs[i].dst_y << " "
                                    << mvs[i].motion_x << " "
                                    << mvs[i].motion_y << "\n";
                        }
                    }
                }
            }
        }
        av_packet_unref(&pkt);
    }

    outfile.close();

    av_frame_free(&frame);
    avcodec_free_context(&dec_ctx);
    avformat_close_input(&fmt_ctx);

    std::cout << "Motion vectors extracted to data/mvs.txt\n";
    return 0;
}