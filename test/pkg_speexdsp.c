// speexdsp A/B 探针：回声消除（speex_echo）+ 预处理（speex_preprocess）全流程。
// 这两个模块内部是整数 FIR / 自适应滤波 / VAD，天然可 bit-exact，适合逐字节比。
// 输入用确定性 LCG 造远端/近端信号，回环 ITERS 帧后哈希输出 PCM。
#include <speex/speex_echo.h>
#include <speex/speex_preprocess.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#define FRAME 256
#define TAIL 1024
#define ITERS 200

static uint64_t fnv1a(const void *p, size_t n)
{
    const uint8_t *b = p;
    uint64_t h = 1469598103934665603ULL;
    for (size_t i = 0; i < n; i++) { h ^= b[i]; h *= 1099511628211ULL; }
    return h;
}

int main(int argc, char **argv)
{
    const char *outp = argc > 1 ? argv[1] : NULL;

    SpeexEchoState *echo = speex_echo_state_init(FRAME, TAIL);
    if (!echo) { fprintf(stderr, "echo init 失败\n"); return 2; }
    SpeexPreprocessState *pp = speex_preprocess_state_init(FRAME, 16000);
    if (!pp) { fprintf(stderr, "preprocess init 失败\n"); return 2; }

    spx_int32_t rate = 16000;
    speex_echo_ctl(echo, SPEEX_ECHO_SET_SAMPLING_RATE, &rate);
    /* 把 echo state 挂给预处理，触发 residual echo suppression 分支 */
    speex_preprocess_ctl(pp, SPEEX_PREPROCESS_SET_ECHO_STATE, echo);

    short play[FRAME], rec[FRAME], out[FRAME];
    FILE *f = NULL;
    if (outp) {
        f = fopen(outp, "wb");
        if (!f) { fprintf(stderr, "打不开 %s\n", outp); return 5; }
    }

    for (int it = 0; it < ITERS; it++) {
        for (int i = 0; i < FRAME; i++) {
            unsigned int n = (unsigned int)(it * FRAME + i);
            unsigned int r = n * 1103515245u + 12345u;
            play[i] = (short)(r >> 16);
            /* 近端 = 远端衰减回声 + 一点噪声：既要有可消的回声，也不至于全零 */
            int e = ((int)play[i] * 3) / 8;
            rec[i] = (short)(e + (int)((r >> 8) & 0x1ff) - 0x100);
        }
        speex_echo_cancellation(echo, rec, play, out);
        speex_preprocess_run(pp, out);
        if (f) fwrite(out, sizeof out, 1, f);
    }
    if (f) fclose(f);

    uint64_t h = 0;
    /* 单独再跑一遍取整段哈希（数据量小，重复计算可接受） */
    {
        FILE *rf = outp ? fopen(outp, "rb") : NULL;
        if (rf) {
            uint64_t acc = 1469598103934665603ULL;
            short buf[FRAME];
            while (fread(buf, sizeof buf, 1, rf) == 1) {
                acc ^= fnv1a(buf, sizeof buf);
                acc *= 1099511628211ULL;
            }
            fclose(rf);
            h = acc;
        }
    }
    printf("frames=%d fnv_out=%016llx\n", ITERS, (unsigned long long)h);

    speex_preprocess_state_destroy(pp);
    speex_echo_state_destroy(echo);
    return 0;
}
