local IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and arg[2] == "debug"
if IS_DEBUG then
	require("lldebugger").start()

	function love.errorhandler(msg)
		error(msg, 2)
	end
end


function love.conf(t)
    t.window.width = 1080
    t.window.height = 1080

    t.window.msaa = 16
    t.window.vsync = 0
end