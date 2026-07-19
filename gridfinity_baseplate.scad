// gridfinity_baseplate.scad
//
// Parametric Gridfinity bin bottom: the underside of a storage container,
// molded with the male stacking feet that mate with a Gridfinity baseplate
// (or stack onto another bin). Optional magnet holes let the feet be
// magnetically anchored.
//
// Units are millimeters. The part sits with the top of its floor slab at
// z = floor, the floor's underside at z = 0, and the feet tapering downward
// to z = -PROFILE_H (their flat contact tips). The footprint runs from the
// origin to [cols*42, rows*42].
//
// Usage:
//   use <gridfinity_baseplate.scad>
//   gridfinity_baseplate(cols = 2, rows = 3);              // plain
//   gridfinity_baseplate(cols = 2, rows = 3, magnets = true); // with magnets
//
// Open this file directly (or `include <>` it) to render the demo at the
// bottom; `use <>` imports the modules without rendering anything.

use <skeletonized_wall.scad>

// ---------------------------------------------------------------------------
// Gridfinity constants (from the Gridfinity spec)
// ---------------------------------------------------------------------------
GRID = 42; // grid pitch: one gridfinity unit
BASE_CLEAR = 0.5; // foot outline = GRID - clearance (0.25 mm per side)
CORNER_R = 4; // outer corner radius of the foot / floor profile
MAGNET_PITCH = 26; // center-to-center spacing of the 4 magnet holes / cell

// Stacking profile, measured from the top (attached to the floor) downward
// to the flat contact tip (heights sum to the total profile height; each
// chamfer is at 45 deg so its inset == its height).
CHAMFER_TOP = 2.15; // upper chamfer height (and inset)
STRAIGHT = 1.8; // vertical section height
CHAMFER_BOTTOM = 0.8; // lower chamfer height (and inset)
PROFILE_H = CHAMFER_TOP + STRAIGHT + CHAMFER_BOTTOM; // 4.75
MAGNETS = true;
ROWS = 2;
COLUMNS = 2;
SKELETONIZE = false;
// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// A rounded square centered on the origin: `size` outer, `r` corner radius.
module rounded_square(size, r, skeletonize = false) {
  offset(r=r) {
    offset(delta=-r) {
      square([size, size], center=true);
    }
  }
}
module slab(z, inset, eps, skeletonize = false)
  translate([0, 0, z])
    linear_extrude(eps)
      offset(delta=-inset)
        rounded_square(GRID - BASE_CLEAR, CORNER_R, skeletonize);

// A single stacking foot: full-size at z = 0 (where it joins the bin floor),
// tapering down to its flat contact tip at z = -PROFILE_H.
module bin_foot(eps = 0.02, skeletonize = false) {
  // A thin slab of the base profile inset by `inset`, placed at height z.
  difference() {
    z1 = -CHAMFER_TOP; // bottom of top chamfer
    z2 = z1 - STRAIGHT; // bottom of straight section
    z3 = z2 - CHAMFER_BOTTOM; // bottom of the foot (contact tip)

    union() {
      hull() { slab(0, 0, eps, skeletonize); slab(z1, CHAMFER_TOP, eps, skeletonize); } // top chamfer
      hull() { slab(z1, CHAMFER_TOP, eps, skeletonize); slab(z2, CHAMFER_TOP, eps, skeletonize); } // straight
      hull() { slab(z2, CHAMFER_TOP, eps, skeletonize); slab(z3, CHAMFER_TOP + CHAMFER_BOTTOM, eps, skeletonize); } // bottom chamfer
    }
    if (skeletonize) {
      translate([0, 0, z3 - 0.01])
        linear_extrude(30)
          square(GRID - BASE_CLEAR - 10, center=true);
    }
  }
}

// ---------------------------------------------------------------------------
// Bin bottom
// ---------------------------------------------------------------------------

// A cols x rows Gridfinity bin bottom, with a stacking foot per cell.
//
//   cols, rows    : number of grid cells in X and Y
//   magnets       : if true, drill 4 magnet holes per cell up into the feet
//   magnet_d      : magnet hole diameter (mm); default fits 6 mm magnets + clearance
//   magnet_depth  : magnet hole depth (mm); default fits 2 mm magnets
//   floor         : bin floor thickness above the feet (mm). Automatically
//                   raised when magnets are enabled so the holes never break
//                   through into the space above the floor.
//   skeletonize   : if true, replace the solid floor slab with the
//                   skeletonized_wall_2d() lattice pattern, saving weight
//                   and material
//   skel_strut    : strut thickness for the skeletonized floor (mm)
//   skel_frame_strut : outer border thickness for the skeletonized floor
//                   (mm); defaults to skel_strut
//   skel_braces   : diagonal brace style for the skeletonized floor -
//                   "x", "/", "\" or "none"
//   fn            : arc resolution for rounded corners / holes
module gridfinity_baseplate(
  cols = 1,
  rows = 1,
  magnets = false,
  magnet_d = 6.2,
  magnet_depth = 2.0,
  floor = 1.2,
  skeletonize = false,
  skel_strut = 1.6,
  skel_frame_strut = undef,
  skel_braces = "x",
  fn = 48
) {
  $fn = fn;

  // Keep at least a small wall between a magnet hole and the space above the floor.
  min_floor = magnets ? magnet_depth + 0.6 : 0;
  floor_h = max(floor, min_floor);

  W = cols * GRID;
  D = rows * GRID;

  // Center of grid cell (i, j).
  function cell(i, j) = [(i + 0.5) * GRID, (j + 0.5) * GRID];

  // The floor footprint outline (rounded outer corners).
  module floor_outline()
    offset(r=CORNER_R) offset(delta=-CORNER_R)
        square([W, D]);

  difference() {
    union() {
      // Floor slab, sitting above the feet: solid, or a skeletonized
      // lattice clipped to the plate footprint.

      // Stacking feet, hanging below the floor.
      for (i = [0:cols - 1], j = [0:rows - 1])
        translate([cell(i, j).x, cell(i, j).y, 0]) {
          difference() {
            union() {
              bin_foot(skeletonize=skeletonize);
              if (magnets) {
                for (dx = [-1, 1], dy = [-1, 1]) {
                  translate(
                    [
                      dx * MAGNET_PITCH / 2,
                      dy * MAGNET_PITCH / 2,
                      -PROFILE_H,
                    ]
                  ) {
                    linear_extrude(magnet_depth + 0.01)
                      square(magnet_d + 0.5, center=true);
                  }
                }
              }
              if (skeletonize) {
                width = GRID - BASE_CLEAR - 10;
                translate([-width / 2, -width / 2, -PROFILE_H + 0.5])
                  linear_extrude(height=PROFILE_H - 0.5, convexity=10)
                    skeletonized_wall_2d(
                      width=width,
                      height=width,
                      cols=2,
                      rows=2,
                      braces="x"
                    );
              }
            }
            if (magnets) {
              for (dx = [-1, 1], dy = [-1, 1]) {
                translate(
                  [
                    dx * MAGNET_PITCH / 2,
                    dy * MAGNET_PITCH / 2,
                    -PROFILE_H - 0.01,
                  ]
                ) {
                  cylinder(h=magnet_depth + 0.01, d=magnet_d);
                }
              }
            }
          }
        }
    }
  }
}

// ---------------------------------------------------------------------------
// Demo (rendered only when this file is opened / included directly)
// ---------------------------------------------------------------------------

gridfinity_baseplate(cols=COLUMNS, rows=ROWS, magnets=MAGNETS, skeletonize=SKELETONIZE);
