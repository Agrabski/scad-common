# scad-common

A small library of reusable, parametric [OpenSCAD](https://openscad.org/)
modules for 3D modeling — with a focus on
[Gridfinity](https://gridfinity.xyz/) components and 3D-printable hardware.

Every file is self-contained: pull the modules you want into your design with
`use <file.scad>` and call them. Opening a file directly (or `include <>`-ing
it) renders a small demo so you can preview what it does.

## Modules

| File | Provides | What it does |
|------|----------|--------------|
| [`skeletonized_wall.scad`](skeletonized_wall.scad) | `skeletonized_wall()`, `skeletonized_wall_2d()`, `strut()` | A grid of rectangular cells with diagonal cross bracing — lightens a solid wall while keeping stiffness through triangulation. |
| [`gridfinity_baseplate.scad`](gridfinity_baseplate.scad) | `gridfinity_baseplate()` | A Gridfinity baseplate of any `cols` × `rows` size, with optional magnet holes (`magnets = true`). |
| [`screw_mounts.scad`](screw_mounts.scad) | `insert_hole()`, `screw_hole()`, `clearance_hole()`, `counterbore_hole()` | Negative-geometry cutters for metric fasteners (M2–M8): heat-set insert bores plus screw holes with a selectable head recess (countersunk, socket cap, button, or none). `difference()` them out of a part. |

## Usage

```openscad
use <gridfinity_baseplate.scad>
use <skeletonized_wall.scad>
use <screw_mounts.scad>

// A 3x2 baseplate with magnet holes.
gridfinity_baseplate(cols = 3, rows = 2, magnets = true);

// A cross-braced wall panel.
translate([0, 130, 0])
    skeletonized_wall(width = 120, height = 60, thickness = 3, cols = 6, rows = 3);

// A block with an M3 heat-set insert bore in its top face.
translate([0, -30, 0])
    difference() {
        cube([12, 12, 8]);
        translate([6, 6, 8]) insert_hole("M3");
    }
```

## Rendering

Render a module to STL (also the quickest way to check it compiles and is
manifold):

```bash
openscad -o out.stl gridfinity_baseplate.scad
```

Override any parameter from the command line without editing the file:

```bash
openscad -o out.stl -D 'cols=4' -D 'rows=2' -D 'magnets=true' gridfinity_baseplate.scad
```

Render a preview image:

```bash
openscad -o out.png --imgsize=600,450 --projection=perspective gridfinity_baseplate.scad
```

All dimensions are in millimeters.

## License

[GPL-3.0](LICENSE) © contributors.
