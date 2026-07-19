// gridfinity_frame_connectors.scad
//
// A loose bowtie ("butterfly key") connector for joining separately printed
// Gridfinity baseplates along a shared edge. A key-shaped pocket is cut
// straddling the seam in each plate (see gridfinity_baseplate.scad's
// `key_*` parameters), and a separately printed key (gridfinity_key()) is
// dropped in vertically across the seam. Because the key is narrower at its
// waist (centered on the seam) than at either end, it resists the two
// plates being pulled apart sideways once both pockets are filled -- the
// same principle as a woodworking bowtie/butterfly inlay.
//
// Attribution: this bowtie profile is adapted from the ButterFlyConnector()
// module in ostat's gridfinity_extended_openscad project
// (modules/module_gridfinity_frame_connectors.scad),
// https://github.com/ostat/gridfinity_extended_openscad, licensed GPL-3.0.
// It's reimplemented standalone here -- without that project's grid/frame
// coordinate system ($gci, env_pitch(), etc.) -- to match this repo's
// conventions. See README.md for the full attribution notice.
//
// Units are millimeters. The 2D profile is centered on the origin with its
// long axis (lobe to lobe) along X and its waist at x = 0 -- lay the origin
// on the seam between two plates so one lobe embeds in each plate.
//
// Usage:
//   use <gridfinity_frame_connectors.scad>
//   linear_extrude(2) gridfinity_key_2d();         // the loose key, printed separately
//   linear_extrude(2) gridfinity_key_socket_2d();  // pocket to cut into each plate
//
// Open this file directly (or `include <>` it) to render the demo at the
// bottom; `use <>` imports the modules without rendering anything.

// ---------------------------------------------------------------------------
// 2D profile
// ---------------------------------------------------------------------------

// The bowtie/butterfly profile: two rounded wedges tip to tip, wide at each
// end and pinched at the waist (x = 0).
//   size : [length, width] -- overall lobe-to-lobe length (X) and lobe width (Y)
//   r    : corner radius; also sets the minimum waist half-width
module gridfinity_key_2d(size = [6, 4], r = 0.8, fn = 32) {
    a = size.y / 2 - r; // half-height of each lobe's wide edge
    b = size.x / 2 - r; // distance from center to each lobe's wide edge

    module wedge()
        hull() {
            translate([-b, -a]) circle(r = r, $fn = fn);
            translate([-b, a]) circle(r = r, $fn = fn);
            translate([b, 0]) circle(r = r, $fn = fn);
        }

    union() {
        wedge();
        mirror([1, 0, 0]) wedge();
    }
}

// An oversized pocket matching gridfinity_key_2d(), sized with `clearance`
// added all around so the loose key seats with a snug press fit.
module gridfinity_key_socket_2d(size = [6, 4], r = 0.8, clearance = 0.15, fn = 32)
    offset(delta = clearance)
        gridfinity_key_2d(size, r, fn);

// ---------------------------------------------------------------------------
// 3D key
// ---------------------------------------------------------------------------

// The loose butterfly key, extruded to `thickness` -- print this once per
// connector, separately from either baseplate.
module gridfinity_key(size = [6, 4], r = 0.8, thickness = 2, fn = 32)
    linear_extrude(thickness)
        gridfinity_key_2d(size, r, fn);

// ---------------------------------------------------------------------------
// Demo (rendered only when this file is opened / included directly)
// ---------------------------------------------------------------------------

// Two abutting plate stubs, each with a matching pocket straddling the
// seam at x = 0, and the loose key that drops into both -- laid out to one
// side so the fit is visible.
$fn = 32;
difference() {
    union() {
        translate([-15, 0, 0]) cube([15, 15, 2], center = false);
        translate([0, 0, 0]) cube([15, 15, 2], center = false);
    }
    translate([0, 7.5, -0.01])
        linear_extrude(2.02)
            gridfinity_key_socket_2d();
}
translate([0, 25, 0])
    gridfinity_key();
