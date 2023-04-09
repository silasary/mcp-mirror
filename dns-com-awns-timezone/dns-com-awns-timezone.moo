"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-timezone:dns-com-awns-timezone
@prop __NEW__."records" {} rc
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"", {"timezone"}}})

@verb __NEW__:"handle_" this none this
@program __NEW__:handle_
{session, timezone} = args;
if (psn = $list_utils:iassoc(session.connection, this.records))
  this.records[psn][2] = time();
  this.records[psn][3] = timezone;
else
  record = {session.connection, time(), timezone};
  this.records = {@this.records, record};
endif
.

@verb __NEW__:"get_timezone" this none this
@program __NEW__:get_timezone
{who} = args;
"return the timezone last recorded by this package for 'who', or UCT if no information is available";
if (record = $list_utils:assoc(who, this.records))
  return record[3];
else
  return "UCT";
endif
.
