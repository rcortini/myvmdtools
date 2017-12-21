proc hq_render {name} {
  set size [display get size]
  set x [lindex $size 0]
  set y [lindex $size 1]
  render Tachyon "$name.dat" "/usr/bin/tachyon" -aasamples 12 -res [expr $x*1.5] [expr $y*1.5] -fullshade %s -format TARGA -o %s.tga
}

proc render_frames {name startframe endframe} {
  file mkdir $name
  # save viewpoint
  save_vp 1
  write_vps "$name/viewpoint.tcl"
  # render
  for {set i $startframe} {$i<$endframe} {incr i} {
    animate goto $i
    set frame_id [format "%05d" $i]
    hq_render "$name/frame-$frame_id"
  }
}


