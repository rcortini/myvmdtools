proc hq_render {name x y} {
  render Tachyon "$name.dat" "/usr/bin/tachyon" -aasamples 12 -res [expr $x*1.5] [expr $y*1.5] -fullshade %s -format TARGA -o %s.tga
}
