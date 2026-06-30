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
    /* temporary: this is cbd2's exact body (centered binomial,
       eta=2) under the f8 label, to isolate the SAMPLER/distribution from the
       rest of the f8 feature (the 256-byte squeeze + unified poly_getnoise +
       natural-order calling). cbd2 reads the first 128 of the 256 squeezed
       bytes and ignores the rest, producing the SAME noise as the working
       baseline. Interpretation:
         - roundtrip PASSES => the 256-byte squeeze + plumbing is fine, bug is
           the f8 sampler itself.
         - roundtrip FAILS  => the squeeze/structure is the bug (e.g. the 2-block
           squeeze corrupting a later Keccak op), independent of the sampler. */
    li x4, 0
    li x5, 1
    li x6, 2
    li x7, 3
    li x8, 4
    li x9, 5

    la x17, cbd2_const
    bn.lid x7, 0(x17++)
    bn.lid x8, 0(x17++)

    LOOPI 4, 19
        bn.lid  x4, 0(x10++)
        bn.and  w1, w0, w3
        bn.rshi w0, w31, w0 >> 1
        bn.and  w0, w0, w3
        bn.add  w0, w0, w1
        bn.and  w1, w0, w4
        bn.rshi w0, w31, w0 >> 2
        bn.and  w0, w0, w4

        LOOPI 4,  9
            LOOPI 16, 6
                bn.rshi w6, w1, w6 >> 4
                bn.rshi w7, w0, w7 >> 4
                bn.rshi w6, w31, w6 >> 12
                bn.rshi w7, w31, w7 >> 12
                bn.rshi w1, w31, w1 >> 4
                bn.rshi w0, w31, w0 >> 4
            bn.subvm.16H w2, w6, w7
            bn.sid x6, 0(x11++)
        NOP
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
