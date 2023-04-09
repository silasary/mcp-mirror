"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-displayurl:dns-com-awns-displayurl
@prop __NEW__."trusted" {} rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_out({{"", {"url"}}})

@verb __NEW__:"send_" this none this
@program __NEW__:send_
"you probably want a ton of security here";
if (this:trusts(caller))
  return pass(@args);
else
  raise(E_PERM);
endif
.

@verb __NEW__:"trusts" this none this
@program __NEW__:trusts
{what} = args;
if (this.trusted)
  if (what in this.trusted)
    return 1;
  else
    return 0;
  endif
endif
return 1;
.
