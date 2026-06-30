set -u
cd "$(dirname "$0")/../.."

params="${1:-kaiburr8}"
pkg="//sw/acc/crypto/tests/mlkem"

# Extract the cycle count (M) from a bench target's test log.
cycles() {
  local target="$1"
  ./bazelisk.sh test "$pkg:$target" --test_output=errors >/dev/null 2>&1 || true
  local log="bazel-testlogs/sw/acc/crypto/tests/mlkem/$target/test.log"
  if [ ! -f "$log" ]; then
    echo "ERROR: no test log for $target" >&2
    exit 1
  fi
  # line: "ACC executed <N> instructions in <M> cycles."
  grep -oE 'executed [0-9]+ instructions in [0-9]+ cycles' "$log" \
    | grep -oE 'in [0-9]+ cycles' | grep -oE '[0-9]+'
}

m1=$(cycles "${params}_bench_keygen")
m2=$(cycles "${params}_bench_keygen_encap")
m3=$(cycles "${params}_bench")

printf '\n%-10s %12s\n' "operation" "cycles"
printf '%-10s %12s\n'   "---------" "------------"
printf '%-10s %12d\n'   "keygen"  "$m1"
printf '%-10s %12d\n'   "encap"   "$((m2 - m1))"
printf '%-10s %12d\n'   "decap"   "$((m3 - m2))"
printf '%-10s %12d\n'   "roundtrip" "$m3"
echo
