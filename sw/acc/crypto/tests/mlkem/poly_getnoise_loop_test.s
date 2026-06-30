/* Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham. */
/* Licensed under the Apache License, Version 2.0, see LICENSE for details. */
/* SPDX-License-Identifier: Apache-2.0 */

/*
 * poly_getnoise (f8) called from INSIDE a hardware LOOP, like keygen/encap do.
 *
 * Every passing f8 test called poly_getnoise via plain jal, never nested inside
 * an enclosing hardware LOOP. The real KEM calls it inside `LOOP x14, ...`, with
 * f8's own LOOPI loops nested under it. This replicates that: a 2-iteration LOOP
 * sampling nonces 0 and 1, checked against the same f(8) references the
 * straight-line poly_getnoise_test uses.
 *
 * If w10/w11 match, f8 is correct inside an enclosing loop too (so the bug is
 * not the loop context). If they differ, the enclosing-loop context corrupts
 * f8's output -- the remaining suspect.
 *   w10 = nonce 0, output word 0
 *   w11 = nonce 1, output word 0
 */

.section .text.start

.globl main
main:
  la   x2, stack_end
  jal  x1, _init_state            /* MOD = r|q, w31 = 0 */

  /* zero the seed and nonce buffers */
  bn.xor w0, w0, w0
  li     x4, 0
  la     x6, seed
  bn.sid x4, 0(x6)
  la     x6, nonce
  bn.sid x4, 0(x6)

  /* precompute addresses in callee-untouched regs (no `la` inside the LOOP) */
  la   x19, sqbuf
  la   x20, seed
  la   x21, nonce
  la   x11, outbuf                /* poly_getnoise advances x11 by 512/poly */
  li   x12, 0                     /* nonce counter */
  li   x14, 2                     /* 2 polys */

  LOOP x14, 7
    addi x6,  x19, 0              /* x6  = sqbuf (reset each iter)  */
    addi x10, x20, 0              /* x10 = seed                     */
    addi x13, x21, 0              /* x13 = nonce buffer             */
    sw   x12, 0(x13)              /* nonce buffer byte0 = counter   */
    jal  x1, poly_getnoise_init
    jal  x1, poly_getnoise
    addi x12, x12, 1

  /* check first output word of each poly */
  la     x6, outbuf
  li     x4, 10
  bn.lid x4, 0(x6)                /* w10 = nonce 0 poly, word 0 */
  la     x6, outbuf
  addi   x6, x6, 512
  li     x4, 11
  bn.lid x4, 0(x6)                /* w11 = nonce 1 poly, word 0 */

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
seed:
  .zero 32
.balign 32
nonce:
  .zero 32
.balign 32
sqbuf:
  .zero 256
.balign 32
outbuf:
  .zero 1024
