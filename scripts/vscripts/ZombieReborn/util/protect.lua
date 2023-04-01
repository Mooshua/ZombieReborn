
--  protect: cooler pcall
--  Error handling and protection
--  
--  Prints information about locals, upvalues, and a stack traceback when an error occurs.
--  Usage: Protect(function, args...) -> ...
--  Returns a tuple. First arg is "success" (boolean), rest are return values.

--  Example:
--  local success, return_1, return_2, ... return_n = Protect(function, args...)
--  if success then
--      ...
--  end

local MAX_LOCALS = 250
local MAX_UPVALS = 250

return function(f, ...)

    local args = { ... }

    local result = { xpcall(
        -- try
        function()
            return f( unpack(args) )
        end,

        -- catch
        function(text)

            --  get erroring function info
            local info = debug.getinfo(2)

            print("error:", text)

            --  print all local variables and their names
            print("locals:")
            for i = 1, MAX_LOCALS do
                local name, value = debug.getlocal(2, i)
        
                if name == nil then break end
                -- re-enable if we don't want to see temporary values
                --if name == "(*temporary)" then break end
        
                print(string.format("\t[%s] (%s) %s", name, type(value), value ))
            end

            --  print all upvalues. probably going to be mostly noise, comment out if unhelpful.
            print("upvalues:")
            for i = 1, MAX_UPVALS do
                local name, value = debug.getupvalue(info.func, i)

                if name == nil then break end

                print(string.format("\t[%s] (%s) %s", name, type(value), value ))
            end

            --  and now a good old fashioned traceback.
            print(debug.traceback("", 2))
        end
    ) }

    return unpack(result)

end