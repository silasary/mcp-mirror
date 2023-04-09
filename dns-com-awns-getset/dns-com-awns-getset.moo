"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-getset:dns-com-awns-getset
@prop __NEW__."users" {} rc
@prop __NEW__."data" {} rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"get", {"id", "property"}}, {"set", {"id", "property", "value"}}, {"drop", {"id", "property"}}})
;__NEW__:set_messages_out({{"ack", {"id"}}})

@verb __NEW__:"handle_get" this none this
@program __NEW__:handle_get
{session, id, property} = args;
if (psn = player in this.users)
  "we've heard of this player";
  if (i = $list_utils:iassoc(property, this.data[psn]))
    "we've heard of this property";
    this:send_ack(session, id, @{{"value", this.data[psn][i][2]}});
  endif
endif
.

@verb __NEW__:"handle_set" this none this
@program __NEW__:handle_set
{session, id, property, value} = args;
if (psn = player in this.users)
  "we've heard of this player";
  if (i = $list_utils:iassoc(property, this.data[psn]))
    "we've heard of this property";
    this.data[psn][i] = {property, value};
  else
    "we've NOT heard of this property";
    this.data[psn] = {@this.data[psn], {property, value}};
  endif
else
  "we've NOT heard of this player";
  this.users = {@this.users, player};
  this.data = {@this.data, {{property, value}}};
endif
.

@verb __NEW__:"handle_drop" this none this
@program __NEW__:handle_drop
{session, id, property} = args;
player:tell("handle_drop");
.

@verb dns-com-awns-getset:"send_ack" this none this
@program dns-com-awns-getset:send_ack
return pass(@args);
.


