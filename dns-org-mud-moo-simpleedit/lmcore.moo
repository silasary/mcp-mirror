@program $generic_editor:invoke_local_editor
"$generic_editor:invoke_local_editor(name, text, upload, reference, type)";
"Spits out the magic text that invokes the local editor in the player's client.";
"NAME is a good human-readable name for the local editor to use for this particular piece of text.";
"TEXT is a string or list of strings, the initial body of the text being edited.";
"UPLOAD, a string, is a MOO command that the local editor can use to save the text when the user is done editing.  The local editor is going to send that command on a line by itself, followed by the new text lines, followed by a line containing only `.'.  The UPLOAD command should therefore call $command_utils:read_lines() to get the new text as a list of strings.";
"REFERENCE is a string representing the MCP/2.1 reference (usually <obj>.<prop> or <obj>:<verb>) for clients who speak MCP/2.1 simpleedit.";
"TYPE is a string representing the MCP/2.1 type (moo-code, string...) for clients who speak MCP/2.1 simpleedit.";
if (caller != this)
  return;
endif
{name, text, upload, reference, type} = args;
if (typeof(text) == STR)
  text = {text};
endif
session = $mcp:session_for(player);
package = $mcp:match_package("dns-org-mud-moo-simpleedit");
if (session:handles_package(package) == {1, 0})
  package:send_content(session, reference, name, type, text);
  return;
endif
notify(player, tostr("#$# edit name: ", name, " upload: ", upload));
":dump_lines() takes care of the final `.' ...";
for line in ($command_utils:dump_lines(text))
  notify(player, line);
endfor
.


@program $mail_editor:local_editing_info
lines = {"To:       " + (toline = $mail_agent:name_list(@args[1])), "Subject:  " + $string_utils:trim(subject = args[2])};
if (args[3])
  lines = {@lines, "Reply-to: " + $mail_agent:name_list(@args[3])};
endif
lines = {@lines, "", @args[4]};
return {tostr("MOOMail", subject ? ("(" + subject) + ")" | (("-to(" + toline) + ")")), lines, "@@sendmail", "sendmail", "string-list"};
.


@program $note_editor:local_editing_info
{what, text} = args;
cmd = (typeof(text) == STR) ? "@set-note-string" | "@set-note-text";
name = (typeof(what) == OBJ) ? what.name | tostr(what[1].name, ".", what[2]);
note = (typeof(what) == OBJ) ? what | tostr(what[1], ".", what[2]);
ref = tostr("str:", (typeof(what) == OBJ) ? tostr(what,".text") | tostr(what[1],".", what[2]));
return {name, text, tostr(cmd, " ", note), ref, "string-list"};
.


@program $verb_editor:local_editing_info
if (caller == $verb_editor)
  set_task_perms(player);
endif
{object, vname, code} = args;
if (typeof(vname) == LIST)
  vargs = tostr(" ", vname[2], " ", $code_utils:short_prep(vname[3]), " ", vname[4]);
  vname = vname[1];
else
  vargs = "";
endif
name = tostr(object.name, ":", vname);
ref = tostr(object, ":", vname);
"... so the next 2 lines are actually wrong, since verb_info won't";
"... necessarily retrieve the correct verb if we have more than one";
"... matching the given same name; anyway, if parse_invoke understood vname,";
"... so will @program.  I suspect these were put here because in the";
"... old scheme of things, vname was always a number.";
"vname = strsub($string_utils:explode(verb_info(object, vname)[3])[1], \"*\", \"\")";
"vargs = verb_args(object, vname)";
"";
return {name, code, tostr("@program ", object, ":", vname, vargs), ref, "moo-code"};
.
