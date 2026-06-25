/* Copyright zeroRISC Inc. */
/* Modified by Authors of "Towards ML-KEM & ML-DSA on OpenTitan" (https://eprint.iacr.org/2024/1192). */
/* Copyright "Towards ML-KEM & ML-DSA on OpenTitan" Authors. */
/* Modified by Ruben Niederhagen and Hoang Nguyen Hien Pham - authors of */
/* "Improving ML-KEM & ML-DSA on OpenTitan - Efficient Multiplication Vector Instructions for OTBN" */
/* (https://eprint.iacr.org/2025/2028). */
/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

.text

/*
 * Name:        pack_ciphertext
 *
 * Description: *removing compression* serialize the
 *              ciphertext as the concatenation of the uncompressed,
 *              serialized vector of polynomials b and the uncompressed,
 *              serialized polynomial v (full 12-bit coefficients, via
 *              poly_tobytes). output is (KYBER_K+1)*KYBER_POLYBYTES bytes.
 *
 * Arguments:   - uint8_t *r: pointer to the output serialized ciphertext
 *              - polyvec *b: pointer to the input vector of polynomials b
 *              - poly *v: pointer to the input polynomial v
 *
 * Flags: Clobbers FG0, has no meaning beyond the scope of this subroutine.
 *
 * @param[in]  x10: dptr_b, dmem pointer to input polyvec b (poly_b)
 * @param[in]  x11: dptr_v, dmem pointer to input polynomial v (poly_v)
 * @param[out] x12: dptr_output, dmem pointer to output byte array
 * @param[in]  x14: KYBER_K
 * @param[in]  w31: all-zero
 *
 * clobbered registers: x0-x30, w0-w31
 */

.globl pack_ciphertext
pack_ciphertext:
  /* set up registers for poly_tobytes */
  li x4, 0
  li x5, 1
  li x6, 2
  li x7, 3
  li x9, 5

  bn.xor w31, w31, w31

  add x13, x0, x12

  /* serialize the k polynomials of b. the input pointer x10 is
   * already poly_b (passed by the caller); x10 and x13 auto-advance per call. */
  LOOP x14, 2
    jal x1, poly_tobytes
    nop

  /* v lives in a separate buffer (poly_v, passed in x11),
   * so repoint the input pointer before serializing it. */
  add x10, x0, x11
  jal x1, poly_tobytes
  ret


/*
 * Name:        unpack_ciphertext
 *
 * Description: de-serialize the ciphertext into the k+1 polynomials
 *              at full 12-bit precision via poly_frombytes. inverse of the
 *              uncompressed pack_ciphertext. 
 *
 * Arguments:   - polyvec *b, poly *v: output polynomials (b followed by v)
 *              - const uint8_t *c: input serialized ciphertext byte array
 *
 * Flags: Clobbers FG0, has no meaning beyond the scope of this subroutine.
 *
 * @param[in]  x10: dptr_input, dmem pointer to input ciphertext byte array
 * @param[in]  x14: KYBER_K
 * @param[in]  x15: dptr_const_0x0fff, coefficient mask (0x0fff)
 * @param[out] x12: dptr_output, dmem pointer to output polynomials (b then v)
 * @param[in]  w31: all-zero
 *
 * clobbered registers: x0-x30, w0-w31
 */

.globl unpack_ciphertext
unpack_ciphertext:
  /* set up registers for poly_frombytes */
  li x4, 0
  li x5, 1
  li x6, 2
  li x7, 3
  li x8, 4
  bn.lid x7, 0(x15) /* w3 = const_0x0fff (coefficient mask) */

  /* zeroize w31 */
  bn.xor w31, w31, w31

  /* de-serialize the k+1 polynomials (b's k polynomials, then v) */
  addi x28, x14, 1
  LOOP x28, 2
    jal x1, poly_frombytes
    nop
  ret
