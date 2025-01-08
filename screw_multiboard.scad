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
mid_oct_o = 24;
mid_oct_i = 13.5;
small_oct_o = mid_oct_i-off;

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

module base(d=mid_oct_i, h=7.9, d2=undef) {
    assert(h > 1);

    d2 = is_num(d2) ? d2 : calc_d2(d, h);

        color_this([0, 1, 1, 0.5])
            cyl(d=d, d2=d2, h=h, chamfer2=1, chamfang2=30, $fn=8, circum=true, anchor=BOTTOM)
            children();
}

module rod(d, l=20, pitch=2.5, flank_angle=45, anchor=BOTTOM, thread_mult=0.25, internal=false) {
    $fn = $fn2;
    trapezoidal_threaded_rod(d=d, l=l, pitch=pitch, anchor=anchor, thread_depth=pitch*thread_mult, internal=internal, flank_angle=flank_angle)
    children();
}

module nut(d, od=undef, pitch=2.5, h=HEIGHT, flank_angle=60, slop=0, thread_mult=0.25)
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

    diff() {
        base(_od, h)
            attach(TOP, BOTTOM, inside=true, overlap=0.01)
            rod(d=d+slop, l=HEIGHT*1.01, pitch=pitch, anchor=BOTTOM, flank_angle=flank_angle, $fn=$fn2, internal=true, thread_mult=thread_mult);
    }

    if ($children > 0) {
        hide_this() cyl(d=_od, h=h, $fn=8, anchor=BOTTOM, circum=true)
            {
                children($fn=$fn2);
            }
    }
}

// push fit stuff


//push_fit_angle = 1.161;
//push_fit_d2 = calc_d2(d1, h, push_fit_angle); // 13.220
// ok it's just a static 13.22

module push_fit(d1=mid_oct_i, h=6.9, d2=13.22) {
    diff()
    {
        color_this([1, 0, 1, 0.5])
            base(d1, h, d2)
                attach(BOTTOM, BOTTOM, inside=true, overlap=0.1)
                    rod(d=small_d+off, l=h*1.01+2, pitch=small_p, internal=true);
    }
    if ($children > 0) {
        hide_this() cyl(d=d1, h=h*1.01+1, $fn=8, anchor=BOTTOM, circum=true)
            {
                children($fn=$fn2);
            }
    }
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
    //yrot(1.161)
    align(RIGHT, BOTTOM, overlap=-1)
    nut(d=large_d, od=large_oct_o, pitch=large_p, slop=off)
        align(RIGHT, BOTTOM, overlap=-1)
        nut(d=mid_d, od=mid_oct_o, pitch=mid_p, slop=off)
            align(RIGHT, BOTTOM, overlap=-1)
            nut(d=small_d, od=small_oct_o, pitch=small_p, slop=off*1.5, thread_mult=0.15)
                // other
                zflip()
                align(RIGHT, BOTTOM, overlap=-1)
                base(d=small_oct_o, h=HEIGHT)
                {
                    attach(BOTTOM, TOP)
                        rod(d=mid_d, l=HEIGHT, pitch=mid_p);
                    align(RIGHT, BOTTOM, overlap=-1)
                        base(d=small_oct_o, h=HEIGHT) {
                            zflip()
                            attach(TOP, BOTTOM)
                                rod(d=small_d, l=HEIGHT, pitch=small_p);
                            zflip()
                            align(RIGHT, BOTTOM, overlap=-1)
                                push_fit();
                        }
                }

}
