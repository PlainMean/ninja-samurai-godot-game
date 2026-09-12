-- Raster authorship: Aseprite Sprite/Image APIs only. Facing right; runtime mirrors.
-- Four attack poses: ready, wind-up, extension, recovery. Native transparent 48x48.
local out=assert(app.params['out'])
app.fs.makeAllDirectories(out)
local units={
 {'cinder_rival','ba453a','f5b65d','652934'},
 {'ash_monk','b76b42','f8d28b','673b42'},
 {'ash_shogun','953c47','ffd077','422c49'},
 {'gate_guard','327ea4','9bdfef','254761'},
 {'twin_cut_retainer','526cb1','b4d5ff','303758'},
 {'moonlit_master','408e9c','dbf7f1','2c526e'},
 {'earth_sentinel','8e7947','d9c48b','49482d'},
 {'iron_vanguard','777d79','ded2aa','434a4d'},
 {'mountain_regent','9d684a','f0c28c','543c38'},
 {'gale_assassin','76988b','e3f5cf','314b50'},
 {'coast_ronin','657f9e','f4ead0','363e60'},
 {'tempest_sovereign','8977ad','ffffff','47405f'}
}
local function rgb(hex) return app.pixelColor.rgba(tonumber(hex:sub(1,2),16),tonumber(hex:sub(3,4),16),tonumber(hex:sub(5,6),16),255) end
for n,u in ipairs(units) do
 local s=Sprite(48,48,ColorMode.RGB); s.layers[1].name=u[1]..' silhouette and weapon'
 local p={rgb('171d30'),rgb(u[2]),rgb(u[3]),rgb(u[4]),rgb('d8aa83'),rgb('eef0da')}
 for f=1,4 do
  if f>1 then s:newFrame() end
  s.frames[f].duration=0.1
  local im=Image(48,48,ColorMode.RGB)
  local dx=({0,-1,2,1})[f]; local dy=({0,-1,1,0})[f]
  local function dot(x,y,c) x=math.floor(x); y=math.floor(y); if x>=0 and x<48 and y>=0 and y<48 then im:drawPixel(x,y,p[c]) end end
  local function rect(x,y,w,h,c) for yy=y,y+h-1 do for xx=x,x+w-1 do dot(xx,yy,c) end end end
  local function poly(v,c)
   for y=0,47 do for x=0,47 do
    local inside=false; local j=#v
    for i=1,#v do
     local a,b=v[i],v[j]
     if (a[2]>y)~=(b[2]>y) and x<(b[1]-a[1])*(y-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
     j=i
    end
    if inside then dot(x,y,c) end
   end end
  end
  local function line(x,y,xx,yy,c,w)
   local steps=math.max(math.abs(xx-x),math.abs(yy-y))
   for k=0,steps do rect(math.floor(x+(xx-x)*k/math.max(1,steps)),math.floor(y+(yy-y)*k/math.max(1,steps)),w or 1,w or 1,c) end
  end
  local function head(x,y,w,h,mask)
   rect(x-1,y-1,w+2,h+2,1);rect(x,y,w,h,5)
   rect(x,y,w,3,4); if mask then rect(x,y+5,w,3,2) end
   rect(x+w-3,y+3,2,1,6)
  end
  local function boots(left,right)
   rect(left,36,5,7,1);rect(right,35,5,8,1);rect(left,41,7,3,4);rect(right,41,7,3,4)
  end
  local function blade(x,y,xx,yy)
   line(x-1,y,xx,yy,1,3);line(x,y,xx,yy,6,1);rect(x-2,y,5,2,3)
  end
  -- Each branch deliberately authors its own silhouette rather than recoloring a base.
  if n==1 then -- slim sleeveless duelist, high tied hair, single extended saber
   boots(17,28);poly({{17+dx,19},{26+dx,18},{30,36},{16,37}},1)
   poly({{18+dx,20},{25+dx,20},{28,34},{17,35}},2)
   head(19+dx,10+dy,7,8,false);rect(16+dx,6+dy,5,6,4)
   line(18+dx,23,13,30,5,3);line(25+dx,22,30+f,25,5,3)
   blade(31+f,25,({38,28,45,40})[f],({10,3,23,13})[f]);rect(17,29,11,2,3)
  elseif n==2 then -- bald monk, bead collar, bell sleeves and planted staff
   boots(17,25);poly({{17,19+dy},{28,19+dy},{34,40},{12,40}},1)
   poly({{18,20+dy},{27,20+dy},{31,38},{15,38}},2)
   head(19+dx,10+dy,8,8,false);rect(19+dx,10+dy,8,3,5)
   poly({{18,21},{11,23},{8,32},{18,29}},4);poly({{26,21},{34,22+f},{35,31+f},{26,28}},3)
   for k=0,4 do rect(17+k*3,20+math.min(k,4-k),2,2,3) end
   line(36-f,6,36+f,43,4,2);rect(34-f,6,6,2,3)
  elseif n==3 then -- fire boss: huge horned helm, layered tassets, cleaver
   boots(13,28);poly({{11,20},{32,20},{36,37},{9,37}},1);rect(12,22,20,12,2)
   for y=27,36,4 do rect(10,y,25,2,3) end
   head(18,11+dy,10,9,true);rect(14,9+dy,18,5,4)
   poly({{14,12},{7,4},{9,15},{16,18}},3);poly({{28,12},{35,3},{33,16},{28,18}},3)
   rect(8,20,9,7,4);rect(29,20,8,7,4)
   local x=35+dx;line(x,21,x+3,40,4,2);poly({{x,19},{x+4,7+f*2},{x+9,9+f*2},{x+5,27}},6)
  elseif n==4 then -- tall water spear guard, plumed conical helm, narrow tabard
   boots(18,26);rect(17,20,14,18,1);rect(19,21,10,16,2);rect(22,22,4,17,3)
   head(20,12+dy,8,8,true);poly({{16,13+dy},{24,5+dy},{32,13+dy}},4);rect(23,2+dy,3,5,3)
   line(18,22,13,31,2,4);line(29,23,35,24+f,2,3)
   line(37-dx,9,37+dx,44,4,2);poly({{35-dx,10},{38-dx,1},{41-dx,10},{38-dx,13}},3)
  elseif n==5 then -- dual blade retainer, divided coat, side swept hair
   boots(14,28);poly({{16,20},{28,20},{34,38},{25,39},{22,30},{19,39},{10,37}},1)
   poly({{17,21},{27,21},{31,36},{26,37},{22,28},{17,36},{13,35}},2)
   head(19+dx,11,8,8,true);poly({{17+dx,12},{19+dx,6},{30+dx,8},{27+dx,13}},4)
   line(17,22,10,25+f,3,3);line(28,22,33,29-f,3,3)
   blade(10,25+f,4+f,10);blade(34,29-f,44,17+f*3);rect(18,27,11,2,3)
  elseif n==6 then -- water master: round moon halo, flowing robe, fan
   boots(17,26)
   for a=0,60 do local q=a*math.pi/30;rect(math.floor(23+12*math.cos(q)),math.floor(16+12*math.sin(q)),2,2,3) end
   poly({{18,19},{29,19},{36,42},{10,42}},1);poly({{19,20},{28,20},{33,40},{13,40}},2)
   poly({{20,20},{24,26},{28,20},{27,39},{20,39}},3);head(20,10+dy,8,9,false);rect(18,8+dy,11,3,6)
   line(28,24,34,26+f,2,3);poly({{34,28+f},{31,14+f},{39,12+f},{46,19+f}},3)
   for k=0,2 do line(34,28+f,33+k*5,15+f+k,4,1) end
  elseif n==7 then -- shield sentinel: broad kite shield and compact helmet
   boots(17,28);rect(16,21,16,17,1);rect(18,22,12,14,2);head(21,11+dy,9,9,true)
   rect(19,9+dy,13,5,4);rect(23,10+dy,3,10,3)
   poly({{7+dx,20},{20+dx,18},{24+dx,32},{15+dx,41},{6+dx,31}},1)
   poly({{9+dx,22},{19+dx,20},{22+dx,31},{15+dx,38},{8+dx,30}},2)
   line(15+dx,22,15+dx,35,3,2);line(10+dx,27,20+dx,27,3,2)
   blade(33,30,39+f,15+f)
  elseif n==8 then -- iron vanguard: square plate suit, two-handed hammer
   boots(13,28);rect(10,20,26,18,1);rect(13,21,20,15,2)
   for k=0,2 do rect(14,24+k*4,18,1,3) end
   head(18,10+dy,12,10,true);rect(17,8+dy,14,6,2);rect(20,14+dy,9,2,1)
   rect(8,20,8,8,4);rect(30,20,8,8,4)
   line(22,29,37-dx,12+f,4,3);rect(31-dx,7+f,13,9,1);rect(32-dx,8+f,11,6,3)
  elseif n==9 then -- mountain boss: jagged stone crown, massive shoulders, slab axe
   boots(11,29);poly({{7,19},{34,19},{38,39},{6,39}},1);poly({{10,21},{32,21},{35,37},{9,37}},2)
   poly({{8,18},{13,13},{19,21},{12,27}},4);poly({{27,20},{33,13},{39,21},{33,28}},4)
   head(18,10+dy,12,10,true)
   poly({{16,12},{15,4},{21,8},{24,2},{27,8},{33,4},{31,13}},3)
   rect(19,23,10,4,3);rect(17,31,15,3,4)
   line(38,19,36,44,4,3);poly({{37,18},{37,7+f},{45,10+f},{47,21+f},{41,25}},3)
  elseif n==10 then -- assassin: hooded crouch, long scarf, reverse sickle
   boots(12,29);poly({{17+dx,20+dy},{27+dx,19+dy},{34,35},{27,38},{21,29},{14,39},{9,35}},1)
   poly({{18+dx,21+dy},{26+dx,20+dy},{31,34},{28,35},{22,27},{13,35}},2)
   head(20+dx,12+dy,8,8,true);poly({{17+dx,17+dy},{19+dx,8+dy},{27+dx,7+dy},{31+dx,15+dy},{25+dx,11+dy}},4)
   poly({{19,21},{8,17-f},{2,20-f},{8,22-f},{18,24}},3)
   line(27,23,36,30-f,2,3);line(35,27-f,43,32-f,4,2);line(43,32-f,44,22-f,6,2);line(44,22-f,39,20-f,6,2)
  elseif n==11 then -- coastal ronin: enormous straw hat, ragged poncho, low sword
   boots(16,28);poly({{16,20},{29,20},{35,33},{30,35},{27,32},{22,36},{17,33},{10,35}},1)
   poly({{17,21},{28,21},{32,32},{26,30},{22,33},{16,31},{13,32}},2)
   head(20,12+dy,8,8,false);poly({{9,14+dy},{23,5+dy},{37,14+dy},{36,17+dy},{9,17+dy}},4)
   line(10,14+dy,35,14+dy,3,2);line(23,6+dy,18,13+dy,3,1)
   line(28,24,33,31,5,3);blade(33,32,45,30-f*3)
  else -- tempest boss: winged mantle, crown and forked storm glaive
   boots(17,27);poly({{17,20},{29,20},{37,41},{10,41}},1);poly({{19,20},{27,20},{33,39},{14,39}},2)
   poly({{18,22},{4,12+f},{7,25},{3,29},{16,32}},4);poly({{29,22},{40,12+f},{39,26},{44,30},{31,33}},4)
   line(6,17+f,16,26,3,2);line(38,18+f,32,27,3,2)
   head(19,10+dy,10,10,true);poly({{17,11},{15,3},{21,7},{24,1},{27,7},{32,3},{30,12}},3)
   rect(21,22,5,15,3);line(39-dx,7,39+dx,44,3,2)
   line(35-dx,3,35-dx,10,6,1);line(43-dx,3,43-dx,10,6,1);line(35-dx,10,43-dx,10,6,1)
  end
  s.cels[f].image=im
 end
 local tag=s:newTag(1,4);tag.name='attack'
 s:saveAs(app.fs.joinPath(out,u[1]..'.aseprite'));app.sprite=s
 app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename=app.fs.joinPath(out,u[1]..'_sheet.png'),dataFilename=app.fs.joinPath(out,u[1]..'.json'),dataFormat=SpriteSheetDataFormat.JSON_ARRAY,listLayers=true,listTags=true,trimSprite=false,trim=false}
 s:close()
end
print('PASS Aseprite authored 12 individual unit silhouettes / 48 attack poses')
