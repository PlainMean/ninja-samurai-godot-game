-- Original journey illustrations. All pixel authorship/export uses Aseprite APIs.
local out=app.params['out']
app.fs.makeAllDirectories(out)
local colors={bg={21,25,43},stone={57,64,83},edge={99,115,133},gold={231,184,104},light={246,227,173},blue={91,170,184},red={158,68,83}}
for k,v in pairs(colors) do colors[k]=app.pixelColor.rgba(v[1],v[2],v[3],255) end
for _,name in ipairs({'route','shrine','reveal'}) do
 local s=Sprite(160,96,ColorMode.RGB)
 s.layers[1].name='Moonlit architecture'
 for f=1,3 do
  if f>1 then s:newFrame() end
  s.frames[f].duration=0.3
  local img=Image(160,96,ColorMode.RGB)
  local function rect(x,y,w,h,c)
   for yy=y,y+h-1 do for xx=x,x+w-1 do
    if xx>=0 and xx<160 and yy>=0 and yy<96 then img:drawPixel(xx,yy,colors[c]) end
   end end
  end
  rect(0,0,160,96,'bg')
  for y=0,15 do for x=0,15 do if (x-7)^2+(y-7)^2<56 then rect(125+x,8+y,1,1,'light') end end end
  for i=1,15 do rect((i*37)%156, (i*19)%41,1,1,'edge') end
  rect(0,83,160,13,'stone')
  if name=='route' then
   for i=0,2 do
    local x=12+i*54; local y=60-i*17
    rect(x,y,30,5,'edge');rect(x+4,y-24,3,24,'red');rect(x+23,y-24,3,24,'red')
    rect(x-2,y-27,34,4,'gold');rect(x+1,y-31,28,3,'stone')
    if i<2 then for j=0,5 do rect(x+29+j*4,y-j*3,4,2,'blue') end end
    rect(x+12,y-14,7,7,i<f and 'gold' or 'stone')
   end
  else
   rect(31,76,98,7,'edge');rect(39,68,82,8,'stone')
   rect(48,34,5,34,'red');rect(107,34,5,34,'red')
   rect(39,28,82,6,'gold');rect(45,22,70,6,'stone')
   rect(53,17,54,5,'edge');rect(62,12,36,5,'stone')
   if name=='shrine' then
    rect(64,55,32,13,'edge');rect(70,48,20,7,'gold')
    for i=0,2 do rect(73+i*6,39-((f+i)%3)*3,2,6,'light') end
   else
    rect(57,35,46,33,'bg')
    for i=0,2 do rect(62+i*13,44,9,9,'gold');rect(65+i*13,47,3,3,'light') end
    rect(74,57,12,9,'blue');rect(77,54,6,3,'light')
    for i=0,4 do rect(58+i*10,36+(i+f)%3,2,2,'light') end
   end
  end
  s.cels[f].image=img
 end
 local tag=s:newTag(1,3);tag.name='glow'
 s:saveAs(app.fs.joinPath(out,name..'.aseprite'))
 app.sprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=app.fs.joinPath(out,name..'_sheet.png'),dataFilename=app.fs.joinPath(out,name..'.json'),dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false}
 s:close()
end
