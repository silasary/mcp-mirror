"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-status:dns-com-awns-status
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_out({{"", {"text"}}})

@verb __NEW__:"status" this none this
@program __NEW__:status
{session, text} = args;
if ((caller == this) || $perm_utils:controls(caller_perms(), session.connection))
  return this:send_(session, text);
endif
.
