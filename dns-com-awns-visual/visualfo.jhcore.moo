@create $feature named Visual FO (vfo):Visual FO (vfo),vfo
@prop __VFO__."handler" __VEH__ rc
@prop __VFO__."users" {} rc
;__VFO__.("description") = "A token FO to hang an event handler from.  The handler will speak dns-com-awns-visual to the client."

@verb __VFO__:"feature_add" this none this
@program __VFO__:feature_add
who = args[1];
"called from $player:add_feature, which runs as $hacker";
if (caller_perms() == $hacker)
  "this may need wizperms if $player:add_handler gets perms checks";
  who:add_handler(this.handler);
else
  return E_PERM;
endif
.

@verb __VFO__:"feature_remove" this none this
@program __VFO__:feature_remove
"called from $player:remove_feature, which runs as $hacker";
who = args[1];
if (caller_perms() == $hacker)
  this.handler:remove_self_from(who);
else
  return E_PERM;
endif
.

@verb __VFO__:"player_connected" this none this
@program __VFO__:player_connected
":player_connected(), called when the user connects.  wait for MCP/2.1 to";
"complete negotiation and if dns-com-awns-visual is supported then send";
"the user's location to the client and add the user to the list of people";
"who will receive periodic 'who' updates.";
session = $mcp:session_for(player);
if (!valid(session))
  return;
endif
package = $mcp:match_package("dns-com-awns-visual");
if (session:wait_for_package(package) != {1, 0})
  return;
endif
package:send_location(session, tostr(player.location));
this.users = setadd(this.users, player);
.

@verb __VFO__:"@visual_who" none none none rx
@program __VFO__:@visual_who
if (player in this.users)
  this.users = setremove(this.users, player);
  player:tell("No more Visual who information for you.");
else
  this.users = setadd(this.users, player);
  player:tell("You'll get Visual who information now.");
endif
.

@verb __VFO__:"update_who" this none this
@program __VFO__:update_who
"trillions of lines of data... no way does this sucker scale up...";
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
endif
package = $mcp:match_package("dns-com-awns-visual");
if (!valid(package))
  player:tell("can't find package dns-com-awns-visual");
  return E_INVARG;
endif
while (1)
  id = {};
  name = {};
  location = {};
  idle = {};
  for user in (connected_players())
    $command_utils:suspend_if_needed(0);
    id = {@id, tostr(user)};
    name = {@name, user:title()};
    location = {@location, tostr(user.location)};
    idle = {@idle, tostr(idle_seconds(user))};
  endfor
  for user in (this.users)
    $command_utils:suspend_if_needed(0);
    session = $mcp:session_for(user);
    if (valid(session) && (session:handles_package(package) == {1, 0}))
      package:send_users(session, id, name, location, idle);
    endif
  endfor
  suspend(60);
endwhile
.

@verb __VFO__:"player_disconnected" this none this
@program __VFO__:player_disconnected
this.users = setremove(this.users, player);
.
