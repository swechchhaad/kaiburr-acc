/* Copyright zeroRISC Inc. */
/* Modified by Authors of "Towards ML-KEM & ML-DSA on OpenTitan" (https://eprint.iacr.org/2024/1192). */
/* Copyright "Towards ML-KEM & ML-DSA on OpenTitan" Authors. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

.text

/*
 * cbd2
 *
 * NOTE: this keeps the name `cbd2` so it remains a drop-in for
 *       `poly_getnoise_cbd2` in poly.s, but it is obvious that it NO LONGER
 *       samples CBD. it samples the the distribution f(n) with
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
 * @param[in]  MOD: low 16-bit lane = q (already set when cbd2 is reached)
 *
 * clobbered registers: x4-x9, w0-w8, w28-w30
 */

.globl cbd2
cbd2:
    /* index GPRs for register-indirect load/store. */
    li x4, 0                  /* bn.lid x4 -> load into w0  */
    li x5, 1                  /* bn.sid x5 -> store from w1 */

    /* build per-lane masks inline from the all-zero reg (no const table):
       w30 = 0x00FF (low byte / C_FF), w29 = 0x007F (low 7 bits / C_LOW7),
       w28 = 0x0001 (bit 0 and the constant 1 / C_ONE).                      */
    bn.not     w30, w31           /* w30 = 0xFFFF per 16-bit lane */
    bn.shv.16H w30, w30 >> 8      /* w30 = 0x00FF */
    bn.shv.16H w29, w30 >> 1      /* w29 = 0x007F */
    bn.shv.16H w28, w30 >> 7      /* w28 = 0x0001 */

    /* 8 input regs (256 bytes) -> 16 output regs (256 coeffs). */
    LOOPI 8, 31
        bn.lid     x4, 0(x10++)   /* w0 = 32 random bytes */

        /* ---- even bytes: coefficient sits in low 8 bits of each lane ---- */
        bn.and     w1, w0, w30    /* c = byte & 0x00FF */
        /* CORE: w1(c) -> w1(coeff) */
        bn.and       w2, w1, w28  /* b   = c & 1                         */
        bn.and       w3, w1, w29  /* t   = c & 0x7F                      */
        bn.addv.16H  w3, w3, w28  /* t  += 1                             */
        bn.shv.16H   w3, w3 >> 7  /* ind = t >> 7  in {0,1}  (b0..b6 all-ones) */
        bn.shv.16H   w4, w3 << 1  /* mag = 2*ind                         */
        bn.addv.16H  w4, w4, w28  /* mag = 2*ind + 1                     */
        bn.subv.16H  w4, w4, w2   /* mag = 2*ind + 1 - b   in {0,1,2}    */
        bn.shv.16H   w5, w1 >> 7  /* s   = bit7    in {0,1}              */
        bn.subv.16H  w6, w31, w5  /* m   = 0 - s   = 0x0000 / 0xFFFF     */
        bn.subvm.16H w7, w31, w4  /* neg = (q - mag) mod q               */
        bn.xor       w8, w4, w7   /* diff = mag ^ neg                    */
        bn.and       w8, w8, w6   /* diff &= m                           */
        bn.xor       w1, w4, w8   /* coeff = mag if s=0 else neg, in [0,q) */
        bn.sid     x5, 0(x11++)   /* store 16 coeffs */

        /* ---- odd bytes: shift each lane down so high byte becomes the coeff -- */
        bn.shv.16H w1, w0 >> 8    /* c = byte >> 8 */
        bn.and       w2, w1, w28
        bn.and       w3, w1, w29
        bn.addv.16H  w3, w3, w28
        bn.shv.16H   w3, w3 >> 7
        bn.shv.16H   w4, w3 << 1
        bn.addv.16H  w4, w4, w28
        bn.subv.16H  w4, w4, w2
        bn.shv.16H   w5, w1 >> 7
        bn.subv.16H  w6, w31, w5
        bn.subvm.16H w7, w31, w4
        bn.xor       w8, w4, w7
        bn.and       w8, w8, w6
        bn.xor       w1, w4, w8
        bn.sid     x5, 0(x11++)
    ret

#if 0 /* eta=3 CBD sampler removed for now */
/*
 * cbd3
 *
 * Description: Given an array of uniformly random bytes, compute
 *              polynomial with coefficients distributed according to
 *              a centered binomial distribution with parameter eta=3.
 *              This function is only needed for Kyber-512
 *
 * Flags: Clobbers FG0, has no meaning beyond the scope of this subroutine.
 *
 * @param[in]  x10: dptr_input, dmem pointer to input byte array
 * @param[in]  x11: dptr_output, dmem pointer to output
 * @param[in]  x17: cbd2_const
 * @param[in]  w31: all-zero
 *
 * clobbered registers: x4-x30, w0-w31
 */

.globl cbd3
cbd3:
    /* Set up wide registers for input and intermediate states */
    li x4, 0
    li x5, 1
    li x6, 2
    li x19, 11
    li x20, 20
    li x21, 21

    /* Load cbd3_const */
    la x17, cbd3_const
    bn.lid x20, 0(x17++)
    bn.lid x21, 0(x17)

    LOOPI 2, 119
        /* Load inpput array of 2*256/4=128 bytes --> 4 wrs */
        bn.lid x4, 0(x10++)
        bn.lid x5, 0(x10++)
        bn.lid x6, 0(x10++)

        bn.and  w3, w0, w20       /* extract mod3=0 bit of w0 */
        bn.rshi w4, w31, w0 >> 1  /* w0 >> 1 */
        bn.and  w4, w4, w20       /* extract mod3=1 bit of w0 */
        bn.rshi w5, w31, w0 >> 2  /* w0 >> 1 */
        bn.and  w5, w5, w20       /* extract mod3=2 bit of w0 */
        bn.add  w3, w3, w4
        bn.add  w3, w3, w5        /* w3 stores 85 intermediate values */

        bn.rshi w0, w1, w0 >> 255 /* w0 stores last bit of old w0, and 255 bits of w1 */
        bn.and  w4, w0, w20       /* extract mod3=0 bit of w0 */
        bn.rshi w5, w31, w0 >> 1  /* w0 >> 1 */
        bn.and  w5, w5, w20       /* extract mod3=1 bit of w0 */
        bn.rshi w6, w31, w0 >> 2  /* w0 >> 2 */
        bn.and  w6, w6, w20       /* extract mod3=2 bit of w0 */
        bn.add  w4, w4, w5
        bn.add  w4, w4, w6        /* w4 stores 85 intermediate values */

        bn.rshi w0, w2, w1 >> 254 /* w0 stores 2 last bits of w1, and 254 bits of w2 */
        bn.and  w5, w0, w20       /* extract mod3=0 bit of w0 */
        bn.rshi w6, w31, w0 >> 1  /* w0 >> 1 */
        bn.and  w6, w6, w20       /* extract mod3=1 bit of w0 */
        bn.rshi w7, w31, w0 >> 2  /* w0 >> 2 */
        bn.and  w7, w7, w20       /* extract mod3=2 bit of w0 */
        bn.add  w5, w5, w6
        bn.add  w5, w5, w7        /* w5 stores 85 intermediate values */

        bn.rshi w0, w31, w2 >> 253 /* w0 stores 3 last bits of w2 */
        bn.and  w6, w0, w20       /* extract first bit of w0 */
        bn.rshi w0, w31, w0 >> 1  /* w0 >> 1 */
        bn.and  w7, w0, w20       /* extract second bit of w0 */
        bn.rshi w0, w31, w0 >> 1  /* w0 >> 1 */
        bn.and  w0, w0, w20       /* extract third bit of w0 */
        bn.add  w6, w6, w7
        bn.add  w6, w6, w0        /* w6 stores 1 intermediate value */

        bn.and  w0, w3, w21       /* and 0x000111 */
        bn.rshi w3, w31, w3 >> 3  /* w3 >> 3 */
        bn.and  w3, w3, w21       /* and 0x000111 */

        bn.and  w1, w4, w21       /* and 0x000111 */
        bn.rshi w4, w31, w4 >> 3  /* w4 >> 3 */
        bn.and  w4, w4, w21       /* and 0x000111 */

        bn.and  w2, w5, w21       /* and 0x000111 */
        bn.rshi w5, w31, w5 >> 3  /* w5 >> 3 */
        bn.and  w5, w5, w21       /* and 0x000111 */

        /* Compute 16*3=48 coeffs */
        LOOPI 2, 9
            LOOPI 16, 6
                bn.rshi w8, w0, w8 >> 6
                bn.rshi w9, w3, w9 >> 6
                bn.rshi w8, w31, w8 >> 10
                bn.rshi w9, w31, w9 >> 10
                bn.rshi w0, w31, w0 >> 6
                bn.rshi w3, w31, w3 >> 6
            bn.subvm.16H w11, w8, w9
            bn.sid x19, 0(x11++)
        LOOPI 10, 6
            bn.rshi w8, w0, w8 >> 6
            bn.rshi w9, w3, w9 >> 6
            bn.rshi w8, w31, w8 >> 10
            bn.rshi w9, w31, w9 >> 10
            bn.rshi w0, w31, w0 >> 6
            bn.rshi w3, w31, w3 >> 6
        bn.rshi w8, w0, w8 >> 16     /* w0 is free */
        bn.rshi w9, w1, w9 >> 6
        bn.rshi w9, w31, w9 >> 10
        bn.rshi w1, w31, w1 >> 6     /* shift out the first intermediate value */
        LOOPI 5, 6
            bn.rshi w8, w4, w8 >> 6
            bn.rshi w9, w1, w9 >> 6
            bn.rshi w8, w31, w8 >> 10
            bn.rshi w9, w31, w9 >> 10
            bn.rshi w1, w31, w1 >> 6
            bn.rshi w4, w31, w4 >> 6
        bn.subvm.16H w11, w8, w9
        bn.sid  x19, 0(x11++)

        /* Compute 16*3=48 coeffs */
        LOOPI 2, 9
            LOOPI 16, 6
                bn.rshi w8, w4, w8 >> 6
                bn.rshi w9, w1, w9 >> 6
                bn.rshi w8, w31, w8 >> 10
                bn.rshi w9, w31, w9 >> 10
                bn.rshi w1, w31, w1 >> 6
                bn.rshi w4, w31, w4 >> 6
            bn.subvm.16H w11, w8, w9
            bn.sid  x19, 0(x11++)
        LOOPI 5, 6
            bn.rshi w8, w4, w8 >> 6
            bn.rshi w9, w1, w9 >> 6
            bn.rshi w8, w31, w8 >> 10
            bn.rshi w9, w31, w9 >> 10
            bn.rshi w1, w31, w1 >> 6
            bn.rshi w4, w31, w4 >> 6
        LOOPI 11, 6
            bn.rshi w8, w2, w8 >> 6
            bn.rshi w9, w5, w9 >> 6
            bn.rshi w8, w31, w8 >> 10
            bn.rshi w9, w31, w9 >> 10
            bn.rshi w2, w31, w2 >> 6
            bn.rshi w5, w31, w5 >> 6
        bn.subvm.16H w11, w8, w9
        bn.sid  x19, 0(x11++)

        /* Compute 16*2=32 coeffs */
        LOOPI 16, 6
            bn.rshi w8, w2, w8 >> 6
            bn.rshi w9, w5, w9 >> 6
            bn.rshi w8, w31, w8 >> 10
            bn.rshi w9, w31, w9 >> 10
            bn.rshi w2, w31, w2 >> 6
            bn.rshi w5, w31, w5 >> 6
        bn.subvm.16H w11, w8, w9
        bn.sid  x19, 0(x11++)
        LOOPI 15, 6
            bn.rshi w8, w2, w8 >> 6
            bn.rshi w9, w5, w9 >> 6
            bn.rshi w8, w31, w8 >> 10
            bn.rshi w9, w31, w9 >> 10
            bn.rshi w2, w31, w2 >> 6
            bn.rshi w5, w31, w5 >> 6
        bn.rshi w8, w2, w8 >> 16
        bn.rshi w9, w6, w9 >> 16
        bn.subvm.16H w11, w8, w9
        bn.sid  x19, 0(x11++)
    ret
#endif
