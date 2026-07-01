/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * unit test for the f6 noise sampler (n=6, 3 bytes -> 4 coeffs) in isolation.
 * checks group 0 (w0), group 2 (the w0/w1 straddle),
 * group 7 (w2), and group 15 (w5).
 *   w0  = coeffs 0-15    w2 = coeffs 32-47
 *   w7  = coeffs 112-127 w15 = coeffs 240-255
 * Valid f6 lanes are only {0x0000,0x0001,0x0002,0x0cff,0x0d00}.
 */

.section .text.start

.globl main
main:
  la   x2, stack_end
  jal  x1, _init_state          /* MOD = r|q, w31 = 0 */
  la   x10, f6_input
  la   x11, f6_output
  jal  x1, f6

  la     x6, f6_output
  li     x4, 0
  bn.lid x4, 0(x6)              /* w0  = coeffs 0-15   */
  la     x6, f6_output
  addi   x6, x6, 64
  li     x4, 2
  bn.lid x4, 0(x6)              /* w2  = coeffs 32-47  */
  la     x6, f6_output
  addi   x6, x6, 224
  li     x4, 7
  bn.lid x4, 0(x6)              /* w7  = coeffs 112-127 */
  la     x6, f6_output
  addi   x6, x6, 480
  li     x4, 15
  bn.lid x4, 0(x6)              /* w15 = coeffs 240-255 */
  ecall

_init_state:
  bn.xor  w31, w31, w31
  li      x5, 2
  la      x6, modulus
  bn.lid  x5++, 0(x6)
  la      x6, modulus_inv
  bn.lid  x5, 0(x6)
  bn.or   w2, w2, w3 << 32
  bn.wsrw 0x0, w2
  ret

.data
.balign 32
.global stack
stack:
  .zero 1024
stack_end:

.balign 32
f6_input:
  .byte 3, 10, 17, 24, 31, 38, 45, 52, 59, 66, 73, 80, 87, 94, 101, 108
  .byte 115, 122, 129, 136, 143, 150, 157, 164, 171, 178, 185, 192, 199, 206, 213, 220
  .byte 227, 234, 241, 248, 255, 6, 13, 20, 27, 34, 41, 48, 55, 62, 69, 76
  .byte 83, 90, 97, 104, 111, 118, 125, 132, 139, 146, 153, 160, 167, 174, 181, 188
  .byte 195, 202, 209, 216, 223, 230, 237, 244, 251, 2, 9, 16, 23, 30, 37, 44
  .byte 51, 58, 65, 72, 79, 86, 93, 100, 107, 114, 121, 128, 135, 142, 149, 156
  .byte 163, 170, 177, 184, 191, 198, 205, 212, 219, 226, 233, 240, 247, 254, 5, 12
  .byte 19, 26, 33, 40, 47, 54, 61, 68, 75, 82, 89, 96, 103, 110, 117, 124
  .byte 131, 138, 145, 152, 159, 166, 173, 180, 187, 194, 201, 208, 215, 222, 229, 236
  .byte 243, 250, 1, 8, 15, 22, 29, 36, 43, 50, 57, 64, 71, 78, 85, 92
  .byte 99, 106, 113, 120, 127, 134, 141, 148, 155, 162, 169, 176, 183, 190, 197, 204
  .byte 211, 218, 225, 232, 239, 246, 253, 4, 11, 18, 25, 32, 39, 46, 53, 60

.balign 32
f6_output:
  .zero 512
