/* Copyright zeroRISC Inc. */
/* Modified by Authors of "Towards ML-KEM & ML-DSA on OpenTitan" (https://eprint.iacr.org/2024/1192). */
/* Copyright "Towards ML-KEM & ML-DSA on OpenTitan" Authors. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

.text

/*
 * f8
 *
 *       this samples the distribution f(n) with
 *       n = 8, per coefficient:
 *           draw 8 random bits b0..b7
 *           sign      = (-1)^b7
 *           magnitude = (1 - b0) + 2 * [b0..b6 all ones]   (in {0,1,2})
 *           coeff     = sign * magnitude   (reduced into [0,q))
 *       => P(0) = 1/2 - 2^-7, P(+-1) = 1/4, P(+-2) = 2^-8.
 *
 * distribution  is symmetric, so the (-1)^b7 sign convention below (b7=1 => negate)
 * matches f(n).
 *
 * layout: one coefficient per 16-bit lane. each input byte is one coefficient,
 *         so this consumes 256 input bytes (8 wide regs) and produces 256
 *         coefficients (16 wide regs).
 *
 * Arguments:   - poly *r: pointer to output polynomial
 *              - const uint8_t *buf: pointer to input byte array (>= 256 bytes)
 *
 * Flags: Clobbers FG0, has no meaning beyond the scope of this subroutine.
 *
 * @param[in]  x10: dptr_input, dmem pointer to input byte array
 * @param[in]  x11: dptr_output, dmem pointer to output
 * @param[in]  w31: all-zero
 * @param[in]  MOD: low 16-bit lane = q (already set when f8 is reached)
 *
 * clobbered registers: x4, x6, w0-w8
 *
 */

.globl f8
f8:
    /* zeroing w31 here here to be self-sufficient and restore the all-zero
       convention. */
    bn.xor w31, w31, w31

    /* index GPRs: input -> w0, output -> w2; mask constants in w3/w4/w5. */
    li x4, 0
    li x6, 2

    bn.not     w3, w31        /* w3 = 0xFFFF per 16-bit lane */
    bn.shv.16H w3, w3 >> 8    /* w3 = 0x00FF */
    bn.shv.16H w4, w3 >> 1    /* w4 = 0x007F */
    bn.shv.16H w5, w3 >> 7    /* w5 = 0x0001 */

    /* 8 input regs (256 bytes) -> 16 output regs (256 coeffs), natural order. */
    LOOPI 8, 37
        bn.lid       x4, 0(x10++)  /* w0 = 32 random bytes b0..b31 */

        /* spread low 16 bytes b0..b15 into w1 lanes 0..15 (natural) */
        LOOPI 16, 3
            bn.rshi  w1, w0, w1 >> 8
            bn.rshi  w1, w31, w1 >> 8
            bn.rshi  w0, w31, w0 >> 8
        bn.and       w6, w1, w5    /* b   = c & 1                          */
        bn.and       w7, w1, w4    /* t   = c & 0x7F                       */
        bn.addv.16H  w7, w7, w5    /* t  += 1                              */
        bn.shv.16H   w7, w7 >> 7   /* ind = t >> 7  in {0,1}               */
        bn.shv.16H   w8, w7 << 1   /* mag = 2*ind                          */
        bn.addv.16H  w8, w8, w5    /* mag = 2*ind + 1                      */
        bn.subv.16H  w8, w8, w6    /* mag = 2*ind + 1 - b   in {0,1,2}     */
        bn.shv.16H   w6, w1 >> 7   /* s   = bit7    in {0,1}               */
        bn.subv.16H  w6, w31, w6   /* m   = 0 - s   = 0x0000 / 0xFFFF      */
        bn.subvm.16H w7, w31, w8   /* neg = (q - mag) mod q                */
        bn.xor       w2, w8, w7    /* diff = mag ^ neg                     */
        bn.and       w2, w2, w6    /* diff &= m                            */
        bn.xor       w2, w8, w2    /* coeff = mag if s=0 else neg          */
        bn.sid       x6, 0(x11++)

        /* spread high 16 bytes b16..b31 (now low in w0) into w1 */
        LOOPI 16, 3
            bn.rshi  w1, w0, w1 >> 8
            bn.rshi  w1, w31, w1 >> 8
            bn.rshi  w0, w31, w0 >> 8
        bn.and       w6, w1, w5
        bn.and       w7, w1, w4
        bn.addv.16H  w7, w7, w5
        bn.shv.16H   w7, w7 >> 7
        bn.shv.16H   w8, w7 << 1
        bn.addv.16H  w8, w8, w5
        bn.subv.16H  w8, w8, w6
        bn.shv.16H   w6, w1 >> 7
        bn.subv.16H  w6, w31, w6
        bn.subvm.16H w7, w31, w8
        bn.xor       w2, w8, w7
        bn.and       w2, w2, w6
        bn.xor       w2, w8, w2
        bn.sid       x6, 0(x11++)
    ret

/*
 * f6
 *
 *       samples the distribution f(n) with n = 6, per coefficient:
 *           draw 6 random bits b0..b5
 *           sign      = (-1)^b5
 *           magnitude = (1 - b0) + 2 * [b0..b4 all ones]   (in {0,1,2})
 *           coeff     = sign * magnitude   (reduced into [0,q))
 *       => P(0) = 1/2 - 2^-5, P(+-1) = 1/4, P(+-2) = 2^-6.
 * note: f6 packs 4 coeffs per 3 bytes, so it
 * consumes 256*6/8 = 192 input bytes (6 wide regs) and produces 256 coeffs
 * (16 wide regs). cbd3-style 6-bit unpacking combined with the f8
 * arithmetic.
 *
 * @param[in]  x10: dptr_input, dmem pointer to input byte array (>= 192 bytes)
 * @param[in]  x11: dptr_output, dmem pointer to output
 * @param[in]  w31: all-zero (f6 zeroes it itself, like f8)
 * @param[in]  MOD: low 16-bit lane = q (already set when f6 is reached)
 *
 * clobbered registers: x4 to x7, w0 to w10
 */
.globl f6
f6:
    /* re-establish the all-zero convention */
    bn.xor w31, w31, w31

    li x4, 0                    /* load idx  -> w0            */
    li x5, 1                    /*           -> w1            */
    li x6, 2                    /*           -> w2            */
    li x7, 10                   /* store idx -> w10           */

    /* masks (per 16-bit lane): w4 = 0x001F, w5 = 0x0001 */
    bn.not     w3, w31          /* 0xFFFF                     */
    bn.shv.16H w4, w3 >> 11     /* 0x001F  (low 5 bits)       */
    bn.shv.16H w5, w3 >> 15     /* 0x0001                     */

    /* 2 halves of 128 coeffs; each half = 96 input bytes = 3 wregs */
    LOOPI 2, 24
        bn.lid x4, 0(x10++)     /* w0 = stream[  0:255]       */
        bn.lid x5, 0(x10++)     /* w1 = stream[256:511]       */
        bn.lid x6, 0(x10++)     /* w2 = stream[512:767]       */

        /* 8 output regs of 16 coeffs each */
        LOOPI 8, 20
            /* spread 16 raw 6-bit fields -> 16 zero-ext lanes in w9,
               advancing the w0<-w1<-w2 pipeline by 6 bits per lane   */
            LOOPI 16, 5
                bn.rshi w9, w0,  w9 >> 6    /* 6 data bits -> top lane */
                bn.rshi w9, w31, w9 >> 10   /* zero-extend to 16 bits  */
                bn.rshi w0, w1,  w0 >> 6    /* w0 pulls 6 from w1      */
                bn.rshi w1, w2,  w1 >> 6    /* w1 pulls 6 from w2      */
                bn.rshi w2, w31, w2 >> 6    /* w2 drains with zeros    */

            /* per-coefficient kernel, identical to f8 except 0x1F / >>5 */
            bn.and       w6,  w9, w5   /* b   = c & 1                 */
            bn.and       w7,  w9, w4   /* t   = c & 0x1F              */
            bn.addv.16H  w7,  w7, w5   /* t  += 1                     */
            bn.shv.16H   w7,  w7 >> 5  /* ind = t >> 5  in {0,1}      */
            bn.shv.16H   w8,  w7 << 1  /* mag = 2*ind                 */
            bn.addv.16H  w8,  w8, w5   /* mag = 2*ind + 1             */
            bn.subv.16H  w8,  w8, w6   /* mag = 2*ind + 1 - b         */
            bn.shv.16H   w6,  w9 >> 5  /* s   = bit5    in {0,1}      */
            bn.subv.16H  w6,  w31, w6  /* m   = 0 - s                 */
            bn.subvm.16H w7,  w31, w8  /* neg = (q - mag) mod q       */
            bn.xor       w10, w8,  w7  /* diff = mag ^ neg            */
            bn.and       w10, w10, w6  /* diff &= m                   */
            bn.xor       w10, w8,  w10 /* coeff = mag if s=0 else neg */

            bn.sid x7, 0(x11++)
    ret
