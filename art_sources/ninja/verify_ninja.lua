-- Independently reopen deliverables; never uses the drawing script.
local out={}
local function report(t) out[#out+1]=t; print(t) end
local s=app.open('ninja_attack.aseprite')
assert(s and s.width==32 and s.height==32,'Source dimensions')
assert(#s.frames==6,'Source frame count')
assert(#s.layers==4,'Editable layers')
local attack
for _,t in ipairs(s.tags) do if t.name=='attack' then attack=t end end
assert(attack and attack.fromFrame.frameNumber==1 and attack.toFrame.frameNumber==6,'Attack tag range')
report('PASS: source 32x32, 6 frames, 4 editable layers, attack tag frames 1-6')
local previous={}
for i,f in ipairs(s.frames) do
 assert(math.abs(f.duration-.1)<.00001,'Frame duration')
 local im=Image(32,32,ColorMode.RGB)
 im:drawSprite(s,i)
 local count=0; local transparent=0; local signature={}
 for y=0,31 do for x=0,31 do
  local p=im:getPixel(x,y)
  if app.pixelColor.rgbaA(p)>0 then count=count+1 else transparent=transparent+1 end
  signature[#signature+1]=tostring(p)
 end end
 assert(count>0 and transparent>0,'Frame must contain art and transparency')
 local key=table.concat(signature,','); assert(not previous[key],'Duplicate frame'); previous[key]=true
 report(string.format('PASS: frame %d, 100ms, %d visible pixels, %d transparent pixels, unique pose',i,count,transparent))
end
local sheet=app.open('ninja_attack_sheet.png')
assert(sheet and sheet.width==192 and sheet.height==32,'Sheet dimensions')
report('PASS: PNG sheet 192x32, native-resolution six-cell horizontal strip')
local gif=app.open('ninja_attack.gif')
assert(gif and gif.width==32 and gif.height==32 and #gif.frames==6,'GIF dimensions/frame count')
for _,f in ipairs(gif.frames) do assert(math.abs(f.duration-.1)<.00001,'GIF duration') end
report('PASS: GIF 32x32, 6 frames, all 100ms')
local file=assert(io.open('verification.txt','w')); file:write(table.concat(out,'\n')..'\n'); file:close()
