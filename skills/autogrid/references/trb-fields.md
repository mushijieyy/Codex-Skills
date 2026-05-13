# AutoGrid TRB Field Notes

Use this reference only when the user asks to modify `.trb` template fields before running AutoGrid.

## Row Geometry / Passage Fields

Typical block:

```text
NI_BEGIN nirow
  NAME                         row 1
  TYPE                         normal
  PERIODICITY                  16
  GEOMETRY_PERIODICITY_NUMBER  1
  ROTATION_SPEED               -11000
  LOW_MEMORY_USE               0
  GENERATE_FULL_MESH           13
NI_END   nirow
```

Meanings:

- `PERIODICITY`: blade count / periodicity for the row.
- `ROTATION_SPEED`: row rotation speed. Preserve sign when the user says to keep rotation direction.
- `GENERATE_FULL_MESH`: number of passages generated for full mesh / passage replication behavior.

## Row Wizard Fields

Typical block:

```text
NI_BEGIN nirowwizard
  ROWTYPE                    6
  NAME                       row wizard
  ROTOR                      1
  GRID_LEVEL                 0
  FLOW_PATH_NUMBER           73
  HUB_GAP                    0
  TIP_GAP                    1
  HUB_FILLET                 0
  TIP_FILLET                 0
  TIP_CONTROL_WIDTH_LE       1
  TIP_CONTROL_WIDTH_TE       1
  HUB_CONTROL_WIDTH_LE       1
  HUB_CONTROL_WIDTH_TE       1
  FULL_MATCHING              1
  ROW_CLUSTERING             0.005
NI_END   nirowwizard
```

Meanings from the user's validated notes:

- `ROWTYPE`: row type; `6` was used for axial compressor.
- `GRID_LEVEL`: global/coarse grid level control.
- `FLOW_PATH_NUMBER`: radial / flow-path layer count.
- `HUB_GAP`: `0` means no hub gap, `1` means hub gap exists.
- `TIP_GAP`: `0` means no tip gap, `1` means tip gap exists.
- `TIP_CONTROL_WIDTH_LE`: leading-edge tip-gap control width in mm.
- `TIP_CONTROL_WIDTH_TE`: trailing-edge tip-gap control width in mm.
- `HUB_CONTROL_WIDTH_LE`: leading-edge hub-gap control width in mm.
- `HUB_CONTROL_WIDTH_TE`: trailing-edge hub-gap control width in mm.
- `ROW_CLUSTERING`: first layer mesh height in mm in the user's template notes.

## Editing Rules

- Patch by block context, not global string replacement, when row-specific changes are requested.
- If changing speed for multiple rows while preserving direction, replace absolute values and keep each sign.
- Physical geometry changes such as actual blade tip clearance should normally come from CFturbo and a fresh `.geomTurbo`; TRB gap fields mainly control AutoGrid's row/gap setup and mesh controls.
- Keep numeric formatting simple and ASCII-only.
