@create $thing named Topology Driver:Topology Driver
@prop __TOP__."cardinal_directions" {} rc
;__TOP__.("cardinal_directions") = {"n", "ne", "e", "se", "s", "sw", "w", "nw"}
;__TOP__.("description") = {"Topology Driver for JHCore", "", "Used by dns-com-awns-visual package to supply topology information.", "", "Implements:", "", ":scan(OBJ room)", "  => {OBJ room, STR title, LIST of direction-room pairs}", "  direction-room = { STR direction, OBJ toroom }", "", "scan room looking for possible exits and return a list conting the room id, the room's title and the list of possible exits.", "", ":find_rooms(OBJ room, INT limit)", "  => LIST rooms", "", "traverse the MOO toplogy finding all rooms reachable within <limit>-rooms distance of <room>.", "", ":real_exits(room)", "  => LIST of exit objects"}

@verb __TOP__:"scan" this none this
@program __TOP__:scan
":scan(room) => {room, title, <list of direction,room pairs>}";
{room} = args;
obvious_exits = room:obvious_exits();
exits = obvious_exits;
kv = {};
"this list shouldn't be hard coded...";
"$english.cardinal_directions";
exits = {};
for direction in ({"n", "ne", "e", "se", "s", "sw", "w", "nw", "u", "d", "out"})
  exit = room:match_exit(direction);
  "an exit, and not false?";
  if ((((valid(exit) && (exit.dest != room)) && $object_utils:isa(exit.dest, $room)) && (exit.dest != $room)) && exit.obvious)
    kv = {@kv, {direction, exit.dest}};
    exits = {@exits, exit};
  endif
  "room:match_exit";
endfor
"non cardinal exits";
all = obvious_exits;
for e in (all)
  "an exit, and not false?";
  if (((((!(e in exits)) && valid(exit)) && $object_utils:isa(exit.dest, $room)) && (exit.dest != $room)) && exit.obvious)
    exits = {@exits, e};
    "Aaaargh, some exits can have spaces in their name, yuck...";
    name = $string_utils:explode(e.dest.name, " ")[1];
    kv = {@kv, {name, e.dest}};
  endif
endfor
"kv == {} is no error, we just have no obvious exits, send anyway to be sure";
"         that we've reset the widget";
return {room, room:title(), kv};
.

@verb __TOP__:"find_rooms" this none this
@program __TOP__:find_rooms
":find_rooms(room, limit) => LIST rooms";
"find all the rooms within <limit>-rooms distance of <room>";
{room, limit} = args;
"a breadth-first search";
rooms = {};
new_rooms = {room};
while (limit >= 0)
  exits = {};
  for r in (new_rooms)
    exits = {@exits, @this:real_exits(r)};
  endfor
  rooms = {@rooms, @new_rooms};
  new_rooms = {};
  for e in (exits)
    if (!(e.dest in rooms))
      new_rooms = setadd(new_rooms, e.dest);
    endif
  endfor
  limit = limit - 1;
endwhile
return rooms;
.

@verb __TOP__:"real_exits" this none this
@program __TOP__:real_exits
":real_exits(room) => LIST of exit objects";
{room} = args;
exits = {};
others = {};
for direction in ({"u", "d"})
  exit = room:match_exit(direction);
  others = {@others, exit};
endfor
for direction in (this.cardinal_directions)
  exit = room:match_exit(direction);
  if ((((valid(exit) && (exit.dest != room)) && $object_utils:isa(exit.dest, $room)) && (exit.dest != $room)) && (!(exit in others)))
    exits = {@exits, exit};
  endif
endfor
return exits;
.
