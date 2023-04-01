local Util = {}

-- Apparently entity indices take up the first 14 bits of an EHandle, need more testing to really verify this
function Util.EHandleToHScript(iPawnId)
    return EntIndexToHScript(bit.band(iPawnId, 0x3FFF))
end

--Dump the contents of a table
function Util.dump(tbl)
    for k, v in pairs(tbl) do
        print(k, v)
    end
end

-- shuffles positions of elements in an array
-- usable only for array type of tables (when keys are not strings)
function Util.shuffle(tbl)
    for i = #tbl, 2, -1 do
        local j = math.random(i)
        tbl[i], tbl[j] = tbl[j], tbl[i]
    end
    return tbl
end

-- removes all instances of a given value
-- from a given table
function Util.removeValue(tbl, value)
    for i = #tbl, 1, -1 do
        if tbl[i] == value then
            table.remove(tbl, i)
        end
    end
end

return Util