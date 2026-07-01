# Copyright zeroRISC Inc.
# Modified by Authors of "Towards ML-KEM & ML-DSA on OpenTitan" (https://eprint.iacr.org/2024/1192).
# Copyright "Towards ML-KEM & ML-DSA on OpenTitan" Authors.
# Modified by Ruben Niederhagen and Hoang Nguyen Hien Pham - authors of
# "Improving ML-KEM & ML-DSA on OpenTitan - Efficient Multiplication Vector Instructions for OTBN"
# (https://eprint.iacr.org/2025/2028).
# Copyright Ruben Niederhagen and Hoang Nguyen Hien Pham.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

load("@ot_python_deps//:requirements.bzl", "requirement")
load("//rules:acc.bzl", "acc_autogen_sim_test", "acc_binary", "acc_consttime_test", "acc_library", "acc_sim_test")

package(default_visibility = ["//visibility:public"])

MODE_FOR_PARAMS = {
    "kaiburr8": 24,
    "kaiburr6": 18,
}

NTESTS = 3

STATS = True  # makes tests run slower but logs detailed execution stats

# Key generation tests
py_binary(
    name = "mlkem_keypair_testgen",
    srcs = ["mlkem_keypair_testgen.py"],
    imports = [
        "../../../../../hw/ip/acc/util",
    ],
    deps = [
        "//hw/ip/acc/util/shared:testgen",
        requirement("kyber-py"),
    ],
)

[
    acc_autogen_sim_test(
        name = params + "_keypair_test" + str(i),
        srcs = ["mlkem_keypair_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_keypair_testgen",
        testgen_args = [params],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:keypair",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

# Encapsulation tests
py_binary(
    name = "mlkem_encap_testgen",
    srcs = ["mlkem_encap_testgen.py"],
    imports = [
        "../../../../../hw/ip/acc/util",
    ],
    deps = [
        "//hw/ip/acc/util/shared:testgen",
        requirement("kyber-py"),
    ],
)

[
    acc_autogen_sim_test(
        name = params + "_encap_test" + str(i),
        srcs = ["mlkem_encap_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_encap_testgen",
        testgen_args = [params],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:encap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

# Encapsulation tests
py_binary(
    name = "mlkem_decap_testgen",
    srcs = ["mlkem_decap_testgen.py"],
    imports = [
        "../../../../../hw/ip/acc/util",
    ],
    deps = [
        "//hw/ip/acc/util/shared:testgen",
        requirement("kyber-py"),
    ],
)

[
    acc_autogen_sim_test(
        name = params + "_decap_test" + str(i),
        srcs = ["mlkem_decap_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_decap_testgen",
        testgen_args = [params],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

[
    acc_autogen_sim_test(
        name = params + "_false_decap_test" + str(i),
        srcs = ["mlkem_decap_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        pqc = True,
        seed = i,
        stats = STATS,
        testgen = ":mlkem_decap_testgen",
        testgen_args = [
            "-i",
            params,
        ],
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for i in range(NTESTS)
    for params in MODE_FOR_PARAMS
]

# checks that the encapsulation and decapsulation shared secrets match
[
    acc_sim_test(
        name = params + "_roundtrip_test",
        srcs = ["mlkem_roundtrip_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        exp = "mlkem_roundtrip_test.exp",
        pqc = True,
        # raising the timeout
        stats = False,
        timeout = "eternal",
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:encap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:keypair",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for params in MODE_FOR_PARAMS
]

# benchmark: same self-contained keygen->encap->decap roundtrip, but with
# execution stats enabled so the simulator dumps per-function cycle counts.
# parse the test log with:
#   python3 hw/ip/acc/util/acc_profile.py \
#     bazel-testlogs/sw/acc/crypto/tests/mlkem/<name>/test.log
[
    acc_sim_test(
        name = params + "_bench",
        srcs = ["mlkem_roundtrip_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
        ],
        exp = "mlkem_roundtrip_test.exp",
        pqc = True,
        stats = True,
        timeout = "eternal",
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:encap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:keypair",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for params in MODE_FOR_PARAMS
]

# Per-stage benchmark variants of the same self-contained roundtrip, used to get
# per-operation cycle counts by subtraction:
#   <p>_bench_keygen        -> keygen only            (cycles = M1)
#   <p>_bench_keygen_encap  -> keygen + encap         (cycles = M2)
#   <p>_bench               -> keygen + encap + decap (cycles = M3)
#   keygen = M1 ; encap = M2 - M1 ; decap = M3 - M2
[
    acc_sim_test(
        name = params + "_bench_" + stage[0],
        srcs = ["mlkem_roundtrip_test.s"],
        copts = [
            "-DKYBER_K=" + str(MODE_FOR_PARAMS[params]),
            "-DBENCH_STAGE=" + str(stage[1]),
        ],
        exp = "mlkem_roundtrip_test.exp",
        pqc = True,
        stats = True,
        timeout = "eternal",
        deps = [
            "//sw/acc/crypto/mlkem:basemul",
            "//sw/acc/crypto/mlkem:cbd",
            "//sw/acc/crypto/mlkem:consts",
            "//sw/acc/crypto/mlkem:decap",
            "//sw/acc/crypto/mlkem:encap",
            "//sw/acc/crypto/mlkem:indcpa_enc",
            "//sw/acc/crypto/mlkem:intt",
            "//sw/acc/crypto/mlkem:keypair",
            "//sw/acc/crypto/mlkem:kmac_send_msg",
            "//sw/acc/crypto/mlkem:ntt",
            "//sw/acc/crypto/mlkem:pack_ciphertext",
            "//sw/acc/crypto/mlkem:pack_keys",
            "//sw/acc/crypto/mlkem:poly",
            "//sw/acc/crypto/mlkem:poly_gen_matrix",
        ],
    )
    for params in MODE_FOR_PARAMS
    for stage in [
        ("keygen", 1),
        ("keygen_encap", 2),
    ]
]

# unit test for the f6 noise sampler (n=6, 3 bytes -> 4 coeffs) in isolation.
acc_sim_test(
    name = "f6_test",
    srcs = ["f6_test.s"],
    exp = "f6_test.exp",
    pqc = True,
    stats = False,
    deps = [
        "//sw/acc/crypto/mlkem:cbd",
        "//sw/acc/crypto/mlkem:consts",
    ],
)
