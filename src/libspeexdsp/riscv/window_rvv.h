/* RVV 内核：预加重分析前的窗函数应用（逐元素浮点乘，位精确）。
 * 语义等价于 preprocess_analysis() 里的
 *   st->frame[i] = MULT16_16_Q15(st->frame[i], st->window[i]);
 * 非定点构建下 MULT16_16_Q15(a,b) 就是 a*b，逐元素纯乘，
 * 向量化不改变任何单个元素的运算顺序与舍入，因此逐字节可比。
 */
#ifndef SPEEX_WINDOW_RVV_H
#define SPEEX_WINDOW_RVV_H
#include <riscv_vector.h>

static inline void spx_window_apply_rvv(float *frame, const float *window, int n)
{
    int i = 0;
    while (i < n)
    {
        size_t vl = __riscv_vsetvl_e32m4((size_t)(n - i));
        vfloat32m4_t f = __riscv_vle32_v_f32m4(frame + i, vl);
        vfloat32m4_t w = __riscv_vle32_v_f32m4(window + i, vl);
        __riscv_vse32_v_f32m4(frame + i, __riscv_vfmul_vv_f32m4(f, w, vl), vl);
        i += (int)vl;
    }
}
#endif
