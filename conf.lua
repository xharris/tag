io.stdout:setvbuf('no')


love.filesystem.setRequirePath( "?.lua;?/init.lua;lua/?.lua;lua/?/init.lua;lua/?.dll" )
require("blanke")
      
function love.conf(t)
    t.console = true
    
    t.identity = "blanke.tag"
    t.window.title = "tag"
    -- t.gammacorrect = nil

end
