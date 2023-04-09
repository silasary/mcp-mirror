"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-rehash:dns-com-awns-rehash
@prop __NEW__."handler" __REH__ rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"getcommands", {}}})
;__NEW__:set_messages_out({{"commands", {"list"}}, {"add", {"list"}}, {"remove", {"list"}}})

@verb __NEW__:"send_commands" this none this
@program __NEW__:send_commands
return pass(@args);
.

@verb __NEW__:"send_add" this none this
@program __NEW__:send_add
return pass(@args);
.

@verb __NEW__:"send_remove" this none this
@program __NEW__:send_remove
return pass(@args);
.

@verb __NEW__:"handle_getcommands" this none this
@program __NEW__:handle_getcommands
{session} = args;
this.handler:rehash(session.connection, 1);
.
