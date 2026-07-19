// gridfinity_baseplate.scad
//
// Parametric Gridfinity baseplate: a grid of sockets that receive the feet of
// Gridfinity bins, with optional magnet holes drilled into the underside.
//
// Units are millimeters. The plate sits with its bottom face on the XY plane
// (z = 0) and grows upward; sockets open at the top face. The footprint runs
// from the origin to [cols*42, rows*42].
//
// Usage:
//   use <gridfinity_baseplate.scad>
//   gridfinity_baseplate(cols = 2, rows = 3);              // plain
//   gridfinity_baseplate(cols = 2, rows = 3, magnets = true); // with magnets
//
// Open this file directly (or `include <>` it) to render the demo at the
// bottom; `use <>` imports the modules without rendering anything.

// ---------------------------------------------------------------------------
// Gridfinity constants (from the Gridfinity spec)
// ---------------------------------------------------------------------------
GRID          = 42;    // grid pitch: one gridfinity unit
BASE_CLEAR    = 0.5;   // socket opening = GRID - clearance (0.25 mm per side)
CORNER_R      = 4;     // outer corner radius of the base profile
MAGNET_PITCH  = 26;    // center-to-center spacing of the 4 magnet holes / cell

// Stacking profile, measured from the top opening downward (heights sum to the
// total profile height; each chamfer is at 45 deg so its inset == its height).
CHAMFER_TOP    = 2.15; // upper chamfer height (and inset)
STRAIGHT       = 1.8;  // vertical section height
CHAMFER_BOTTOM = 0.8;  // lower chamfer height (and inset)
PROFILE_H      = CHAMFER_TOP + STRAIGHT + CHAMFER_BOTTOM; // 4.75

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// A rounded square centered on the origin: `size` outer, `r` corner radius.
module rounded_square(size, r) {
    offset(r = r) offset(delta = -r) square([size, size], center = true);
}

// The socket cutter for a single cell. Its opening lies at z = 0 and it tapers
// downward to -PROFILE_H, matching the negative of a bin foot.
module socket_cutter(eps = 0.02) {
    // A thin slab of the base profile inset by `inset`, placed at height z.
    module slab(z, inset)
        translate([0, 0, z])
            linear_extrude(eps)
                offset(delta = -inset)
                    rounded_square(GRID - BASE_CLEAR, CORNER_R);

    z1 = -CHAMFER_TOP;                 // bottom of top chamfer
    z2 = z1 - STRAIGHT;                // bottom of straight section
    z3 = z2 - CHAMFER_BOTTOM;          // bottom of the socket

    hull() { slab(0,  0);            slab(z1, CHAMFER_TOP); }               // top chamfer
    hull() { slab(z1, CHAMFER_TOP); slab(z2, CHAMFER_TOP); }               // straight
    hull() { slab(z2, CHAMFER_TOP); slab(z3, CHAMFER_TOP + CHAMFER_BOTTOM); } // bottom chamfer
}

// ---------------------------------------------------------------------------
// Baseplate
// ---------------------------------------------------------------------------

// A cols x rows Gridfinity baseplate.
//
//   cols, rows    : number of grid cells in X and Y
//   magnets       : if true, drill 4 magnet holes per cell into the underside
//   magnet_d      : magnet hole diameter (mm); default fits 6 mm magnets + clearance
//   magnet_depth  : magnet hole depth (mm); default fits 2 mm magnets
//   floor         : material thickness below the sockets (mm). Automatically
//                   raised when magnets are enabled so the holes never break
//                   through into a socket.
//   fn            : arc resolution for rounded corners / holes
module gridfinity_baseplate(cols = 1, rows = 1, magnets = false,
                            magnet_d = 6.2, magnet_depth = 2.0,
                            floor = 1.2, fn = 48) {
    $fn = fn;

    // Keep at least a small wall between a magnet hole and the socket above it.
    min_floor = magnets ? magnet_depth + 0.6 : 0;
    floor_h   = max(floor, min_floor);
    total_h   = PROFILE_H + floor_h;

    W = cols * GRID;
    D = rows * GRID;

    // Center of grid cell (i, j).
    function cell(i, j) = [(i + 0.5) * GRID, (j + 0.5) * GRID];

    difference() {
        // Solid plate with rounded outer corners.
        linear_extrude(total_h)
            offset(r = CORNER_R) offset(delta = -CORNER_R)
                square([W, D]);

        // Sockets, opening at the top face.
        for (i = [0 : cols - 1], j = [0 : rows - 1])
            translate([cell(i, j).x, cell(i, j).y, total_h])
                socket_cutter();

        // Magnet holes, drilled up from the bottom face.
        if (magnets)
            for (i = [0 : cols - 1], j = [0 : rows - 1])
                for (dx = [-1, 1], dy = [-1, 1])
                    translate([cell(i, j).x + dx * MAGNET_PITCH / 2,
                               cell(i, j).y + dy * MAGNET_PITCH / 2,
                               -0.01])
                        cylinder(h = magnet_depth + 0.01, d = magnet_d);
    }
}

// ---------------------------------------------------------------------------
// Demo (rendered only when this file is opened / included directly)
// ---------------------------------------------------------------------------

gridfinity_baseplate(cols = 2, rows = 2, magnets = true);
