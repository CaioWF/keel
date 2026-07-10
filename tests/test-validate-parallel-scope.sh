V="$HERE/../core/gates/validate-parallel-scope.mjs"

assert_file "$V" "validate-parallel-scope gate exists"

# partition: disjoint Task 1 + Task 2 batch together; overlapping Task 3 splits; broad Task 4 solo
S1="$(new_sandbox)"
cat > "$S1/tasks.md" <<'EOF'
# Tarefas
## Checklist de Implementação
- [ ] Task 1: modulo a (AC-1) [scope: src/a/**, tests/a/**]
- [ ] Task 2: modulo b (AC-2) [scope: src/b/**, tests/b/**]
- [ ] Task 3: toca a/x (AC-3) [scope: src/a/x.ts]
- [ ] Task 4: cross-cutting, sem scope
EOF
node "$V" partition "$S1/tasks.md" > "$S1/out.txt" 2>&1
assert_eq "0" "$?" "partition exits 0 on valid tasks.md"
assert_contains "$S1/out.txt" "paralelo ×2" "disjoint Task 1 + Task 2 batch in parallel"
assert_contains "$S1/out.txt" "Batch 1 (paralelo ×2): Task 1, Task 2" "batch 1 groups the two disjoint tasks"
assert_contains "$S1/out.txt" "Task 4: (sem scope)" "no-scope task reported solo"
rm -rf "$S1"

# partition: all scopes overlap -> no parallel batch
S2="$(new_sandbox)"
cat > "$S2/tasks.md" <<'EOF'
- [ ] Task 1: a (AC-1) [scope: src/core/**]
- [ ] Task 2: a2 (AC-2) [scope: src/core/util.ts]
EOF
node "$V" partition "$S2/tasks.md" > "$S2/out.txt" 2>&1
assert_contains "$S2/out.txt" "Nenhum batch >1" "overlapping scopes yield no parallel batch"
rm -rf "$S2"

# partition: malformed scope (missing ]) -> exit 1
S3="$(new_sandbox)"
printf -- '- [ ] Task 1: x (AC-1) [scope: src/a/**\n' > "$S3/tasks.md"
node "$V" partition "$S3/tasks.md" >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && pass "malformed scope fails (exit 1)" || fail "malformed scope should exit 1 (got $rc)"
rm -rf "$S3"

# check: files inside declared scope -> exit 0
node "$V" check "src/a/**, tests/a/**" src/a/x.ts tests/a/y.test.ts >/dev/null 2>&1
assert_eq "0" "$?" "in-scope files pass check"

# check: a file outside declared scope -> exit 1
node "$V" check "src/a/**" src/a/x.ts src/b/leak.ts >/dev/null 2>&1; rc=$?
[ "$rc" -eq 1 ] && pass "out-of-scope file fails check (exit 1)" || fail "out-of-scope file should exit 1 (got $rc)"

# check: ./-prefixed changed path normalizes and matches
node "$V" check "src/a/**" ./src/a/x.ts >/dev/null 2>&1
assert_eq "0" "$?" "leading ./ normalized in check"
