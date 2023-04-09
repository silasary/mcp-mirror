"__PACKAGE__ is the objectid of the generic MCP package
"__NEW__ is the object id of the new object resulting from the @create command
"__REGISTRY__ is the value of $mcp.registry
"To add the package, become a wizard and type:
"    @add-package __NEW__ to __REGISTRY__

@create __PACKAGE__ named dns-com-awns-jtext:dns-com-awns-jtext
;__NEW__:set_version_range({"1.0", "1.0"})
;__NEW__:set_messages_in({{"pick", {"type", "args"}}})

@verb __NEW__:"handle_pick" none none none rxd
@program __NEW__:handle_pick
{session, type, the_args} = args;
the_list = this:make_list(the_args);
if (rv = $mcp.parser:parse_mcp_alist(@the_list))
  try
    player:receive_document({$jaddress.(type), rv[2]});
  except (ANY)
    player:tell("That information is not available.");
  endtry
endif
.

@verb __NEW__:"make_list" this none this
@program __NEW__:make_list
{string} = args;
the_list = {};
keyword = "";
for word in ($string_utils:words(string))
  if (word[$] == ":")
    if (keyword)
      value = $string_utils:trim(value);
      the_list = {@the_list, keyword, value};
      keyword = "";
    endif
    keyword = word;
    value = "";
  else
    value = (value + " ") + word;
  endif
endfor
if (keyword)
  value = $string_utils:trim(value);
  the_list = {@the_list, keyword, value};
endif
return the_list;
.
