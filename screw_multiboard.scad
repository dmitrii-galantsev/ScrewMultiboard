// Multiboard - Screw your license. Your file organization is abysmal. Because
// you can't figure out how to batch-link the files - I am taking it upon
// myself to design ScrewMultiboard. Which is legally distict from Multiboard.

include <BOSL2/std.scad>
include <BOSL2/threading.scad>

$fn = $preview ? 20 : 100;
$fn2 = $fn;

off = 0.25;

large_d = 22.5 - off;
large_p = 2.5;

mid_d = 14.25 - off;
mid_p = 3;

small_d = 7.025 - off;
small_d2 = 6.069 - off;
small_p = mid_p;

HEIGHT = 10;

large_oct_o = 27.2;
large_oct_i = 21.4;
//mid_oct_o = large_oct_i-off;
mid_oct_o = large_oct_i;
mid_oct_i = 13.5;
//small_oct_o = mid_oct_i-off;
//small_oct_o = mid_oct_i+off;
small_oct_o = mid_oct_i;

module base(d=mid_oct_i, h=7.9, d2=undef, h2=1, anchor=CENTER, spin=0, orient=UP) {
    function calc_d2(d1, h=10, angle=1.161) =
        let (
            // Calculate radius 1
            r1 = d1 / 2,
            // Calculate change in radius using tan(angle) * height
            delta_r = tan(angle) * h,
            // Calculate radius 2
            r2 = r1 - delta_r
        )
        // Return diameter 2 (2 * r2)
        2 * r2;

    function calc_circum_mult(sides=8) = (1/cos(180/sides));

    assert(h > h2);

    d2 = is_num(d2) ? d2 : calc_d2(d, h);

    module _base() {
        color_this([1, 0, 1, 0.5])
        cyl(d1=d, d2=d2, h=h-h2, chamfer2=1, chamfang2=30, $fn=8, circum=true, anchor=anchor)
            attach(BOTTOM, TOP)
                color_this([0, 1, 1, 0.5])
                cyl(d=d, h=h2, $fn=8, circum=true, anchor=anchor);
    }

    // pretend to be normal cyl because otherwise objects will be tilted
    // d*(1/cos(180/8)) is same as enclosing a circle
    attachable(anchor, spin, orient=orient, d=d*calc_circum_mult(), l=h) {
        // up by half the flat-sided cylinder because those are stacked on top of each other
        up(h2/2)
            _base();
        children();
    }
}

module rod(d, l=20, pitch=2.5, flank_angle=45, anchor=BOTTOM, thread_mult=0.25, internal=false) {
    $fn = $fn2;
    trapezoidal_threaded_rod(d=d, l=l, pitch=pitch, anchor=anchor, thread_depth=pitch*thread_mult, internal=internal, flank_angle=flank_angle)
        children();
}

module nut(d, od=undef, id=undef, pitch=2.5, h=HEIGHT, h2=1, flank_angle=60, slop=0, thread_mult=0.25)
{
    // set _od = od if od is defined
    // fallback to d + slop * 5 + 5
    _od =
        is_num(od) ?
        od :
        d+(slop*5)+5;

    if (is_num(od)) {
        assert(_od == od);
    }

    difference() {
        difference() {
            base(_od, h, h2=h2);
            // if id is present - add base-shaped hole
            if (is_num(id)) {
                hide_this()
                    base(_od, h, h2=h2)
                        attach(TOP, BOTTOM, inside=true, overlap=0.01)
                            base(id, h, h2=h2);
            }
        }
        // if d is present - add thread
        if (is_num(d) && d > 0) {
            hide_this()
                base(_od, h, h2=h2)
                    attach(TOP, BOTTOM, inside=true, overlap=0.01)
                        rod(d=d+slop, l=HEIGHT*1.01, pitch=pitch, anchor=BOTTOM, flank_angle=flank_angle, $fn=$fn2, internal=true, thread_mult=thread_mult);
        }
    }

    // children can only attach, not diff
    // however, difference() still works
    if ($children > 0) {
        hide_this()
            cyl(d=_od, h=h, $fn=8, circum=true)
                children($fn=$fn2);
    }
}

module large_nut(d=large_d, od=large_oct_o, id=large_oct_i, pitch=large_p, slop=off) {
    nut(d=d, od=od, id=id, pitch=pitch, slop=slop)
        children();
}

module mid_nut(d=mid_d, od=mid_oct_o, id=mid_oct_i, pitch=mid_p, slop=off) {
    nut(d=d, od=od, id=id, pitch=pitch, slop=slop)
        children();
}

module small_nut(d=small_d, od=small_oct_o, pitch=small_p, slop=off*1.5, thread_mult=0.15, rod=false, small_rod=true) {
    nut(d=rod ? undef : d, od=od, pitch=pitch, slop=slop, thread_mult=thread_mult, h2=3)
    {
        children();
        if (rod)
            attach(BOTTOM, TOP)
                rod(d=small_rod ? d : mid_d, l=HEIGHT, pitch=pitch);
    }
}

module small_nut_small_rod(d=small_d, od=small_oct_o, pitch=small_p, slop=off*1.5, thread_mult=0.15) {
    small_nut(d=d, od=od, pitch=pitch, slop=slop, thread_mult=thread_mult, rod=true, small_rod=true)
        children();
}

module small_nut_mid_rod(d=small_d, od=small_oct_o, pitch=small_p, slop=off*1.5, thread_mult=0.15) {
    small_nut(d=d, od=od, pitch=pitch, slop=slop, thread_mult=thread_mult, rod=true, small_rod=false)
        children();
}

base(d=mid_oct_o, h=HEIGHT)
{
    // rods
    attach(TOP, BOTTOM)
    rod(d=large_d, l=HEIGHT, pitch=large_p, anchor=BOTTOM)
        attach(TOP, BOTTOM)
        rod(d=mid_d, l=HEIGHT, pitch=mid_p)
            attach(TOP, BOTTOM)
                rod(d=small_d, l=HEIGHT, pitch=small_p);
    // nuts
    attach(RIGHT, LEFT, overlap=-1)
    large_nut()
        attach(RIGHT, LEFT, overlap=-1)
        mid_nut()
            attach(RIGHT, LEFT, overlap=-1)
            small_nut()
                // other
                zflip()
                attach(RIGHT, LEFT, overlap=-1)
                xflip() // not sure why threads reverse without this. because of zflip?
                small_nut_mid_rod()
                    attach(RIGHT, LEFT, overlap=-1)
                        small_nut_small_rod();
}

