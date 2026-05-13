---
name: autogrid
description: Use when the user wants to run NUMECA/Cadence AutoGrid5 batch meshing from a CFturbo .geomTurbo file, an output .igg mesh path, and an AutoGrid .trb template or compressor stage count; also use when the user asks to modify known AutoGrid .trb template fields before meshing.
---

# Autogrid

## Purpose

Generate and, when requested, execute the validated PowerShell command that calls the user's reusable AutoGrid5 wrapper:

```powershell
& "C:\Users\HP\.codex\skills\autogrid\run_autogrid_mesh.bat" "<geomTurbo>" "<output.igg>" "<template.trb>"
```

The wrapper is self-contained: it writes the required AutoGrid5 Python macro into a temporary working directory at runtime, so it should not depend on a separate `run_autogrid_project.py` file being present.

The wrapper is expected to produce an editable AutoGrid project package with matching basename:

```text
<case>.trb
<case>.geomTurbo
<case>.igg
<case>.cgns
<case>.bcs
<case>.config
<case>.geom
<case>.info
<case>.qualityReport
<case>.autogrid.log
<case>.xmt_txt
```

## Required Inputs

Always obtain or infer exactly these three paths before running:

1. `geomTurbo`: CFturbo-exported `.geomTurbo` geometry path.
2. `output.igg`: desired output mesh path. Its parent folder is the case output folder, and its basename becomes the basename for all companion files.
3. `template.trb`: AutoGrid `.trb` template path. If the user does not provide a template but gives a compressor stage count, select the matching template from `C:\Users\HP\.codex\skills\autogrid\Trb template`.

## Template Selection

Use this mapping when the user gives a stage count instead of a `.trb` path:

| User stage count | Template path |
| --- | --- |
| `0.5`, `half`, `half stage`, `0.5 stage` | `C:\Users\HP\.codex\skills\autogrid\Trb template\0.5 stage.trb` |
| `1`, `one`, `single`, `1 stage` | `C:\Users\HP\.codex\skills\autogrid\Trb template\1 stage.trb` |
| `4`, `4 stage`, `four stage`, `4-stage contra-rotating` | `C:\Users\HP\.codex\skills\autogrid\Trb template\4 stage contra-rotating.trb` |

If the stage count does not match one of these known templates and no explicit `.trb` is provided, ask for the template path before running. The `0.5`, `1`, and `4` stage contra-rotating templates are reusable/common templates for those cases.

If the user asks only for the command, do not execute it. If the user asks you to run it, run the PowerShell command and then verify output files and quality report.

## Command Pattern

In PowerShell, use `&` because the batch path contains spaces:

```powershell
& "C:\Users\HP\.codex\skills\autogrid\run_autogrid_mesh.bat" "D:\path\case.geomTurbo" "D:\path\output\case.igg" "D:\path\template.trb"
```

Preserve quotes around all three arguments. Prefer `.igg` as the output extension.

## Optional TRB Field Edits

If the user asks to modify template parameters before meshing:

1. Do not edit the original template in place.
2. Copy the template to a clearly named derived `.trb` path in the output folder or a temporary working location.
3. Patch only requested fields, preserving the `NI_BEGIN` / `NI_END` structure.
4. Run the wrapper with the derived `.trb` as the third argument.
5. Report the derived template path and the changed fields.

Common fields are summarized in [trb-fields.md](references/trb-fields.md).

## Verification

After running, check:

- `<case>.trb` exists and is nontrivial in size.
- `<case>.igg` exists.
- `<case>.cgns` exists when expected.
- `<case>.qualityReport` contains `Mesh Validity    : OK` and `No Negative Cell`.
- `<case>.autogrid.log` has no fatal error and shows `Exit IGG Background Session`.

Warnings such as `Spanwise Angular deviation exceeds 40 degrees` should be reported, but they do not automatically mean the batch command failed.
