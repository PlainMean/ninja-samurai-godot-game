-- Independent verifier: reopens disk artifacts and never loads the generator.
local log={ 'Aseprite '..tostring(app.version)..' — independent saved-artifact verification' }
local function pass(s) log[#log+1]='PASS: '..s end
local function open(path)
  local s=app.open(path); assert(s,'Cannot open '..path); return s
end
local function render(s,f)
  local image=Image(s.width,s.height,ColorMode.RGB)
  image:drawSprite(s,f,Point(0,0))
  return image
end
local function same(a,b)
  if app.pixelColor.rgbaA(a)==0 and app.pixelColor.rgbaA(b)==0 then return true end
  return a==b
end
local source=open('samurai_attack.aseprite')
assert(source.width==32 and source.height==32,'Source dimensions')
assert(#source.frames==6,'Source frame count')
assert(source.colorMode==ColorMode.RGB,'RGBA source expected')
assert(#source.layers==3,'Expected three editable layers')
for _,l in ipairs(source.layers) do assert(not l.isBackground,'Background layer must be transparent') end
pass('source is 32x32 RGBA, 6 real timeline frames, 3 editable transparent layers')
local attack
for _,t in ipairs(source.tags) do if t.name=='attack' then attack=t end end
assert(attack and attack.fromFrame.frameNumber==1 and attack.toFrame.frameNumber==6,'attack tag range')
assert(attack.aniDir==AniDir.FORWARD,'attack tag direction')
pass('attack tag spans frames 1–6, forward playback')
local frames={}
for f=1,6 do
  assert(math.abs(source.frames[f].duration-0.100)<0.000001,'Source timing '..f)
  frames[f]=render(source,f)
  local opaque,transparent,hash=0,0,0
  for y=0,31 do for x=0,31 do
    local v=frames[f]:getPixel(x,y)
    local a=app.pixelColor.rgbaA(v)
    assert(a==0 or a==255,'Unexpected antialias alpha')
    if a==0 then transparent=transparent+1 else opaque=opaque+1 end
    hash=(hash*65599+v)%2147483647
  end end
  assert(opaque>0 and transparent>0,'Frame must contain art and transparency')
  pass(string.format('frame %d: 100 ms, %d opaque / %d transparent pixels, checksum %d',f,opaque,transparent,hash))
end
local comparisons=0
for a=1,5 do for b=a+1,6 do
  local distinct=false
  for y=0,31 do for x=0,31 do
    if not same(frames[a]:getPixel(x,y),frames[b]:getPixel(x,y)) then distinct=true end
  end end
  assert(distinct,'Duplicate frames '..a..' and '..b)
  comparisons=comparisons+1
end end
pass('all 6 frames distinct: '..comparisons..' exhaustive pairwise pixel comparisons')
local sheet=open('samurai_attack_sheet.png')
assert(sheet.width==192 and sheet.height==32 and #sheet.frames==1,'Horizontal sheet dimensions')
local strip=render(sheet,1)
for f=1,6 do for y=0,31 do for x=0,31 do
  assert(same(frames[f]:getPixel(x,y),strip:getPixel((f-1)*32+x,y)),'Sheet pixel mismatch')
end end end
pass('native horizontal PNG is 192x32 and exactly matches all six source frames')
local gif=open('samurai_attack.gif')
assert(gif.width==32 and gif.height==32 and #gif.frames==6,'GIF dimensions/count')
for f=1,6 do
  assert(math.abs(gif.frames[f].duration-0.100)<0.000001,'GIF timing')
  local g=render(gif,f)
  for y=0,31 do for x=0,31 do
    assert(same(frames[f]:getPixel(x,y),g:getPixel(x,y)),'GIF pixel mismatch at frame '..f)
  end end
end
pass('GIF is 32x32, 6 frames at 100 ms; all colors/transparency exactly match source')
local preview=open('samurai_attack_sheet_4x.png')
assert(preview.width==768 and preview.height==128 and #preview.frames==1,'Preview dimensions')
local scaled=render(preview,1)
for y=0,127 do for x=0,767 do
  assert(same(scaled:getPixel(x,y),strip:getPixel(math.floor(x/4),math.floor(y/4))),'Preview is not exact nearest-neighbor')
end end
pass('4x preview is 768x128; all 98,304 pixels verify exact nearest-neighbor scaling')
pass('ALL CHECKS PASSED')
local report=assert(io.open('verification.txt','w'))
report:write(table.concat(log,'\n')..'\n'); report:close()
print(table.concat(log,'\n'))
