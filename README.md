The copyright is belong to @mushijieyy

# Codex-Skills

This repository stores two Codex skills created for Windows-based turbomachinery automation workflows.

## Included Skills

### `autogrid`

Automates NUMECA/Cadence AutoGrid5 batch mesh generation from CFturbo `.geomTurbo` geometry files.

**Inputs**

- `geomTurbo`: CFturbo-exported geometry file.
- `output.igg`: desired mesh output path. The basename is reused for companion files.
- `template.trb`: AutoGrid template path. If no template is supplied, the skill can select a bundled template from a compressor stage count.

**Outputs**

- `<case>.igg`
- `<case>.trb`
- `<case>.geomTurbo`
- `<case>.cgns`
- `<case>.bcs`
- `<case>.config`
- `<case>.geom`
- `<case>.info`
- `<case>.qualityReport`
- `<case>.autogrid.log`
- `<case>.xmt_txt`

**Usage**

Ask Codex to use the `autogrid` skill with a `.geomTurbo` file, an output folder or `.igg` path, and either a `.trb` template or a known compressor stage count.

Example:

```text
Use the autogrid skill to mesh this 4-stage compressor. geomTurbo: D:\case\machine.geomTurbo. Output folder: D:\case\mesh.
```

**Implementation Logic**

The skill calls `run_autogrid_mesh.bat`, which runs AutoGrid5 in batch mode, writes the required AutoGrid macro at runtime, imports the geometry, applies the selected `.trb` template, exports the editable mesh project package, and verifies the generated quality report and AutoGrid log.

Bundled template selection:

- `0.5 stage` -> `Trb template/0.5 stage.trb`
- `1 stage` -> `Trb template/1 stage.trb`
- `4 stage contra-rotating` -> `Trb template/4 stage contra-rotating.trb`

### `ansys-cfx-automation-v3`

Automates ANSYS CFX `.cfx` case editing and export using official CFX command-line tools.

**Inputs**

- Source `.cfx` case file.
- Requested CCL/physics changes.
- Output directory and desired output names.
- Optional `.def` export requirement.

**Outputs**

- Modified `.cfx` case file.
- Exported CCL for audit/readback.
- Exported `.def` file when requested.
- Verification notes from official CFX readback tools.

**Usage**

Ask Codex to use the `ansys-cfx-automation-v3` skill with a source `.cfx` file, the target parameter changes, and an output location.

Example:

```text
Use ansys-cfx-automation-v3 to modify this CFX case, export the final .cfx, CCL, and .def into D:\CFX test.
```

**Implementation Logic**

The skill uses official ANSYS CFX tools instead of raw text extraction. Its workflow exports or reads the case state through CFX utilities, patches the CCL, regenerates the `.cfx` and `.def`, then verifies both the `.cfx` and `.def` through validated readback commands. It also documents known recovery handling for CFX-Pre import issues, derived transient blade-row time synchronization, `.def` regeneration failures, and temporary-file cleanup.

## Repository Layout

```text
skills/
  autogrid/
    SKILL.md
    run_autogrid_mesh.bat
    Trb template/
    references/
    agents/
  ansys-cfx-automation-v3/
    SKILL.md
    agents/
```
