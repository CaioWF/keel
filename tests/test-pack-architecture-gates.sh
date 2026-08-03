# Test the architecture-gates pack: the dependency-rule gate, the pack.d seam that lets any
# pack contribute a gate, and the opt-in boundary (a stack signal must not install it).

AG_S="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$AG_S" >/dev/null 2>&1

# ---- the pack.d seam exists in core, independent of any pack ----
# It is what makes a pack gate survive an update: bootstrap rewrites run-gates.sh on every
# --force, so a pack that edited that file would be erased by the next one.
assert_contains "$AG_S/.specify/gates/run-gates.sh" "pack.d" "run-gates sweeps a pack.d directory"
assert_nofile "$AG_S/.specify/gates/pack.d/dependency-rule.mjs" "no pack gate before opting in"

# ---- install ----
bash "$HERE/../packs/architecture-gates/install.sh" --dir "$AG_S" >/dev/null 2>&1
assert_file "$AG_S/.specify/gates/pack.d/dependency-rule.mjs" "pack installs the gate into pack.d"
assert_file "$AG_S/.specify/architecture.json" "pack seeds the layer map"

AG_GATE="$AG_S/.specify/gates/pack.d/dependency-rule.mjs"

# ---- skips rather than fails when there is nothing to check ----
AG_OUT="$(cd "$AG_S" && node "$AG_GATE" . 2>&1)" && AG_RC=0 || AG_RC=1
assert_eq "0" "$AG_RC" "gate exits 0 when the project has no src/ yet"
case "$AG_OUT" in *skipped*) pass "gate says it skipped rather than passing silently" ;; *) fail "gate should report a skip (got: $AG_OUT)" ;; esac

mkdir -p "$AG_S/src/domain" "$AG_S/src/application" "$AG_S/src/infrastructure" "$AG_S/src/interface"

# ---- a tree that obeys the rule ----
printf 'export class Order {}\n' > "$AG_S/src/domain/order.ts"
printf 'import { Order } from "../domain/order";\nexport const place = (o: Order) => o;\n' > "$AG_S/src/application/place.ts"
printf 'import { place } from "../application/place";\nimport express from "express";\nexport const r = [place, express];\n' > "$AG_S/src/interface/http.ts"
printf 'export const db = 1;\n' > "$AG_S/src/infrastructure/db.ts"
# The composition root sits outside every declared layer and must stay unchecked: wiring
# concrete infra into use cases is exactly what it exists to do.
printf 'import { r } from "./interface/http";\nimport { db } from "./infrastructure/db";\nexport const app = [r, db];\n' > "$AG_S/src/main.ts"
( cd "$AG_S" && node "$AG_GATE" . >/dev/null 2>&1 ) && AG_RC=0 || AG_RC=1
assert_eq "0" "$AG_RC" "inward-pointing imports pass, composition root exempt"

# ---- violations ----
printf 'import { db } from "../infrastructure/db";\nexport class Bad {}\n' > "$AG_S/src/domain/bad.ts"
AG_OUT="$(cd "$AG_S" && node "$AG_GATE" . 2>&1)" && AG_RC=0 || AG_RC=1
assert_eq "1" "$AG_RC" "an outward import fails the gate"
case "$AG_OUT" in *"src/domain/bad.ts:1"*) pass "violation is reported at file:line" ;; *) fail "violation should carry file:line (got: $AG_OUT)" ;; esac
rm -f "$AG_S/src/domain/bad.ts"

# External packages are an allow-list: domain declares what it may import and defaults to
# nothing, so a package entering the ecosystem later is caught instead of passing silently.
printf 'import { z } from "zod";\nexport const s = z;\n' > "$AG_S/src/domain/schema.ts"
( cd "$AG_S" && node "$AG_GATE" . >/dev/null 2>&1 ) && AG_RC=0 || AG_RC=1
assert_eq "1" "$AG_RC" "an external import into a layer that allows none fails"
rm -f "$AG_S/src/domain/schema.ts"

# ---- things that must NOT be violations ----
printf '// import { db } from "../infrastructure/db";\n/* import { db } from "../infrastructure/db"; */\nexport const ok = 1;\n' > "$AG_S/src/domain/commented.ts"
printf 'import { join } from "node:path";\nexport const j = join;\n' > "$AG_S/src/domain/builtin.ts"
( cd "$AG_S" && node "$AG_GATE" . >/dev/null 2>&1 ) && AG_RC=0 || AG_RC=1
assert_eq "0" "$AG_RC" "commented-out imports and node: builtins are not violations"

# Ignored globs are skipped — a test importing infra from inside the domain tree is normal.
printf 'import { db } from "../infrastructure/db";\nexport const t = db;\n' > "$AG_S/src/domain/order.test.ts"
( cd "$AG_S" && node "$AG_GATE" . >/dev/null 2>&1 ) && AG_RC=0 || AG_RC=1
assert_eq "0" "$AG_RC" "files matching an ignore glob are not checked"

# ---- wired into the runner through pack.d ----
printf 'import { db } from "../infrastructure/db";\nexport class Bad {}\n' > "$AG_S/src/domain/bad.ts"
AG_OUT="$(cd "$AG_S" && bash .specify/gates/run-gates.sh . 2>&1)"
case "$AG_OUT" in *"pack:dependency-rule"*) pass "run-gates picks the gate up from pack.d" ;; *) fail "run-gates should run the pack gate" ;; esac
case "$AG_OUT" in *"pack:dependency-rule FAILED"*) pass "a pack gate can fail the whole run" ;; *) fail "pack gate failure should fail run-gates" ;; esac
rm -f "$AG_S/src/domain/bad.ts"

# ---- idempotency and the seed-once boundary ----
# The layer map describes THIS project's tree, so --force must not restore the template over a
# project that renamed its layers; the gate itself is pack-owned code and does refresh.
printf '{"root":"lib","layers":{"core":[]}}\n' > "$AG_S/.specify/architecture.json"
bash "$HERE/../packs/architecture-gates/install.sh" --dir "$AG_S" --force >/dev/null 2>&1
assert_contains "$AG_S/.specify/architecture.json" '"root":"lib"' "--force keeps the project's own layer map"
assert_file "$AG_S/.specify/gates/pack.d/dependency-rule.mjs" "--force still refreshes the gate itself"

# A malformed layer map is a real error, not a skip: passing silently would mean the gate
# reports green while checking nothing.
printf 'not json\n' > "$AG_S/.specify/architecture.json"
( cd "$AG_S" && node "$AG_GATE" . >/dev/null 2>&1 ) && AG_RC=0 || AG_RC=1
assert_eq "1" "$AG_RC" "invalid architecture.json fails instead of skipping"

# ---- opt-in boundary ----
AG_S2="$(new_sandbox)"
echo '{}' > "$AG_S2/package.json"; echo '{}' > "$AG_S2/tsconfig.json"
AG_OUT="$(bash "$HERE/../bootstrap.sh" --dir "$AG_S2" 2>&1)"
assert_nofile "$AG_S2/.specify/architecture.json" "a TS signal alone does not install the pack"
echo "$AG_OUT" | grep -F "optional packs not installed:" | grep -qF "architecture-gates" \
  && pass "the pack is discoverable in the not-installed list" || fail "install should name architecture-gates as available"

# Explicit opt-in via --pack works and is recorded in the manifest.
AG_S3="$(new_sandbox)"
bash "$HERE/../bootstrap.sh" --dir "$AG_S3" --pack=architecture-gates >/dev/null 2>&1
assert_file "$AG_S3/.specify/gates/pack.d/dependency-rule.mjs" "--pack=architecture-gates installs the gate"
assert_contains "$AG_S3/.specify/keel.json" '"architecture-gates"' "the manifest records the pack"

rm -rf "$AG_S" "$AG_S2" "$AG_S3"
