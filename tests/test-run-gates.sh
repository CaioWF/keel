G="$HERE/../core/gates/run-gates.sh"

# helper: drop a scoped `make` shim into <sandbox>/bin (system has no make)
_make_shim() { # sandbox_dir
  mkdir -p "$1/bin"
  cat > "$1/bin/make" <<'SHIM'
#!/usr/bin/env bash
t="$1"
[ -f Makefile ] || exit 1
grep -qE "^$t:" Makefile || exit 1
cmd=$(grep -A1 "^$t:" Makefile | tail -1 | sed 's/^[[:space:]]*@*//')
bash -c "$cmd"
SHIM
  chmod +x "$1/bin/make"
}

# no checks -> exit 0
S1="$(new_sandbox)"
( cd "$S1" && bash "$G" >/dev/null 2>&1 ); assert_eq "0" "$?" "no checks detected exits 0"
rm -rf "$S1"

# failing make test -> exit non-zero
S2="$(new_sandbox)"; _make_shim "$S2"
printf 'test:\n\t@exit 3\n' > "$S2/Makefile"
( cd "$S2" && PATH="$S2/bin:$PATH" bash "$G" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "failing make test propagates non-zero" || fail "should fail on make test exit 3"
rm -rf "$S2"

# passing make test -> exit 0
S3="$(new_sandbox)"; _make_shim "$S3"
printf 'test:\n\t@true\n' > "$S3/Makefile"
( cd "$S3" && PATH="$S3/bin:$PATH" bash "$G" >/dev/null 2>&1 ); assert_eq "0" "$?" "passing make test exits 0"
rm -rf "$S3"

# build gate: make `build` target now runs (was previously lint/test only)
S4="$(new_sandbox)"; _make_shim "$S4"
printf 'build:\n\t@exit 5\n' > "$S4/Makefile"
( cd "$S4" && PATH="$S4/bin:$PATH" bash "$G" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "failing make build propagates non-zero" || fail "should fail on make build exit 5"
rm -rf "$S4"

S5="$(new_sandbox)"; _make_shim "$S5"
printf 'build:\n\t@true\n' > "$S5/Makefile"
( cd "$S5" && PATH="$S5/bin:$PATH" bash "$G" >/dev/null 2>&1 ); assert_eq "0" "$?" "passing make build exits 0"
rm -rf "$S5"

# build gate: Go stack detected via go.mod, `go build ./...` invoked
_go_shim() { # sandbox_dir exit_code
  mkdir -p "$1/bin"
  printf '#!/usr/bin/env bash\n[ "$1" = "build" ] && exit %s\nexit 0\n' "$2" > "$1/bin/go"
  chmod +x "$1/bin/go"
}
S6="$(new_sandbox)"; _go_shim "$S6" 7
printf 'module x\n' > "$S6/go.mod"
( cd "$S6" && PATH="$S6/bin:$PATH" bash "$G" >/dev/null 2>&1 ); rc=$?
[ "$rc" -ne 0 ] && pass "failing go build propagates non-zero" || fail "should fail on go build exit 7"
rm -rf "$S6"

S7="$(new_sandbox)"; _go_shim "$S7" 0
printf 'module x\n' > "$S7/go.mod"
( cd "$S7" && PATH="$S7/bin:$PATH" bash "$G" >/dev/null 2>&1 ); assert_eq "0" "$?" "passing go build exits 0"
rm -rf "$S7"
