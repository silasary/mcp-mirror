"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-ping:dns-com-awns-ping
@prop __NEW__."callbacks" {} rc
@prop __NEW__."times" {} rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"", {"id"}}, {"reply", {"id"}}})
;__NEW__:set_messages_out({{"", {"id"}}, {"reply", {"id"}}})

@verb __NEW__:"handle_" this none this
@program __NEW__:handle_
if (caller == this)
  {session, id} = args;
  "reply if we support this package version (don't trust the client)";
  if (valid(package = $mcp.registry:match_package("dns-com-awns-ping")))
    if (session:handles_package(package) == {1, 0})
      package:send_reply(session, id);
    endif
  endif
endif
.

@verb __NEW__:"send_*" this none this
@program __NEW__:send_
"Doh! anyone can ping me!";
return pass(@args);
.

@verb __NEW__:"ping" this none this
@program __NEW__:ping
{session, ?o = $nothing, ?v = ""} = args;
if (!$perm_utils:controls(caller_perms(), session.connection))
  raise(E_PERM);
endif
id = task_id();
this.callbacks = setadd(this.callbacks, {session, tostr(id), o, v});
this:send_(session, id);
"timing stuff...";
if (ptiming = $list_utils:iassoc(session, this.times))
  this.times[ptiming][3] = time();
else
  this.times = setadd(this.times, {session, {0, 0, 0, 0, 0}, time()});
endif
.

@verb __NEW__:"handle_reply" this none this
@program __NEW__:handle_reply
{session, id} = args;
if (!$perm_utils:controls(caller_perms(), session.connection))
  raise(E_PERM);
endif
if (callback = $list_utils:assoc(session, this.callbacks))
  this.callbacks = setremove(this.callbacks, callback);
  {s, i, o, v} = callback;
  valid(o) && `o:(v)() ! 1';
endif
"timing stuff...";
if (ptiming = $list_utils:iassoc(session, this.times))
  rtt = time() - this.times[ptiming][3];
  times = {@this.times[ptiming][2], rtt};
  times = times[2..$];
  this.times[ptiming][2] = times;
endif
.

@verb __NEW__:"slow" this none this
@program __NEW__:slow
{session} = args;
return this:avg(session) > 1.0;
.

@verb __NEW__:"avg" this none this
@program __NEW__:avg
{session} = args;
if (timing = $list_utils:assoc(session, this.times))
  {s, times, latest} = timing;
  sum = 0.0;
  for t in (times)
    sum = sum + tofloat(t);
  endfor
  if (len = length(times))
    return sum / tofloat(length(times));
  else
    return 0.0;
  endif
else
  return 0.0;
endif
.
