"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__TOP__ is the object id of the associated Topology Driver
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-visual:dns-com-awns-visual
@prop __NEW__."topology_driver" __TOP__ rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"getusers", {}}, {"getlocation", {}}, {"gettopology", {"location", "distance"}}, {"getself", {}}})
;__NEW__:set_messages_out({{"location", {"id"}}, {"users", {"id", "name", "location", "idle"}}, {"topology", {"id", "name", "exit"}}, {"self", {"id"}}})

@verb __NEW__:"send_" this none this
@program __NEW__:send_
return pass(@args);
.

@verb __NEW__:"users" this none this
@program __NEW__:users
"=> { {id, name, location, idle}... }";
users = {};
for user in (connected_players())
  users = {@users, {user, user:title(), user.location, idle_seconds(user)}};
endfor
return users;
.

@verb __NEW__:"send_location" this none this
@program __NEW__:send_location
return pass(@args);
.

@verb __NEW__:"send_topology" this none this
@program __NEW__:send_topology
return pass(@args);
.

@verb __NEW__:"send_users" this none this
@program __NEW__:send_users
return pass(@args);
.

@verb __NEW__:"handle_getusers" this none this
@program __NEW__:handle_getusers
{session} = args;
session = $mcp:session_for(player);
package = $mcp:match_package("dns-com-awns-visual");
if (!valid(package))
  player:tell("dns-com-awns-visual not supported");
  return;
endif
if (session:handles_package(package) != {1, 0})
  player:tell("dns-com-awns-visual/1.0 not supported");
  return;
endif
id = {};
name = {};
location = {};
idle = {};
for user in (connected_players())
  id = {@id, tostr(user)};
  name = {@name, user:title()};
  location = {@location, tostr(user.location)};
  idle = {@idle, tostr(idle_seconds(user))};
endfor
"SUBOPTIMAL, sends a *lot* of lines of text...";
package:send_users(session, id, name, location, idle);
.

@verb __NEW__:"handle_getlocation" this none this
@program __NEW__:handle_getlocation
{session} = args;
"send the new location...";
session = $mcp:session_for(player);
if (!valid(session))
  return;
endif
package = $mcp:match_package("dns-com-awns-visual");
if (session:handles_package(package) != {1, 0})
  return;
endif
package:send_location(session, tostr(player.location));
.

@verb __NEW__:"handle_gettopology" this none this
@program __NEW__:handle_gettopology
{session, location, distance} = args;
session = $mcp:session_for(player);
package = $mcp:match_package("dns-com-awns-visual");
if (!valid(package))
  player:tell("dns-com-awns-visual not supported");
  return;
endif
if (session:handles_package(package) != {1, 0})
  player:tell("dns-com-awns-visual/1.0 not supported");
  return;
endif
topology = this.topology_driver:find_rooms(toobj(location), tonum(distance));
room_ids = {};
room_names = {};
room_exits = {};
for r in (topology)
  scan = this.topology_driver:scan(r);
  {room_id, room_name, exit_pairs} = scan;
  e = $list_utils:append(@exit_pairs);
  f = $string_utils:from_list(e, " ");
  room_ids = {@room_ids, tostr(room_id)};
  room_names = {@room_names, room_name};
  room_exits = {@room_exits, f};
endfor
package:send_topology(session, room_ids, room_names, room_exits);
.

@verb __NEW__:"send_self" this none this
@program __NEW__:send_self
return pass(@args);
.

@verb __NEW__:"handle_getself" this none this
@program __NEW__:handle_getself
{session} = args;
"send your id...";
session = $mcp:session_for(player);
if (!valid(session))
  return;
endif
package = $mcp:match_package("dns-com-awns-visual");
if (session:handles_package(package) != {1, 0})
  return;
endif
package:send_self(session, tostr(player));
.
