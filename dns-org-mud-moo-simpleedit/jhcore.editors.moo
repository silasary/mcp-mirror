" $verb_editor:local_editing_info contains references to
" player:verbcode_internal_to_external.  This verb converts between
" regular moo ' "comments"; ' and JHCore ' // Comments ' formats.
" You can either copy the same verb from the dns-org-mud-moo-simpleedit
" package to Generic Programmer, or you can delete the line containing
" :verbcode_internal_to_external.

" COPIES

@copy $generic_editor:invoke to $generic_editor:invoke(old)
@copy $generic_editor:invoke_local_editor to $generic_editor:invoke_local_editor(old)

@copy $note_editor:parse_invoke to $note_editor:parse_invoke(old)
@copy $note_editor:local_editing_info to $note_editor:local_editing_info(old)

@copy $verb_editor:parse_invoke to $verb_editor:parse_invoke(old)
@copy $verb_editor:local_editing_info to $verb_editor:local_editing_info(old)

@copy $mail_editor:parse_invoke to $mail_editor:parse_invoke(old)
@copy $mail_editor:local_editing_info to $mail_editor:local_editing_info(old)

" PROGRAMMING

@program $generic_editor:invoke
{new, @rest} = args;
":invoke(...)";
"to find out what arguments this verb expects,";
"see this editor's parse_invoke verb.";
if ((!(caller in {this, player})) && (!$perm_utils:controls(caller_perms(), player)))
  "...non-editor/non-player verb trying to send someone to the editor...";
  return E_PERM;
endif
if ((who = this:loaded(player)) && this:changed(who))
  if (!new)
    if (this:suck_in(player))
      player:tell("You are working on ", this:working_on(who));
    endif
    return;
  elseif (player.location == this)
    player:tell("You are still working on ", this:working_on(who));
    if (msg = this:previous_session_msg())
      player:tell(msg);
    endif
    return;
  endif
  "... we're not in the editor and we're about to start something new,";
  "... but there's still this pending session...";
  working = this:working_on(who);
  if (typeof(working) == STR)
    player:tell("You were working on ", this:working_on(who));
    if (!$command_utils:yes_or_no("Do you wish to delete that session?"))
      if (this:suck_in(player))
        player:tell("Continuing with ", this:working_on(player in this.active));
        if (msg = this:previous_session_msg())
          player:tell(msg);
        endif
      endif
      return;
    endif
    "... note session number may have changed => don't trust `who'";
    this:kill_session(player in this.active);
  endif
endif
spec = this:parse_invoke(new, @rest);
if (typeof(spec) == LIST)
  if ((player:edit_option("local") && $object_utils:has_verb(this, "local_editing_info")) && (info = this:local_editing_info(@spec)))
    this:invoke_local_editor(@info);
  elseif (this:suck_in(player))
    this:init_session(player in this.active, @spec);
  endif
endif
.

@program $generic_editor:invoke_local_editor
":invoke_local_editor(type, name, text, upload)";
"Spits out the magic text that invokes the local editor in the player's client.";
"TYPE is the type of data--program, text, mail, value, etc.";
"NAME is a good human-readable name for the local editor to use for this particular piece of text.";
"TEXT is a string or list of strings, the initial body of the text being edited.";
"UPLOAD, a string, is a MOO command that the local editor can use to save the text when the user is done editing.  The local editor is going to send that command on a line by itself, followed by the new text lines, followed by a line containing only `.'.  The UPLOAD command should therefore call $command_utils:read_lines() to get the new text as a list of strings.";
if (caller != this)
  return;
endif
type = args[1];
name = args[2];
text = args[3];
upload = args[4];
if (typeof(text) == STR)
  text = {text};
endif
package = $mcp:match_package("dns-org-mud-moo-simpleedit");
session = $mcp:session_for(player);
if (session:handles_package(package))
  mcp_info = args[5];
  package:send_content(session, @mcp_info);
elseif (use_mcp = player:client_option("mcp_edit"))
  "mcp version 1.0 editing";
  res = player:client_notify("edit", {{"type", type}, {"name", name}, {"upload", upload}}, text);
  return res;
else
  notify(player, tostr("#$# edit name: ", name, " upload: ", upload));
  ":dump_lines() takes care of the final `.' ...";
  for line in ($command_utils:dump_lines(text))
    notify(player, line);
  endfor
endif
.

@program $note_editor:parse_invoke
":parse_invoke(string,verb)";
" string is the actual commandline string indicating what we are to edit";
" verb is the command verb that is attempting to invoke the editor";
if (!(string = args[1]))
  player:tell_lines({("Usage:  " + args[2]) + " <note>              (where <note> is some note object)", ("        " + args[2]) + " <object>.<property> (edits an arbitrary property)", ("        " + args[2]) + "                     (continues editing an unsaved note)"});
elseif (1 == (note = this:note_match_failed(string)))
elseif (ERR == typeof(text = this:note_text(note)))
  player:tell("Couldn't retrieve text:  ", text);
else
  return {note, text};
endif
return 0;
.

@program $note_editor:local_editing_info
{what,text}=args;
if (typeof(text) == STR)
  cmd = "@set-note-string";
  type = "string";
  vtyp = "str";
elseif ($list_utils:check_type(text, STR))
  cmd = "@set-note-text";
  type = "string-list";
  vtyp = "str";
else
  cmd = "@set-note-value";
  text = this:explode_list(0, text);
  type = "string-list";
  vtyp = "val";
endif
name = (typeof(what) == OBJ) ? what.name | tostr(what[1].name, ".", what[2]);
note = (typeof(what) == OBJ) ? what | tostr(what[1], ".", what[2]);
text = (typeof(text) == STR) ? {text} | text;
info = {"text", name, text, tostr(cmd, " ", note)};
mcp_info = {(vtyp + ":") + note, name, type, text};
return {@info, mcp_info};
.

@program $verb_editor:parse_invoke
":parse_invoke(string,v)";
"  string is the commandline string to parse to obtain the obj:verb to edit";
"  v is the actual command verb used to invoke the editor";
" => {object, verbname, verb_code} or error";
vref = $string_utils:words(args[1]);
v = args[2];
bynumber = v[$] == "#";
if ((!vref) || (!(spec = $code_utils:parse_verbref(vref[1]))))
  player:tell("Usage: ", v, " object:verb");
  return;
endif
if (argspec = listdelete(vref, 1))
  if (bynumber)
    player:tell("Don't use args with ", v, ".");
    return;
  elseif (typeof(pas = $code_utils:parse_argspec(@argspec)) == LIST)
    if (pas[2])
      player:tell("Don't know what to do with \"", $string_utils:from_list(pas[2], " "), "\"");
      return;
    endif
    argspec = pas[1][1..3];
    argspec[2] = $code_utils:full_prep(argspec[2]) || argspec[2];
  else
    player:tell(pas);
    return;
  endif
endif
if ($command_utils:object_match_failed(object = player:my_match_object(spec[1], this:get_room(player)), spec[1]))
  return 0;
elseif (bynumber)
  if (!$string_utils:is_numeric(spec[2]))
    player:tell("Must use verb number with ", v, ".");
    return;
  endif
  vnum = toint(spec[2]);
  if (vnum < 1)
    player:tell("Verb number must be positive.");
    return;
  endif
  code = `this:fetch_verb_code(object, vnum) ! ANY';
  if (typeof(code) == ERR)
    if (code == E_VERBNF)
      player:tell("That object does not define that many verbs.");
    else
      player:tell(code);
    endif
    return code;
  endif
  return {object, vnum, code, object};
else
  code = E_VERBNF;
  definer = object;
  while (valid(definer))
    vnum = 0;
    while ((vnum = $code_utils:find_verb_named_1_based(definer, spec[2], vnum + 1)) && (argspec && `verb_args(definer, vnum) != argspec ! E_PERM => 1'))
    endwhile
    if (vnum)
      code = `this:fetch_verb_code(definer, vnum) ! ANY';
      "FOR NOW...";
      "vname = tostr(vnum - 1);";
      break;
    endif
    definer = parent(definer);
  endwhile
  if (typeof(code) == ERR)
    player:tell((code != E_VERBNF) ? code | "That object does not define that verb", argspec ? " with those arguments." | ".");
    return code;
  elseif ((definer != object) && (!player:edit_option("local")))
    player:tell("That object does not define that verb", argspec ? " with those arguments" | "", ".  You may want to edit the verb on its ancestor, ", definer:iname(), " (", definer, ").");
    return E_INVARG;
  else
    if (definer != object)
      code = {tostr(object:dnamec(), " (", object, ") does not define a :", spec[2], " verb", argspec ? " with those arguments" | "", ".  The following code is from its ancestor, ", definer:iname(), " (", definer, ")."), @code};
    endif
    "return {object, vname, code, definer};";
    return {object, vnum, code, definer};
  endif
endif
.

@program $verb_editor:local_editing_info
{object, vname, code, definer} = args;
if (caller != $verb_editor)
  raise(E_PERM);
endif
set_task_perms(player);
if (typeof(vname) == LIST)
  vargs = tostr(" ", vname[2], " ", $code_utils:short_prep(vname[3]), " ", vname[4]);
  vname = vname[1];
else
  vargs = "";
endif
"... so the next 2 lines are actually wrong, since verb_info won't";
"... necessarily retrieve the correct verb if we have more than one";
"... matching the given same name; anyway, if parse_invoke understood vname,";
"... so will @program.  I suspect these were put here because in the";
"... old scheme of things, vname was always a number.";
if ((typeof(vname) == NUM) || $string_utils:is_numeric(vname))
  vargs = verb_args(definer, vname);
  if (!(vargs[2] in {"none", "any"}))
    vargs[2] = $code_utils:short_prep(vargs[2]);
  endif
  vargs = tostr(" ", vargs[1], " ", vargs[2], " ", vargs[3]);
  vname = strsub((vnames = $string_utils:explode(verb_info(definer, vname)[3]))[1], "*", "");
  "(but i LIKE having a name instead of a number.)";
endif
name = tostr(object.name, ":", vname);
"";
if ((vargs == " this none this") && ((!player:list_option("args_assignment")) && (named = $code_utils:named_args_from_code(code))))
  split = $code_utils:split_verb_code(code);
  split[2][1..length(named[1]) + (named[2] ? 1 | 0)] = {};
  code = $list_utils:flatten(split);
  code = player:verbcode_internal_to_external(code);
  reference = tostr(object, ":", vname, " (", $code_utils:named_args_list(named), ")");
else
  code = player:verbcode_internal_to_external(code);
  reference = tostr(object, ":", vname, vargs);
endif
info = {"program", name, code, tostr("@program ", reference)};
"reference, name, type, content";
mcp_info = {reference, "MOO verb: " + reference, "moo-code", code};
return {@info, mcp_info};
.

@program $mail_editor:parse_invoke
"invoke(rcptstrings,verb[,subject]) for a @send";
"invoke(1,verb,rcpts,subject,replyto,body) if no parsing is needed";
"invoke(2,verb,msg,flags,replytos) for an @answer";
if (!(which = args[1]))
  player:tell_lines({tostr("Usage:  ", args[2], " <list-of-recipients>"), tostr("        ", args[2], "                      to continue with a previous draft")});
elseif (typeof(which) == LIST)
  "...@send...";
  if (rcpts = this:parse_recipients({}, which))
    if (replyto = player:mail_option("replyto"))
      replyto = this:parse_recipients({}, replyto, ".mail_options: ");
    endif
    if (0 == (subject = {@args, 0}[3]))
      if (player:mail_option("nosubject"))
        subject = "";
      else
        player:tell("Subject:");
        subject = $command_utils:read();
      endif
    endif
    return {rcpts, subject, replyto, {}};
  endif
elseif (which == 1)
  return args[3..6];
elseif (!(to_subj = this:parse_msg_headers(msg = args[3], flags = args[4])))
else
  include = {};
  if ("include" in flags)
    prefix = ">            ";
    for line in ($mail_agent:to_text(@msg))
      if (!line)
        prefix = ">  ";
      endif
      include = {@include, @this:fill_string(">  " + line, 70, prefix)};
    endfor
  endif
  return {@to_subj, args[5], include};
endif
return 0;
.

@program $mail_editor:local_editing_info
lines = {"To:       " + (toline = $mail_agent:nn_list(@args[1])), "Subject:  " + $string_utils:trim(subject = args[2])};
if (args[3])
  lines = {@lines, "Reply-to: " + $mail_agent:nn_list(@args[3])};
endif
lines = {@lines, "", @args[4]};
info = {"mail", tostr("MOOMail", subject ? ("(" + $string_utils:print(subject)) + ")" | (("-to(" + $string_utils:print(toline)) + ")")), lines, "@@sendmail"};
"reference, name, type, content";
mcp_info = {"sendmail", info[2], "string-list", info[3]};
return {@info, mcp_info};
.
