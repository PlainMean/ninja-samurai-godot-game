-- Raster authorship exclusively via Aseprite Sprite/Image APIs.
local out=assert(app.params['out']); app.fs.makeAllDirectories(out)
local palettes={water={'122e57','225dba','359ceb','91e6ff','d5f8ff'},fire={'501b2e','ad3026','ef5726','ffac38','ffe59a'},earth={'302329','644331','99643e','c28b54','e3bf82'},wind={'303949','737f96','bdcad8','e3ecf4','ffffff'}}
for _,name in ipairs({'water','fire','earth','wind'}) do
 local s=Sprite(48,48,ColorMode.RGB); s.layers[1].name=name..' blade, grip and animated glint'
 local p={};local pal=Palette(6);pal:setColor(0,Color{r=0,g=0,b=0,a=0})
 for i,h in ipairs(palettes[name]) do p[i]=app.pixelColor.rgba(tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16),255);pal:setColor(i,Color(p[i])) end
 s:setPalette(pal)
 for f=1,4 do
  if f>1 then s:newFrame() end;s.frames[f].duration=.1
  local im=Image(48,48,ColorMode.RGB)
  local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do if xx>=0 and xx<48 and yy>=0 and yy<48 then im:drawPixel(xx,yy,p[c]) end end end end
  local function poly(points,c)
   for y=0,47 do for x=0,47 do local inside=false;local j=#points
    for i,a in ipairs(points) do local b=points[j];if (a[2]>y+.5)~=(b[2]>y+.5) and x+.5<(b[1]-a[1])*(y+.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end;j=i end
    if inside then rect(x,y,1,1,c) end
   end end
  end
  -- Grip anchor is (24,39); blade points up. Element-specific silhouettes.
  rect(21,34,6,11,1);rect(23,34,2,9,2);rect(22,43,4,3,4)
  for y=35,41,3 do rect(22,y,4,1,4) end
  if name=='water' then
   poly({{19,33},{15,26},{15,19},{19,12},{29,3},{34,2},{28,9},{25,17},{26,23},{31,27},{28,33}},1)
   poly({{20,32},{17,25},{17,19},{21,12},{32,4},{26,14},{23,19},{24,25},{29,28},{27,32}},3)
   poly({{17,24},{18,18},{22,12},{32,4},{25,14},{21,20},{21,27}},4)
   poly({{20,30},{20,23},{23,18},{23,26},{27,29}},2)
   poly({{15,31},{21,32},{27,32},{32,30},{31,34},{24,36},{17,35}},1)
   rect(18,33,12,1,4)
  elseif name=='fire' then
   poly({{19,33},{13,25},{18,27},{16,18},{21,21},{20,12},{26,2},{27,13},{32,9},{30,20},{35,17},{31,28},{27,34}},1)
   poly({{21,33},{16,27},{21,29},{19,20},{23,24},{22,13},{26,5},{25,19},{30,13},{27,25},{32,21},{28,31}},3)
   poly({{23,32},{21,27},{24,22},{24,15},{26,10},{26,26},{29,24},{26,32}},4)
   poly({{15,32},{20,33},{27,33},{33,30},{31,35},{24,37},{17,35}},2)
  elseif name=='earth' then
   poly({{17,32},{12,12},{17,5},{30,5},{35,11},{30,32}},1)
   poly({{19,31},{15,13},{18,8},{29,8},{32,12},{28,31}},3)
   poly({{15,13},{18,8},{29,8},{32,12},{26,13},{24,29},{21,29},{21,13}},4)
   poly({{17,16},{22,18},{20,23},{25,26},{24,28},{18,24},{20,20}},2)
   rect(13,31,22,5,1);rect(15,32,18,2,3);rect(21,32,6,3,5)
  else
   poly({{21,33},{17,27},{20,23},{17,22},{21,17},{19,16},{25,3},{28,7},{30,15},{27,21},{30,20},{27,27},{25,33}},1)
   poly({{22,32},{19,27},{23,22},{20,22},{24,16},{22,16},{26,6},{28,14},{25,22},{28,22},{25,29}},4)
   poly({{23,30},{23,19},{26,7},{26,23},{24,32}},5)
   poly({{12,29},{20,31},{24,33},{30,30},{36,28},{32,34},{24,36},{16,34}},3)
   rect(20,33,8,1,5)
  end
  -- Traveling specular glint, four unique nonempty frames at 100ms.
  rect(23,10+f*4,2,2,5);rect(22,11+f*4,4,1,5)
  s.cels[f].image=im
 end
 local tag=s:newTag(1,4);tag.name='sword'
 s:saveAs(out..'/'..name..'.aseprite');app.sprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=out..'/'..name..'_sheet.png',dataFilename=out..'/'..name..'.json',dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false}
 s:close()
end
print('PASS generated four elemental swords, sixteen 48x48 frames at 100ms')
