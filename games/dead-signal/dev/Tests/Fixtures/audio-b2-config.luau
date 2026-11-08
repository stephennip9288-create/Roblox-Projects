-- Keep immutable Batch1 comparisons exact; Batch2 is independently exercised.
local fs=require('@lune/fs')
return {original=function(source)
    local block=fs.readFile('Reviews/audio-atmosphere-b2/CONFIG-POLICY.luau.txt')
    local first,last=string.find(source,block,1,true)
    if not first then return source end
    assert(not string.find(source,block,last+1,true),'Duplicate Batch2 policy')
    return string.sub(source,1,first-1)..string.sub(source,last+1)
end}
