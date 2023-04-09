"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-serverinfo:dns-com-awns-serverinfo
@prop __NEW__."home_url" "" rc
@prop __NEW__."help_url" "" rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"get", {}}})
;__NEW__:set_messages_out({{"", {"home_url", "help_url"}}})

@verb __NEW__:"handle_get" this none this
@program __NEW__:handle_get
{session} = args;
this:send_(session, this.home_url, this.help_url);
.

@verb __NEW__:"send_" this none this
@program __NEW__:send_
if ($perm_utils:controls(caller_perms(), this))
  return pass(@args);
else
  raise(E_PERM);
endif
.
