---
name: ansys-cfx-automation-v3
description: Automate ANSYS CFX .cfx case edits with official CFX command-line tools, audited CCL readback, recoverable CFX-Pre physics-message handling, transient blade-row derived-time synchronization, safe .def generation, and temporary-file cleanup.
---

# ANSYS CFX Automation V3

Use official ANSYS CFX tools as the source of truth. Never edit a `.cfx` binary directly or infer active settings by searching readable strings inside it.

Default CFX bin path on this machine:

```powershell
$CFXBIN = 'D:\Program Files\ANSYS Inc\v241\CFX\bin'
```

## Tool Roles

- `cfx5dfile.exe`: export saved CFX-Pre state from `.cfx` using `-read-pre-state`.
- `cfx5pre.exe`: load `.cfx`, play batch/session files, save edited `.cfx`, and write `.def`.
- `cfx5cmds.exe`: read CCL from `.def` for verification.
- `cfx5solve.exe`: solver execution. Do not call it unless the user explicitly asks to solve or submit a run.

## Core Rule

Every generated `.cfx` must pass an audited readback before exporting `.def`. If CFX-Pre reports or writes physics errors, do not export `.def`; diagnose and repair the `.cfx` first, then rerun readback. Only proceed to `.def` after the requested settings and CFX-Pre messages are acceptable.

## Standard Workflow

1. Identify the source `.cfx` and choose output names before editing. Write a new `.cfx`; do not intentionally overwrite the source unless explicitly requested.
2. Export pre-state CCL:

```powershell
& "$CFXBIN\cfx5dfile.exe" "case.cfx" -read-pre-state -output "case_pre_state.tmp.ccl"
```

3. Modify the exported CCL with tightly scoped replacements. Count expected occurrences before replacing; if a target value appears more or fewer times than expected, inspect the surrounding CCL block.
4. Before building the CFX-Pre batch file, clean known unsafe CCL line breaks:

```powershell
$text = $text -replace "V\\\r?\n\s*elocity", "Velocity"
```

Also avoid splitting any CCL token inside a continued line. If a long list needs line wrapping, wrap at comma boundaries:

```text
...,Time,s,Velocity,m s^-1, \
Acceleration,m s^-2,Angular Velocity,radian s^-1, \
...
```

5. Run a pre-write static audit on the modified CCL:
   - Confirm each requested target block and value is present exactly once.
   - Confirm edited scopes are correct, especially domain, boundary, and analysis names.
   - Confirm no known unsafe broken tokens remain, such as `V\` followed by `elocity`.
   - Confirm all required derived values are consistent with the edited primary values.

6. Create a temporary CFX-Pre batch file containing the cleaned, modified CCL, then append:

```text
> update
> writeCaseFile filename=D:/path/to/edited_case.cfx, operation=save case file
```

Use forward slashes in `filename=` values.

7. Apply the batch and capture stdout/stderr. A zero process exit code is not sufficient by itself.

```powershell
& "$CFXBIN\cfx5pre.exe" -cfx "case.cfx" -batch "apply_edit.tmp.pre"
```

8. Immediately export the edited `.cfx` CCL and audit it:

```powershell
& "$CFXBIN\cfx5dfile.exe" "edited_case.cfx" -read-pre-state -output "edited_case_exported.ccl"
```

9. Audit CFX-Pre output and readback CCL before `.def` generation. Treat these as blockers:
   - `Severity = Error`
   - `Unknown quantity`
   - `not up-to-date`
   - `ERROR in ReadDataBlockHeader`
   - `ERROR in ReadIntDataBlock`
   - `ERROR in ReadToken`
   - missing requested values in the readback CCL
   - inconsistent derived values

Some CFX-Pre low-level messages may appear even with exit code 0 and a readable case. Do not proceed on that basis alone; read back and inspect the saved `.cfx`. If the readback is clean and target values are correct, document the low-level message as non-blocking for that run.

10. If the readback contains a recoverable physics-message inconsistency, generate a second, narrow `.pre` repair file that replaces only the affected CCL block, run `cfx5pre` again, and restart the audit from step 8. If the error is not clearly recoverable, stop and report it instead of exporting `.def`.

11. Before writing `.def`, delete any previous generated output `.def` with the same name. `cfx5pre` can fail or leave a partial output when overwriting a large existing `.def`.

```powershell
if (Test-Path -LiteralPath "edited_case.def") { Remove-Item -LiteralPath "edited_case.def" -Force }
```

12. Generate the `.def` without solving only after the edited `.cfx` audit has passed:

```text
> update
> writeCaseFile filename=D:/path/to/edited_case.def, operation=write def file
```

```powershell
& "$CFXBIN\cfx5pre.exe" -cfx "edited_case.cfx" -batch "write_def.tmp.pre"
```

13. Verify the `.def` through official readback:

```powershell
& "$CFXBIN\cfx5cmds.exe" -read -def "edited_case.def" -text "verify_from_def.tmp.ccl"
```

Check that the edited `.cfx` CCL and `.def` CCL agree on the requested fields. Small formatting and rounding differences from CFX are acceptable only when they preserve the same physical value.

## Error Audit And Repair Policy

Do not blindly auto-fix every CFX-Pre error. Classify messages first:

- Recoverable derived-setting errors: repair the affected block with a narrow `.pre`, rerun CFX-Pre, and read back again.
- Known token-wrap errors such as `Unknown quantity type: V elocity`: fix the import CCL wrapping and rerun from the pre-write audit.
- Physics warnings unrelated to the requested edit, such as transient initial-condition warnings: report them and proceed only if they are warnings, not errors, and the user-requested settings are correct.
- Mesh, material, boundary, topology, or missing-location errors: stop and report. Do not export `.def`.

The `.def` gate is strict: no `.def` export while readback CCL contains `Severity = Error`, target-value mismatch, stale derived settings, or unresolved unknown quantities.

## Transient Blade Row Derived-Time Rules

When editing a rotating domain used by `TRANSIENT BLADE ROW MODELS`, do not rely on a plain CCL `Angular Velocity` replacement to trigger the same recomputation as the GUI panel Apply action. Synchronize the TBR block explicitly.

For `Option = Passing Period` with a single rotating domain:

```text
Passing Period [s] = 60 / (abs(RPM) * Number of Passages in 360)
Timestep [s] = Passing Period / Number of Timesteps per Period
```

Preserve the sign of `Angular Velocity`; use `abs(RPM)` only for the time calculation.

Before writing `.cfx`, update the complete TBR block consistently, for example:

```text
FLOW: Flow Analysis 1
  &replace   TRANSIENT BLADE ROW MODELS:
    Option = None
    TRANSIENT METHOD:
      Option = Time Integration
      TIME DURATION:
        Number of Periods per Run = 300
        Option = Number of Periods per Run
      END # TIME DURATION:
      TIME PERIOD:
        Computed Passing Period = 0.000340908[s]
        Domain = R1
        Option = Passing Period
      END # TIME PERIOD:
      TIME STEPS:
        Computed Timestep = 3.40908e-06[s]
        Number of Timesteps per Period = 100
        Option = Number of Timesteps per Period
      END # TIME STEPS:
    END # TRANSIENT METHOD:
  END # TRANSIENT BLADE ROW MODELS:
END # FLOW:Flow Analysis 1
> update
```

This is the recorded GUI-style Apply pattern: a full `&replace TRANSIENT BLADE ROW MODELS` block followed by `> update`. Use it as the repair pattern when readback reports `Computed Passing Period is not up-to-date`.

### Numeric Precision

Preserve at least the precision already used by the source CCL unless CFX rewrites the value differently during readback.

- Passing period: use at least 7 significant digits, and prefer 9 significant digits when the source uses values like `0.000340908[s]`.
- Timestep: use at least 6 significant digits, and prefer 6 to 9 significant digits in scientific notation for small values like `3.40908e-06[s]`.
- Do not truncate values to a shorter decimal form if it changes the physical value beyond normal CFX readback rounding.
- Accept CFX readback rounding such as `0.0003125[s]` becoming `0.000312499[s]` only after confirming the discrepancy is numeric formatting, not stale settings.

## Cleanup Rules

Keep only user-requested final artifacts by default:

- the new `.cfx`
- the new `.def`, when requested and only after audit passes
- one final CCL exported from the new `.cfx`

Delete temporary files after successful verification:

- `*.tmp.pre`
- source pre-state exports such as `*_pre_state.tmp.ccl`
- modified import CCL files used only to build a batch
- `.def` verification CCL files such as `verify_from_def.tmp.ccl`
- `.cfx` verification CCL files other than the final exported CCL

Do not delete the original `.cfx`, the final exported CCL, source session recordings supplied by the user, or files the user explicitly asked to keep.

If CFX-Pre touches the source `.cfx` timestamp or size while loading it, read back the source and confirm its physics settings still match the original expected values. Report the touch in the final answer.

## Common Target Edits

For inlet total pressure, scope the edit inside:

```text
FLOW: Flow Analysis 1
  DOMAIN: <domain>
    BOUNDARY: <inlet>
      BOUNDARY CONDITIONS:
        MASS AND MOMENTUM:
          Option = Stationary Frame Total Pressure
          Relative Pressure = ...
```

For rotating speed, scope the edit inside:

```text
FLOW: Flow Analysis 1
  DOMAIN: <rotating domain>
    DOMAIN MODELS:
      DOMAIN MOTION:
        Angular Velocity = ...
```

Preserve the original sign of angular velocity unless the user explicitly asks to reverse rotation direction. If the rotating domain participates in TBR timing, also update and audit the TBR derived-time fields.

For transient blade row time steps, scope the edit inside:

```text
FLOW: Flow Analysis 1
  TRANSIENT BLADE ROW MODELS:
    TRANSIENT METHOD:
      TIME STEPS:
        Number of Timesteps per Period = ...
```

Then update `Computed Passing Period` and `Computed Timestep` if the period-defining domain speed changed, or update `Computed Timestep` if only `Number of Timesteps per Period` changed.
