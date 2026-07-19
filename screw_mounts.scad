// screw_mounts.scad
//
// Reusable negative-geometry cutters for metric fasteners and heat-set
// inserts. Every module is meant to be subtracted (difference()) from a part.
//
// Sizes: M2, M2.5, M3, M4, M5, M6, M8.
// Head types (for screw_hole): "countersunk" / "flat", "socket" / "cap",
//                              "button", and "pan" / "none" (no recess).
//
// Units are millimeters. Orientation convention (all modules):
//   The mouth of the hole sits at the LOCAL ORIGIN on the Z=0 plane and the
//   hole bores DOWNWARD into -Z, i.e. the fastener enters from +Z. Each cutter
//   pokes ~0.1 mm past the surfaces it breaks so the Boolean is clean.
//   translate()/rotate() the call to place it on the real face.
//
// For screw_hole()/clearance_hole()/counterbore_hole(), `length` is the FULL
// thickness of material the shank crosses; any head recess is carved into the
// top (Z=0) face within that thickness.
//
// Usage:
//   use <screw_mounts.scad>
//   difference() { part(); translate(p) insert_hole("M3"); }
//   difference() { lid();  translate(p) screw_hole("M3", 4, head = "socket"); }
//
// Open this file directly (or `include <>` it) to render the demo at the
// bottom; `use <>` imports the modules/functions without rendering anything.

// ===========================================================================
// Fastener tables
//
// Values are standard DIN/ISO nominal dimensions. Heat-set insert bores are
// manufacturer-dependent (the values below suit common brass inserts, e.g.
// CNC Kitchen / generic) — override per module if your inserts differ.
// Every table asserts on an unknown size so mistakes fail loudly.
// ===========================================================================

// Thread nominal / body outer diameter.
function screw_body_d(size) =
    size == "M2"   ? 2.0 :
    size == "M2.5" ? 2.5 :
    size == "M3"   ? 3.0 :
    size == "M4"   ? 4.0 :
    size == "M5"   ? 5.0 :
    size == "M6"   ? 6.0 :
    size == "M8"   ? 8.0 :
    assert(false, str("screw_body_d: unknown size '", size, "'"));

// Countersunk flat head diameter (ISO 7046 / DIN 965, 90 deg included angle).
function cs_head_d(size) =
    size == "M2"   ? 3.8  :
    size == "M2.5" ? 4.7  :
    size == "M3"   ? 5.6  :
    size == "M4"   ? 7.5  :
    size == "M5"   ? 9.2  :
    size == "M6"   ? 11.0 :
    size == "M8"   ? 14.5 :
    assert(false, str("cs_head_d: unknown size '", size, "'"));

// Socket (cap) head — DIN 912 — as [diameter, height].
function cap_head(size) =
    size == "M2"   ? [3.8,  2.0] :
    size == "M2.5" ? [4.5,  2.5] :
    size == "M3"   ? [5.5,  3.0] :
    size == "M4"   ? [7.0,  4.0] :
    size == "M5"   ? [8.5,  5.0] :
    size == "M6"   ? [10.0, 6.0] :
    size == "M8"   ? [13.0, 8.0] :
    assert(false, str("cap_head: unknown size '", size, "'"));

// Button head — ISO 7380 — as [diameter, height].
function button_head(size) =
    size == "M2"   ? [3.5,  1.1]  :
    size == "M2.5" ? [4.7,  1.4]  :
    size == "M3"   ? [5.7,  1.65] :
    size == "M4"   ? [7.6,  2.2]  :
    size == "M5"   ? [9.5,  2.75] :
    size == "M6"   ? [10.5, 3.3]  :
    size == "M8"   ? [14.0, 4.4]  :
    assert(false, str("button_head: unknown size '", size, "'"));

// Brass heat-set insert bore — as [outer diameter, depth].
function insert_bore(size) =
    size == "M2"   ? [3.2, 4.0]  :
    size == "M2.5" ? [3.5, 5.7]  :
    size == "M3"   ? [4.0, 5.0]  :
    size == "M4"   ? [5.6, 6.7]  :
    size == "M5"   ? [6.4, 8.1]  :
    size == "M6"   ? [8.1, 12.7] :
    size == "M8"   ? [10.0, 12.7] :
    assert(false, str("insert_bore: unknown size '", size, "'"));

// ===========================================================================
// Cutters
// ===========================================================================

// Pocket for a heat-set insert, pressed in from +Z. Bores `depth` into -Z
// (default = the size's standard insert length) and pokes 0.1 mm past the Z=0
// face so the cut breaks the surface cleanly.
//   depth : override the bore depth (mm); leave default for the standard length
module insert_hole(size, depth = undef) {
    d = insert_bore(size)[0];
    h = depth == undef ? insert_bore(size)[1] : depth;
    translate([0, 0, -h])
        cylinder(d = d, h = h + 0.1);
}

// Plain shank clearance bore through `length` of material (no head recess).
//   length : material thickness the shank crosses
//   fit    : added to the body diameter (mm); 0 = exact body dia, ~0.4 = free fit
module clearance_hole(size, length, fit = 0) {
    translate([0, 0, -(length + 0.1)])
        cylinder(d = screw_body_d(size) + fit, h = length + 0.2);
}

// Clearance bore + cylindrical head recess (counterbore) for socket-cap or
// button heads seated below the surface. `length` is the full material
// thickness; the head recess is carved into the top.
//   length         : full thickness the shank crosses
//   fit            : added to the body diameter (mm)
//   head_d, head_h : recess diameter / depth; default to the socket-cap table
module counterbore_hole(size, length, fit = 0, head_d = undef, head_h = undef) {
    hd = head_d == undef ? cap_head(size)[0] : head_d;
    hh = head_h == undef ? cap_head(size)[1] : head_h;
    union() {
        // full-thickness shank clearance bore (+0.1 past both faces)
        translate([0, 0, -(length + 0.1)])
            cylinder(d = screw_body_d(size) + fit, h = length + 0.2);
        // cylindrical head recess at the mouth
        translate([0, 0, -hh])
            cylinder(d = hd, h = hh + 0.1);
    }
}

// Screw clearance hole with a head recess selected by `head`:
//   "countersunk" / "flat" : conical countersink (cs_angle, default 90 deg)
//   "socket" / "cap"       : cylindrical counterbore sized for a cap head
//   "button"               : cylindrical counterbore sized for a button head
//   "pan" / "none"         : no recess — a plain clearance bore (head sits proud)
// `length` is the full material thickness the shank crosses.
//   fit      : added to the body diameter (mm); 0 = exact body dia
//   cs_angle : countersink included angle for flat heads (deg)
module screw_hole(size, length, head = "countersunk", fit = 0, cs_angle = 90) {
    bd = screw_body_d(size) + fit;

    if (head == "countersunk" || head == "flat") {
        hd = cs_head_d(size);
        ht = (hd - bd) / 2 / tan(cs_angle / 2); // countersink depth
        union() {
            translate([0, 0, -(length + 0.1)])
                cylinder(d = bd, h = length + 0.2);
            translate([0, 0, -ht])
                cylinder(d1 = bd, d2 = hd, h = ht);
            translate([0, 0, -0.001])         // break the top surface
                cylinder(d = hd, h = 0.1);
        }
    } else if (head == "socket" || head == "cap") {
        counterbore_hole(size, length, fit, cap_head(size)[0], cap_head(size)[1]);
    } else if (head == "button") {
        counterbore_hole(size, length, fit, button_head(size)[0], button_head(size)[1]);
    } else if (head == "pan" || head == "none") {
        clearance_hole(size, length, fit);
    } else {
        assert(false, str("screw_hole: unknown head type '", head, "'"));
    }
}

// ===========================================================================
// Demo (renders only when this file is opened / included directly)
// ===========================================================================
$fn = 48;

module _demo_block(x, thickness = 10)
    translate([x, -7, -thickness]) cube([12, 14, thickness]);

// Left to right: heat-set insert, countersunk, socket cap, button, and a
// plain clearance hole — all M3, sliced so the recess profile is visible.
_specs = ["insert", "countersunk", "socket", "button", "none"];
for (i = [0 : len(_specs) - 1]) {
    x = i * 16 - 40;
    difference() {
        _demo_block(x);
        translate([x + 6, 0, 0])
            if (_specs[i] == "insert") insert_hole("M3");
            else screw_hole("M3", 8, head = _specs[i]);
    }
}
