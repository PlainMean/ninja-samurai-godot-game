-- Read-only Aseprite-native sanity gate; independent binary verifier is in game/tests.
local src=assert(app.params['src'])
local names={'water','fire','earth','wind'}
for _,name in ipairs(names) do
 local s=app.open(app.fs.joinPath(src,name..'.aseprite'))
 assert(s.width==48 and s.height==48 and #s.frames==4 and #s.layers==1)
 assert(#s.tags==1 and s.tags[1].name=='sword' and s.tags[1].fromFrame.frameNumber==1 and s.tags[1].toFrame.frameNumber==4)
 local sheet=Image{fromFile=app.fs.joinPath(src,name..'_sheet.png')}
 assert(sheet.width==192 and sheet.height==48)
 for f=1,4 do
  assert(math.abs(s.frames[f].duration-0.1)<0.00001)
  local im=s.cels[f].image;local count=0
  for y=0,47 do for x=0,47 do
   assert(im:getPixel(x,y)==sheet:getPixel((f-1)*48+x,y))
   if app.pixelColor.rgbaA(im:getPixel(x,y))>0 then count=count+1 end
  end end
  assert(count>200)
 end
 s:close()
end
print('PASS Aseprite reopened four swords: four source/export poses, sword tag, 100ms timing')
