@create $event_handler named Rehash Event Handler (reh):Rehash Event Handler (reh),reh
@prop __REH__."rehash_visited" {} rc
@prop __REH__."rehash_verbs" {} rc
@prop __REH__."rehash_list" {} rc
@prop __REH__."rehash_users" {} rc
@prop __REH__."feature" __RFO__ rc

@verb __REH__:"remove_self_from" this none this rx
@program __REH__:remove_self_from
"new security on handlers requires this handler call remove itself";
{who} = args;
(caller == this.feature) || raise(E_PERM);
return who:remove_handler(this);
.

@verb __REH__:"rehash" this none this
@program __REH__:rehash
"CUUUT AAAND PAAAASTE TERRRORRRR!";
{who, ?full = 0} = args;
cu = $command_utils;
su = $string_utils;
observed = {};
if (full)
  visited = {};
  contributed = {};
else
  "objects which have been processed and cached";
  visited = this.rehash_visited;
  "verbs contributed by each object";
  contributed = this.rehash_verbs;
endif
"rooms";
"player is in p.l.c";
for oo in ({who.location, @who.location.contents, @who.contents, @who.location:obvious_exits(this)})
  cu:suspend_if_needed(0);
  object = oo;
  while (valid(object))
    observed = setadd(observed, object);
    if (!(object in visited))
      visited = {@visited, object};
      contributed = {@contributed, this:rehash_object(object)};
    endif
    object = parent(object);
  endwhile
endfor
"obvious exits";
for c in (who.location:obvious_exits(this))
  cu:suspend_if_needed(0);
  object = c;
  observed = setadd(observed, object);
  "names of exits too I suppose";
  psn = object in visited;
  for n in (su:explode(object:name()))
    contributed[psn] = {@contributed[psn], n};
  endfor
endfor
"features";
for object in (who.features)
  if ( !$recycler:valid(object) || !$object_utils:isa(object, $feature) )
    "FOs have an onnoying habit of being recycled from time to time";
    continue;
  endif;
  cu:suspend_if_needed(0);
  observed = setadd(observed, object);
  if (!(object in visited))
    visited = {@visited, object};
    contributed = {@contributed, {}};
    vs = object.commands;
    for vv in (vs)
      if (typeof(vv) != STR)
        continue;
      endif
      psn = object in visited;
      for v in (su:explode(vv))
        contributed[psn] = {@contributed[psn], v};
      endfor
    endfor
  endif
endfor
this.rehash_visited = visited;
this.rehash_verbs = contributed;
"merge all verbs";
verbs = {};
for object in (observed)
  cu:suspend_if_needed(0);
  psn = object in visited;
  for verb in (contributed[psn])
    verbs = setadd(verbs, verb);
  endfor
endfor
"filter out non alphas, the client also does this...";
likely = {};
for v in (verbs)
  cu:suspend_if_needed(0);
  if (index(su.alphabet, v[1]))
    likely = {@likely, v};
  endif
endfor
psn = who in this.rehash_users;
if (!psn)
  this.rehash_users = {@this.rehash_users, who};
  this.rehash_list = {@this.rehash_list, {}};
  psn = who in this.rehash_users;
endif
session = $mcp:session_for(who);
if (!valid(session))
  return;
endif
package = $mcp:match_package("dns-com-awns-rehash");
if (!valid(package))
  return;
endif
if (session:handles_package(package) != {1, 0})
  return;
endif
if (full)
  "eg, verb== @rehash!";
  if (likely)
    package:send_commands(session, su:lowercase(su:from_list(likely, " ")));
  endif
else
  "eg, verb== @rehash";
  cu:suspend_if_needed(0);
  add = $set_utils:difference(likely, this.rehash_list[psn]);
  remove = $set_utils:difference(this.rehash_list[psn], likely);
  if (add)
    package:send_add(session, su:lowercase(su:from_list(add, " ")));
  endif
  if (remove)
    package:send_remove(session, su:lowercase(su:from_list(remove, " ")));
  endif
endif
this.rehash_list[psn] = likely;
.

@verb __REH__:"rehash_object" this none this
@program __REH__:rehash_object
{object} = args;
verbs = {};
vs = $code_utils:verbs(object);
for vv in (vs)
  if (typeof(vv) != STR)
    continue;
  endif
  for v in ($string_utils:explode(vv))
    xv = strsub(v, "*", "");
    verb_args = `verb_args(object, xv) ! ANY => 0';
    if (verb_args && (verb_args != {"this", "none", "this"}))
      verbs = {@verbs, v};
    endif
  endfor
endfor
return verbs;
.

@verb __REH__:"handle_event_enter" this none this
@program __REH__:handle_event_enter
{who, hem, er} = args;
if (is_player(who) && (this.feature in who.features))
  this:rehash(who);
endif
.

@verb __REH__:"handle_event_exit" this none this
@program __REH__:handle_event_exit
{who, hem, er} = args;
if (is_player(who) && (this.feature in who.features))
  this:rehash(who);
endif
.
