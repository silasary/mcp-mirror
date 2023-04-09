@create __PACKAGE__ named dns-com-vmoo-mmedia:dns-com-vmoo-mmedia
@prop __MMEDIA__."accept_info" {} "r"
;;__MMEDIA__.("accept_info") = {}
@prop __MMEDIA__."default_base" "" "r"
@prop __MMEDIA__."show_info" {} "r"
;;__MMEDIA__.("show_info") = {}
@prop __MMEDIA__."music_info" {} "r"
@prop __MMEDIA__."play_info" {} "r"
;;__MMEDIA__.("play_info") = {}
@prop __MMEDIA__."logo" "" r
@prop __MMEDIA__."insert_info" {} "r"
@prop __MMEDIA__."alias_info" {} "r"
;;__MMEDIA__.("version_range") = {"2.0", "2.0"}
;;__MMEDIA__.("messages_in") = {{"accept", {}}, {"ack-failed", {"ack-id", "method", "stage"}}, {"ack-stage", {"ack-id", "method", "stage"}}, {"ack-done", {"ack-id", "method", "stage", "reason"}}}
;;__MMEDIA__.("messages_out") = {{"base", {"url"}}, {"play", {}}, {"show", {}}, {"music", {}}, {"insert", {}}, {"preload", {}}}
;;__MMEDIA__.("key") = 0
;;__MMEDIA__.("aliases") = {"dns-com-vmoo-mmedia"}
;;__MMEDIA__.("object_size") = {20122, 959530283}

@verb __MMEDIA__:"handle_accept" this none this rxd
@program __MMEDIA__:handle_accept
{session, @args} = args;
if (caller != this)
  return E_PERM;
endif
who = session.connection;
this:accept_info(who, args);
this.logo && this:show(who, this.logo);
.

@verb __MMEDIA__:"match_arg" this none this rxd
@program __MMEDIA__:match_arg
{wat, waarin} = args;
for info in (waarin)
  if (info[1] == wat)
    return info[2];
  endif
endfor
return E_VARNF;
.

@verb __MMEDIA__:"accept_info show_info music_info play_info insert_info alias_info" this none this rxd
@program __MMEDIA__:accept_info
{who, info} = args;
if (caller != this)
  return E_PERM;
endif
if (idx = $list_utils:iassoc(who, this.(verb)))
  if (verb == "alias_info")
    this.(verb)[idx] = {who, setadd(this.(verb)[idx][2], info[1])};
  else
    this.(verb)[idx] = {who, info};
  endif
else
  this.(verb) = {@this.(verb), {who, info}};
endif
.

@verb __MMEDIA__:"accepts_type" this none this rxd
@program __MMEDIA__:accepts_type
{who, method, ext} = args;
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
endif
ext = ("," + ext) + ",";
return ((info = $list_utils:assoc(who, this.accept_info)) && (types = this:match_arg(method, info[2]))) && (index(("," + types) + ",", ext) != 0);
.

@verb __MMEDIA__:"accepts_protocol" this none this rxd
@program __MMEDIA__:accepts_protocol
{who, prot} = args;
prot = ("," + prot) + ",";
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
endif
return ((info = $list_utils:assoc(who, this.accept_info)) && (protocols = this:match_arg("protocols", info[2]))) && (index(("," + protocols) + ",", prot) != 0);
.

@verb __MMEDIA__:"finalize_connection" this none this rxd
@program __MMEDIA__:finalize_connection
who = player;
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
endif
for prop in (properties(this))
  if (((length(prop) > 5) && (prop[$ - 4..$] == "_info")) && (idx = $list_utils:iassoc(who, this.(prop))))
    this.(prop) = listdelete(this.(prop), idx);
  endif
endfor
.

@verb __MMEDIA__:"send_base" this none this rxd
@program __MMEDIA__:send_base
{session, ?url = this.default_base} = args;
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
endif
if(url)
  return pass(session, url);
endif
.

@verb __MMEDIA__:"send_play send_show send_music" this none this rxd
@program __MMEDIA__:send_play
{session, @args} = args;
if (caller != this)
  return E_PERM;
endif
return pass(session, @args);
.

@verb __MMEDIA__:"handle_ack-failed" this none this rxd
@program __MMEDIA__:handle_ack-failed
{session, id, method, stage} = args;
who = session.connection;
if (caller != this)
  return E_PERM;
endif
if (method == "preload")
  if ((idx = $list_utils:iassoc(who, this.alias_info)) && (idx2 = $list_utils:iassoc(id, this.alias_info[idx], 2)))
    if (!(this.alias_info[idx][2] = listdelete(this.alias_info[idx][2], idx2)))
      this.alias_info = listdelete(this.alias_info, idx);
    endif
  endif
else
  this:(method + "_info")(who, {id, {"failed", stage}});
endif
.

@verb __MMEDIA__:"play music show insert" this none this rxd
@program __MMEDIA__:play
{who, file, ?ackid = random($maxint), @args} = args;
sort = "file";
if ((caller != this) && (!$perm_utils:controls(caller_perms(), who)))
  return E_PERM;
elseif ((!valid(session = $mcp:session_for(who))) || (!session:handles_package(this)))
  return E_INVARG;
elseif (this:knows_alias(who, file))
  sort = "alias";
elseif (((idx = rindex(file, ".")) && (!this:accepts_type(who, verb, file[idx + 1..$]))) || ((idx = index(file, "://")) && (!this:accepts_protocol(who, file[1..idx - 1]))))
  return E_TYPE;
endif
this:(verb + "_info")(session.connection, {ackid, {"", 0}});
this:("send_" + verb)(session, {"ack-id", ackid}, {sort, file}, @args);
return 1;
.

@verb __MMEDIA__:"stop_play stop_music stop_show stop_insert" this none this rxd
@program __MMEDIA__:stop_play
who = args[1];
what = verb[6..$];
prop = what + "_info";
if (!$perm_utils:controls(caller_perms(), who))
  return E_PERM;
elseif ((!valid(session = $mcp:session_for(who))) || (!session:handles_package(this)))
  return E_INVARG;
elseif (idx = $list_utils:iassoc(who, this.(prop)))
  {ackid, status} = this.(prop)[idx][2];
  if (status[1] == "failed")
    ackid = "*";
  endif
  this.(prop) = listdelete(this.(prop), idx);
else
  ackid = "*";
endif
this:("send_" + what)(session, {"stop", ackid});
return 1;
.

@verb __MMEDIA__:"initialize_connection" this none this rxd
@program __MMEDIA__:initialize_connection
"Usage:  :initialize_connection()";
"";
{version} = args;
connection = caller;
if (parent(connection) != $mcp.session)
  return;
endif
messages = $list_utils:slice(this.messages_in);
connection:register_handlers(messages);
this:send_base(connection);
.

@verb __MMEDIA__:"handle_ack-stage" this none this rxd
@program __MMEDIA__:handle_ack-stage
{session, id, type, stage} = args;
if (caller != this)
  return E_PERM;
endif
this:(type + "_info")(session.connection, {id, {"stage", toint(stage)}});
.

@verb __MMEDIA__:"handle_ack-done" this none this rxd
@program __MMEDIA__:handle_ack-done
{session, id, method, stage, reason} = args;
who = session.connection;
if (caller != this)
  return E_PERM;
endif
if (method == "preload")
  if ((idx = $list_utils:iassoc(who, this.alias_info)) && (idx2 = $list_utils:iassoc(id, this.alias_info[idx], 2)))
    if (!(this.alias_info[idx][2] = listdelete(this.alias_info[idx][2], idx2)))
      this.alias_info = listdelete(this.alias_info, idx);
    endif
  endif
else
  prop = method + "_info";
  if (idx = $list_utils:iassoc(who, this.(prop)))
    this.(prop) = listdelete(this.(prop), idx);
  endif
endif
.

@verb __MMEDIA__:"preload" this none this rxd
@program __MMEDIA__:preload
{who, file, alias, ?ackid = random($maxint), @args} = args;
if ((caller != this) && (!$perm_utils:controls(caller_perms(), who)))
  return E_PERM;
elseif ((!valid(session = $mcp:session_for(who))) || (!session:handles_package(this)))
  return E_INVARG;
elseif (this:knows_alias(who, alias))
  return "Alias already in use";
elseif (((idx = rindex(file, ".")) && ((((!this:accepts_type(who, "show", file[idx + 1..$])) && (!this:accepts_type(who, "play", file[idx + 1..$]))) && (!this:accepts_type(who, "music", file[idx + 1..$]))) && (!this:accepts_type(who, "insert", file[idx + 1..$])))) || ((idx = index(file, "://")) && (!this:accepts_protocol(who, file[1..idx - 1]))))
  return E_TYPE;
endif
this:alias_info(who, {{alias, ackid}});
this:send_preload(session, {"ack-id", ackid}, {"file", file}, {"as", alias}, @args);
return 1;
.

@verb __MMEDIA__:"methods" this none this rxd
@program __MMEDIA__:methods
who = args[1];
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
elseif ((!(info = $list_utils:assoc(who, this.accept_info))) || (!(methods = this:match_arg("methods", info[2]))))
  return E_INVARG;
endif
return $string_utils:explode($string_utils:strip_chars(methods, " "), ",");
.

@verb __MMEDIA__:"stop_preload" this none this rxd
@program __MMEDIA__:stop_preload
{who, ?alias = ""} = args;
if (!$perm_utils:controls(caller_perms(), who))
  return E_PERM;
elseif ((!valid(session = $mcp:session_for(who))) || (!session:handles_package(this)))
  return E_INVARG;
endif
idx = $list_utils:iassoc(who, this.alias_info);
if (alias && idx)
  if (idx2 = $list_utils:iassoc(alias, this.alias_info[idx][2]))
    ackid = this.alias_info[idx][2][idx2][2];
    if (!(this.alias_info[idx][2] = listdelete(this.alias_info[idx][2], idx2)))
      this.alias_info = listdelete(this.alias_info, idx);
    endif
  else
    return E_VARNF;
  endif
else
  if (idx)
    this.alias_info = listdelete(this.alias_info, idx);
  endif
  ackid = "*";
endif
this:send_preload(session, {"stop", ackid});
return 1;
.

@verb __MMEDIA__:"knows_alias" this none this rxd
@program __MMEDIA__:knows_alias
{who, alias} = args;
if (!$perm_utils:controls(caller_perms(), this))
  return E_PERM;
endif
return (info = $list_utils:assoc(who, this.alias_info)) && ($list_utils:iassoc(alias, info[2]) != 0);
.

"***finished***

