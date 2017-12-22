# root directory of the sbs_tracers simulations
set root_name "sbs_tracers"
set root_dir "$::env(HOME)/work/data/hoomd/$root_name"

proc add_rep {currentMol numreps} {
  mol addrep $currentMol
  set rep [mol repname $currentMol $numreps]
  set ID [mol repindex $currentMol $rep]
  return $ID
}

# this function sets up the visualization state for the polymer
proc sbs_tracers_rep {molid} {
  # variable settings
  set res 30.0
  set polymer_radius 0.3
  set binder_radius 1.0
  set tracer_radius 1.0
  set factors_radius 1.0
  set blue 0
  set red 1

  # init
  set currentMol $molid
  set numreps [molinfo $currentMol get numreps]

  # fix the name of the "D1" atoms
  set D1 [atomselect $molid "name D1"]
  $D1 set name "F"

  # color definitions
  color Name C red
  color Name A blue2
  color Name B blue
  color Name D yellow
  color Name F yellow3

  # polymer representation
  set polymerrepID [add_rep $currentMol $numreps]
  mol modselect $polymerrepID $currentMol "name A or name B"
  mol modstyle $polymerrepID $currentMol Licorice $polymer_radius $res $res
  mol modmaterial $polymerrepID $currentMol AOShiny

  # factors representation
  incr numreps
  set factorsrepID [add_rep $currentMol $numreps]
  mol modselect $factorsrepID $currentMol "name C"
  mol modstyle $factorsrepID $currentMol VDW $factors_radius $res
  mol modmaterial $factorsrepID $currentMol AOEdgy

  # tracers representation
  incr numreps
  set tracersrepID [add_rep $currentMol $numreps]
  mol modselect $tracersrepID $currentMol "name D"
  mol modstyle $tracersrepID $currentMol VDW $tracer_radius $res
  mol modmaterial $tracersrepID $currentMol AOEdgy

  # tracers representation
  incr numreps
  set tracers1repID [add_rep $currentMol $numreps]
  mol modselect $tracers1repID $currentMol "name F"
  mol modstyle $tracers1repID $currentMol VDW $tracer_radius $res
  mol modmaterial $tracersrepID $currentMol AOEdgy
}

proc sim_basename {phi e} {
  global root_name
  return "$root_name-phi-$phi-e-$e"
}

proc sim_name {phi e n} {
  set basename [sim_basename $phi $e]
  return "$basename-$n"
}

proc sim_directory {run_id phi e n} {
  global root_dir
  set basename [sim_basename $phi $e]
  set simname [sim_name $phi $e $n]
  return "$root_dir/production/$run_id/$basename/$simname"
}

# function to load a simulation from the sbs_tracers production runs
proc sbs_tracers_loadsim {run_id phi e n} {
  set simdir [sim_directory $run_id $phi $e $n]
  set simname [sim_name $phi $e $n]
  set xml "$simdir/$simname.xml"
  set dcd "$simdir/$simname.dcd"

  # load trajectory
  set molId [mol new $dcd type {dcd} first 0 last -1 step 1 waitfor all]
  mol addfile $xml type {hoomd} first 0 last -1 step 1 waitfor all $molId

  # delete last frame
  set nframes [molinfo top get numframes]
  set lastframe [expr $nframes-1]
  animate delete beg $lastframe end $lastframe skip 0 $molId

  # nice visualization
  sbs_tracers_rep $molId

  # delete initial "lines" representation
  mol delrep 0 $molId
}

proc prepare_render {} {
  # display settings
  set x 1280
  set y 960
  display resize $x $y
  color Display Background white
  display shadows on
  display ambientocclusion on
  display aoambient 0.7
  display aodirect 0.4
}

proc load_sim {run_id phi e n} {
  # polymer representation
  set polymerrepID [add_rep $molid $numreps]
  mol modselect $polymerrepID $molid "name A or name B"
  mol modstyle $polymerrepID $molid Licorice 0.3 $res $res
  mol smoothrep $molid $polymerrepID $smooth

  # tracers representation
  incr numreps
  set tracersrepID [add_rep $molid $numreps]
  mol modselect $tracersrepID $molid "name D"
  # mol modselect $tracersrepID $molid "index $my_tracer_id"
  mol modstyle $tracersrepID $molid VDW $tracer_radius $res
  mol modcolor $tracersrepID $molid ColorID 4
  mol smoothrep $molid $tracersrepID $smooth

  # delete initial "lines" representation
  mol delrep 0 $molid

  # see if viewpoint exists
  set name "phi-$phi-e-$e-$n"
  set vpf "$name/viewpoint.tcl"
  if {[file exists $vpf]} {
    source $vpf
    retrieve_vp 1
  }
}

proc xml_pbc_fix {} {
  # unwrap tracers and factors coordinates
  pbc wrap -all -center origin -compound fragment
}

proc get_particle_images {molid particle_text} {
  set dims [lindex [pbc get] 0]
  set particle [atomselect $molid $particle_text]
  set pos [lindex [$particle get {x y z}] 0]
  set images [list]
  for {set i 0} {$i < 3} {incr i} {
    set xi [lindex $pos $i]
    set di [lindex $dims $i]
    set di2 [expr $di/2.0]
    set images [lappend images [expr floor(($xi+$di2)/$di)]]
  }
  return $images
}

proc bring_polymer_to_center {molid polymer_text central_particle_text} {
  # select polymer
  set polymer [atomselect $molid $polymer_text]

  # get the image index of the central particle
  set images [get_particle_images $molid $central_particle_text]

  # calculate the offset by which we should move the polymer
  set offset [list]
  set dims [lindex [pbc get] 0]
  for {set i 0} {$i < 3} {incr i} {
    set offset [lappend offset [expr -[lindex $images $i] * [lindex $dims $i]]]
  }

  # now set new coordinates
  set newcoords [list]
  foreach coord [$polymer get {x y z}] {
    set newcoords [lappend newcoords [vecadd $coord $offset]]
  }
  $polymer set {x y z} $newcoords
}

proc gsd_pbs_fix {molid polymer_text central_particle_text} {
  set nframes [molinfo top get numframes]
  for {set i 0} {$i < $nframes} {incr i} {
    animate goto $i
    pbc join fragment -bondlist
    bring_polymer_to_center $molid $polymer_text $central_particle_text
  }
}
