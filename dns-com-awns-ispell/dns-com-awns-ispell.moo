"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-ispell:dns-com-awns-ispell
@prop __NEW__."id" 212 rc
@prop __NEW__."callbacks" {} rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"reply", {"id", "word", "str"}}})
;__NEW__:set_messages_out({{"", {"id", "word"}}})

@verb __NEW__:"send_" this none this
@program __NEW__:send_
return pass(@args);
.

@verb __NEW__:"handle_reply" this none this
@program __NEW__:handle_reply
{session, id, word, line} = args;
if (i = $list_utils:iassoc(id, this.callbacks))
  {the_id, o, v, arglist} = this.callbacks[i];
  this.callbacks = listdelete(this.callbacks, i);
  `o:(v)(word, line, @arglist) ! ANY => 1';
endif
.

@verb __NEW__:"_new_id" this none this
@program __NEW__:_new_id
this.id = this.id + 1;
return tostr(this.id);
.

@verb __NEW__:"spell" this none this
@program __NEW__:spell
{word, o, v, @rest} = args;
"right now there's only Networker, but perhaps others can provide the same service, in whihc case this would be a lookup for service-providing clients";
session = $mcp:session_for(this.owner);
if (valid(session) && session:handles_package(this))
  id = this:_new_id();
  record = {id, o, v, rest};
  this.callbacks = {@this.callbacks, record};
  this:send_(session, id, word);
  return 1;
else
  return 0;
endif
.
