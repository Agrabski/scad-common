# CLAUDE.md

Guidance for Claude Code when working in this repository.

## What this is

A library of reusable **OpenSCAD** modules for 3D modeling, with a focus on
[Gridfinity](https://gridfinity.xyz/) components. Each `.scad` file is a small,
self-contained, parametric module intended to be pulled into a design with
`use <file.scad>`.

## Conventions

- **Language:** OpenSCAD (targeting the 2021.01 stable release installed here).
- **Units:** millimeters throughout. Gridfinity grid is 42 mm; heights are
  measured in 7 mm "u" units.
- **Naming:** `snake_case` for modules, functions, and files. File name matches
  the primary module it provides.
- **Parametric first:** expose sizes as named parameters with sensible defaults
  rather than hard-coded numbers. Keep required parameters (dimensions) first,
  optional/style parameters after, each with a default.
- **`use`-safe files:** a file must render nothing when imported with
  `use <file.scad>`. Put any demo/example geometry at the very bottom of the
  file — it renders when the file is opened directly or `include <>`-ed, but not
  under `use <>`.
- **2D + 3D split:** where it makes sense, provide a 2D `*_2d` module for the
  cross-section/profile and a thin 3D wrapper that extrudes it. This keeps
  modules composable.
- **Comments:** a header block per file describing purpose, units, orientation,
  and a usage example; a one-line comment above each module documenting its
  parameters.

## Modules

- `skeletonized_wall.scad` — a grid of rectangular cells with diagonal cross
  bracing (an X per cell). Lightens a solid wall while keeping stiffness through
  triangulation. Provides `strut()`, `skeletonized_wall_2d()`, and
  `skeletonized_wall()`.
- `gridfinity_baseplate.scad` — a `cols` × `rows` Gridfinity baseplate: each
  cell gets a raised alignment rim, with optional magnet holes (`magnets =
  true`, sized via the `magnet_dims()` table by name, e.g. `"6x2"`), optional
  padding arms (`pad_left`/`pad_right`/`pad_top`/`pad_bottom`) to fill leftover
  drawer space, and optional `key_*` butterfly-key pockets (see
  `gridfinity_frame_connectors.scad`) to join multiple printed plates.
  Provides `gridfinity_baseplate()`.
- `gridfinity_bin_bottom.scad` — the underside of a Gridfinity bin: a `cols` ×
  `rows` floor with a male stacking foot per cell (mates with a baseplate or
  stacks on another bin), optional magnet holes, and optional skeletonization
  of the floor. Gridfinity spec constants (42 mm pitch, 4.75 mm stacking
  profile, 26 mm magnet pitch) are named at the top of the file. Provides
  `gridfinity_bin_bottom()`.
- `gridfinity_frame_connectors.scad` — a loose bowtie ("butterfly key")
  connector for joining separately printed baseplates: a key-shaped pocket is
  cut into each plate straddling the seam, and a separately printed key drops
  in to lock them together. Provides `gridfinity_key()`, `gridfinity_key_2d()`,
  `gridfinity_key_socket_2d()`. **Attribution:** the bowtie profile is adapted
  from `ButterFlyConnector()` in ostat's `gridfinity_extended_openscad`
  (GPL-3.0, https://github.com/ostat/gridfinity_extended_openscad),
  reimplemented standalone here — see the file header and README.md's
  Attribution section before modifying this file's core geometry.
- `screw_mounts.scad` — negative-geometry cutters for metric fasteners
  (M2–M8), meant to be `difference()`-d out of a part: `insert_hole()`
  (heat-set insert bore), `screw_hole()` (clearance hole with a selectable head
  recess: countersunk/socket/button/none), `clearance_hole()` (plain shank
  bore), and `counterbore_hole()` (cylindrical head recess). Fastener
  dimensions live in the table functions (`screw_body_d()`, `cs_head_d()`,
  `cap_head()`, `button_head()`, `insert_bore()`), which `assert` on an unknown
  size.

## Working with the code

Render a file to STL (also the quickest way to validate that it compiles and is
manifold):

```bash
openscad -o out.stl skeletonized_wall.scad
```

Render a preview image:

```bash
openscad -o out.png --imgsize=600,400 --projection=perspective skeletonized_wall.scad
```

Override parameters from the command line without editing the file:

```bash
openscad -o out.stl -D 'cols=6' -D 'rows=3' skeletonized_wall.scad
```

After changing a module, render it to STL to confirm it still compiles and
produces a valid (manifold, non-empty) object before considering the change
done.
