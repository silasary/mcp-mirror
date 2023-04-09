@create $event_handler named Visual Event Handler (veh):Visual Event Handler (veh),veh
;__VEH__.("handler_ok") = 1
;__VEH__.("feature") = __VFO__

@verb __VEH__:"remove_self_from" this none this rx
@program __VEH__:remove_self_from
"new security on handlers requires this handler call remove itself";
{who} = args;
(caller == this.feature) || raise(E_PERM);
return who:remove_handler(this);
.

@verb __VEH__:"handle_event_enter" this none this
@program __VEH__:handle_event_enter
{who, hem, er} = args;
if (((player == who) && er) && (er[1] == player))
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
endif
.
