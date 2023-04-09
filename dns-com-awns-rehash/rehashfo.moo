@create $feature named Rehash Feature Object (rfo):Rehash Feature Object (rfo),rfo
@prop __RFO__."handler" __REH__ rc

@verb __RFO__:"feature_add" this none this
@program __RFO__:feature_add
who = args[1];
"called from $player:add_feature, which runs as $hacker";
if (caller_perms() == $hacker)
  "this may need wizperms if $player:add_handler gets perms checks";
  who:add_handler(this.handler);
else
  return E_PERM;
endif
.

@verb __RFO__:"feature_remove" this none this
@program __RFO__:feature_remove
"called from $player:remove_feature, which runs as $hacker";
who = args[1];
if (caller_perms() == $hacker)
  this.handler:remove_self_from(who);
else
  return E_PERM;
endif
.

@verb __RFO__:"@rehash @rehash!" none none none rxd
@program __RFO__:@rehash
full = verb == "@rehash!";
this.handler:rehash(player, full);
.

@verb __RFO__:"@which" any none none rxd
@program __RFO__:@which
{command} = args;
environment = {player, @player.contents, player.location, @player.location.contents, @player.location:obvious_exits(player), $nothing};
visited = {};
for object in (environment)
  oo = object;
  while (valid(oo))
    if (oo in visited)
      continue;
    endif
    if (psn = oo in this.handler.rehash_visited)
      "we need to expand stuff like l*ook to l, lo, loo, look";
      if (command in this:expand(this.handler.rehash_verbs[psn]))
        player:tell(oo:dnamec(), " (", oo, ") :", command, (oo == object) ? "" | ((((" through " + object:dnamec()) + " (") + tostr(object)) + ")"));
        return;
      endif
    endif
    oo = parent(oo);
  endwhile
endfor
player:tell("Can't find any object supporting the command '", command, "'.");
.

@verb __RFO__:"expand" this none this
@program __RFO__:expand
{l} = args;
expanded = {};
for string in (l)
  if (star = index(string, "*"))
    s = string[1..star - 1];
    rest = $string_utils:explode(string[star + 1..$], "");
    expanded = {@expanded, s};
    for character in (rest)
      s = s + character;
      expanded = {@expanded, s};
    endfor
  else
    expanded = {@expanded, string};
  endif
endfor
return expanded;
.
