// skeletonized_wall.scad
//
// A skeletonized wall: a grid of rectangular cells with diagonal cross
// braces. Removes material (weight / print time / filament) from a solid
// wall while keeping stiffness through the triangulated bracing.
//
// Units are millimeters. The wall face lies in the XY plane (width along X,
// height along Y) and is extruded along Z by `thickness`. To stand it up as
// an actual wall, rotate([90, 0, 0]) after calling.
//
// Usage:
//   use <skeletonized_wall.scad>
//   skeletonized_wall(width = 80, height = 40, thickness = 3,
//                     cols = 4, rows = 2, strut = 1.6);
//
// Open this file directly (or `include <>` it) to render the demo at the
// bottom; `use <>` imports the modules without rendering anything.

// ---------------------------------------------------------------------------
// Low-level helper
// ---------------------------------------------------------------------------

// A thick 2D line segment from p1 to p2 with the given width and rounded
// ends, so struts meeting at a node blend into a smooth joint.
module strut(p1, p2, width, fn = 16) {
    hull() {
        translate(p1) circle(d = width, $fn = fn);
        translate(p2) circle(d = width, $fn = fn);
    }
}

// ---------------------------------------------------------------------------
// 2D pattern
// ---------------------------------------------------------------------------

// The flat skeletonized pattern in the XY plane, occupying [0,width] x [0,height].
//
//   width, height : overall size of the panel (mm)
//   cols, rows    : number of cells across and up
//   strut         : thickness of the internal struts and diagonals (mm)
//   frame_strut   : thickness of the outer border; defaults to strut
//   braces        : diagonal style per cell -
//                     "x" both diagonals (default), "/" or "\" a single
//                     diagonal, "none" for an open grid
module skeletonized_wall_2d(width, height, cols = 3, rows = 2,
                            strut = 1.6, frame_strut = undef, braces = "x") {
    fs = is_undef(frame_strut) ? strut : frame_strut;
    cw = width / cols;
    ch = height / rows;

    union() {
        // Outer frame.
        strut([0, 0],          [width, 0],       fs);
        strut([width, 0],      [width, height],  fs);
        strut([width, height], [0, height],      fs);
        strut([0, height],     [0, 0],           fs);

        // Internal vertical dividers.
        if (cols > 1)
            for (i = [1 : cols - 1])
                strut([i * cw, 0], [i * cw, height], strut);

        // Internal horizontal dividers.
        if (rows > 1)
            for (j = [1 : rows - 1])
                strut([0, j * ch], [width, j * ch], strut);

        // Diagonal cross bracing, per cell.
        for (i = [0 : cols - 1], j = [0 : rows - 1]) {
            x0 = i * cw; y0 = j * ch;
            x1 = x0 + cw; y1 = y0 + ch;
            if (braces == "x" || braces == "/")
                strut([x0, y0], [x1, y1], strut);
            if (braces == "x" || braces == "\\")
                strut([x0, y1], [x1, y0], strut);
        }
    }
}

// ---------------------------------------------------------------------------
// 3D wall
// ---------------------------------------------------------------------------

// The skeletonized pattern extruded to a solid wall of the given thickness.
// Parameters match skeletonized_wall_2d plus:
//   thickness : extrusion depth along Z (mm)
module skeletonized_wall(width, height, thickness, cols = 3, rows = 2,
                         strut = 1.6, frame_strut = undef, braces = "x") {
    linear_extrude(height = thickness, convexity = 10)
        skeletonized_wall_2d(width, height, cols, rows,
                             strut, frame_strut, braces);
}

// ---------------------------------------------------------------------------
// Demo (rendered only when this file is opened / included directly)
// ---------------------------------------------------------------------------

skeletonized_wall(width = 80, height = 40, thickness = 3,
                  cols = 4, rows = 2, strut = 1.6, frame_strut = 2.4);
