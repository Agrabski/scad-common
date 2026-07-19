// gridfinity_baseplate.scad
//
// Parametric Gridfinity baseplate: the countertop tile that Gridfinity bins
// sit on and align to. Each cell gets a raised alignment rim that the bin's
// stacking feet drop into; magnet holes (optional, parametrized by size) let
// bins anchor magnetically. Optional padding arms fill leftover space beside
// the grid so the plate can fit a drawer whose interior isn't an exact
// multiple of 42 mm. Optional butterfly-key pockets on each edge let several
// printed plates be joined into one large surface (see
// gridfinity_frame_connectors.scad).
//
// Units are millimeters. The plate sits with its underside at z = 0 and the
// top of the alignment rims at z = base_h + rim_h. The grid footprint runs
// from the origin to [cols*42, rows*42]; padding, if any, extends outward
// from that footprint on the requested side(s).
//
// Usage:
//   use <gridfinity_baseplate.scad>
//   gridfinity_baseplate(cols = 3, rows = 2);                     // plain
//   gridfinity_baseplate(cols = 3, rows = 2, magnets = true);     // magnets
//   gridfinity_baseplate(cols = 3, rows = 2, pad_right = 8.5);    // fill a gap
//   // Two plates joined edge to edge with a loose butterfly key:
//   gridfinity_baseplate(cols = 2, rows = 2, key_right = true);
//   translate([2 * 42, 0, 0])
//     gridfinity_baseplate(cols = 2, rows = 2, key_left = true);
//
// Open this file directly (or `include <>` it) to render the demo at the
// bottom; `use <>` imports the modules/functions without rendering anything.

use <gridfinity_frame_connectors.scad>

// ---------------------------------------------------------------------------
// Gridfinity constants (from the Gridfinity spec)
// ---------------------------------------------------------------------------
GRID = 42; // grid pitch: one gridfinity unit
BASE_CLEAR = 0.5; // cell rim outline = GRID - clearance (0.25 mm per side)
CORNER_R = 4; // outer corner radius of the cell / plate profile
MAGNET_PITCH = 26; // center-to-center spacing of the 4 magnet holes / cell

// ---------------------------------------------------------------------------
// Magnet size table
//
// Named as "DxH" (diameter x height, mm), the common disc magnet sizes used
// in Gridfinity baseplates. Pass a name via `magnet_size`, or override the
// diameter/depth directly with `magnet_d` / `magnet_depth`.
// ---------------------------------------------------------------------------
function magnet_dims(size) =
    size == "4x2"  ? [4.0,  2.0] :
    size == "6x2"  ? [6.0,  2.0] :
    size == "6x3"  ? [6.0,  3.0] :
    size == "8x2"  ? [8.0,  2.0] :
    size == "8x3"  ? [8.0,  3.0] :
    size == "10x2" ? [10.0, 2.0] :
    size == "10x3" ? [10.0, 3.0] :
    assert(false, str("magnet_dims: unknown size '", size, "'"));

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// A rounded rectangle centered on the origin: `w` x `h` outer, `r` corner radius.
module rounded_rect_2d(w, h, r)
    offset(r = r) offset(delta = -r) square([w, h], center = true);

// ---------------------------------------------------------------------------
// Baseplate
// ---------------------------------------------------------------------------

// A cols x rows Gridfinity baseplate.
//
//   cols, rows     : number of grid cells in X and Y
//   magnets        : if true, drill 4 magnet holes per cell (shared pattern
//                    at each cell corner, spaced MAGNET_PITCH apart)
//   magnet_size    : named size looked up in magnet_dims(), e.g. "6x2"
//   magnet_d       : override magnet hole diameter (mm); default from magnet_size
//   magnet_depth   : override magnet hole depth (mm); default from magnet_size
//   magnet_fit     : added to magnet_d for a press fit (mm)
//   base_h         : thickness of the solid base slab (mm)
//   rim_h          : height of the raised alignment rim around each cell (mm)
//   rim_t          : wall thickness of the alignment rim (mm)
//   pad_left, pad_right, pad_top, pad_bottom :
//                    extra solid material (mm) extending the plate footprint
//                    past the grid on that side, to fill leftover drawer
//                    space. Flush with the base slab; no cell rim over it.
//   key_left, key_right, key_top, key_bottom :
//                    if true, cut a butterfly-key pocket (see
//                    gridfinity_frame_connectors.scad) per row/column
//                    straddling that edge. A separately printed
//                    gridfinity_key() drops into the matching pockets on two
//                    abutting plates to lock them together.
//   key_size, key_r, key_clearance :
//                    edge key geometry; see gridfinity_key_2d() /
//                    gridfinity_key_socket_2d()
//   fn             : arc resolution for rounded corners / holes
module gridfinity_baseplate(
    cols = 1,
    rows = 1,
    magnets = false,
    magnet_size = "6x2",
    magnet_d = undef,
    magnet_depth = undef,
    magnet_fit = 0.2,
    base_h = 2.2,
    rim_h = 2.15,
    rim_t = 1.7,
    pad_left = 0,
    pad_right = 0,
    pad_top = 0,
    pad_bottom = 0,
    key_left = false,
    key_right = false,
    key_top = false,
    key_bottom = false,
    key_size = [6, 4],
    key_r = 0.8,
    key_clearance = 0.15,
    fn = 48
) {
    $fn = fn;

    md = magnet_d == undef ? magnet_dims(magnet_size)[0] : magnet_d;
    mh = magnet_depth == undef ? magnet_dims(magnet_size)[1] : magnet_depth;

    W = cols * GRID;
    D = rows * GRID;

    // Overall plate footprint, including padding, centered for rounding then
    // shifted so the grid still runs from the origin to [W, D].
    plate_w = W + pad_left + pad_right;
    plate_d = D + pad_top + pad_bottom;
    plate_cx = -pad_left + plate_w / 2;
    plate_cy = -pad_bottom + plate_d / 2;

    // Center of grid cell (i, j).
    function cell(i, j) = [(i + 0.5) * GRID, (j + 0.5) * GRID];

    module plate_outline()
        translate([plate_cx, plate_cy])
            rounded_rect_2d(plate_w, plate_d, CORNER_R);

    // One butterfly-key pocket straddling the plate edge at (x, y), rotated
    // so the key's long axis crosses the seam: 0 for left/right edges
    // (already crossing a vertical seam), 90 for top/bottom (a horizontal one).
    module edge_key(x, y, angle)
        translate([x, y])
            rotate([0, 0, angle])
                translate([0, 0, -0.01])
                    linear_extrude(base_h + 0.02)
                        gridfinity_key_socket_2d(key_size, key_r, key_clearance, fn);

    module keys() {
        if (key_left)
            for (j = [0 : rows - 1])
                edge_key(-pad_left, cell(0, j).y, 0);
        if (key_right)
            for (j = [0 : rows - 1])
                edge_key(W + pad_right, cell(0, j).y, 0);
        if (key_bottom)
            for (i = [0 : cols - 1])
                edge_key(cell(i, 0).x, -pad_bottom, 90);
        if (key_top)
            for (i = [0 : cols - 1])
                edge_key(cell(i, 0).x, D + pad_top, 90);
    }

    module magnet_holes(i, j) {
        for (dx = [-1, 1], dy = [-1, 1])
            translate([cell(i, j).x + dx * MAGNET_PITCH / 2, cell(i, j).y + dy * MAGNET_PITCH / 2, -0.01])
                cylinder(h = mh + 0.01, d = md + magnet_fit);
    }

    difference() {
        union() {
            // Base slab, spanning the grid plus any padding.
            linear_extrude(base_h) plate_outline();

            // Alignment rim per cell: a picture-frame wall the bin's
            // stacking feet drop into.
            for (i = [0 : cols - 1], j = [0 : rows - 1])
                translate([cell(i, j).x, cell(i, j).y, base_h])
                    linear_extrude(rim_h)
                        difference() {
                            rounded_rect_2d(GRID - BASE_CLEAR, GRID - BASE_CLEAR, CORNER_R);
                            rounded_rect_2d(
                                GRID - BASE_CLEAR - 2 * rim_t,
                                GRID - BASE_CLEAR - 2 * rim_t,
                                max(CORNER_R - rim_t, 0.1)
                            );
                        }
        }

        if (magnets)
            for (i = [0 : cols - 1], j = [0 : rows - 1])
                magnet_holes(i, j);

        keys();
    }
}

// ---------------------------------------------------------------------------
// Demo (rendered only when this file is opened / included directly)
// ---------------------------------------------------------------------------

// Two 2x1 plates joined edge to edge with a butterfly-key connector, the
// left one padded on its outer edge to show filling leftover drawer space,
// both with magnet holes -- plus the loose key that drops into the seam
// between them.
gridfinity_baseplate(cols = 2, rows = 1, magnets = true, pad_left = 8, key_right = true);
translate([2 * GRID, 0, 0])
    gridfinity_baseplate(cols = 2, rows = 1, magnets = true, pad_right = 8, key_left = true);
translate([2 * GRID, GRID / 2, 6]) gridfinity_key();

