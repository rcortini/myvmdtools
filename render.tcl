proc hq_render {name} {
  set size [display get size]
  set x [lindex $size 0]
  set y [lindex $size 1]
  render Tachyon "$name.dat" "/usr/bin/tachyon" -aasamples 12 -res [expr $x*1.5] [expr $y*1.5] -fullshade %s -format TARGA -o %s.tga
}
