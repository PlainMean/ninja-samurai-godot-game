-- All rasterization is performed with Aseprite Image:drawPixel.
local s = Sprite(32,32,ColorMode.RGB)
s.filename = 'ninja_attack.aseprite'
local C = {
 ink={9,12,23}, deep={17,23,39}, navy={29,40,60}, light={46,63,83},
 edge={68,86,103}, red={183,32,54}, scarlet={239,62,71}, wine={104,22,43},
 skin={213,164,125}, skinlight={248,206,155}, steel={157,184,198},
 white={228,247,247}, blue={86,122,148}, arc={164,218,228,210}
}
for k,v in pairs(C) do C[k]=app.pixelColor.rgba(v[1],v[2],v[3],v[4] or 255) end
local img
local function px(x,y,c)
 x=math.floor(x); y=math.floor(y)
 if x>=0 and x<32 and y>=0 and y<32 then img:drawPixel(x,y,C[c]) end
end
local function rect(x,y,w,h,c)
 for yy=y,y+h-1 do for xx=x,x+w-1 do px(xx,yy,c) end end
end
local function line(x0,y0,x1,y1,c,r)
 local n=math.max(math.abs(x1-x0),math.abs(y1-y0))
 for i=0,n do
  local t=n==0 and 0 or i/n
  local x=math.floor(x0+(x1-x0)*t+.5)
  local y=math.floor(y0+(y1-y0)*t+.5)
  rect(x-(r or 0),y-(r or 0),1+2*(r or 0),1+2*(r or 0),c)
 end
end
local function poly(p,c)
 for y=0,31 do for x=0,31 do
  local inside=false
  local j=#p
  for i=1,#p do
   local a,b=p[i],p[j]
   if (a[2]>y+.5)~=(b[2]>y+.5) and x+.5<(b[1]-a[1])*(y+.5-a[2])/(b[2]-a[2])+a[1] then inside=not inside end
   j=i
  end
  if inside then px(x,y,c) end
 end end
end
local layers={}
s.layers[1].name='Scarf'
layers[1]=s.layers[1]
for _,name in ipairs({'Ninja','Steel blade','Slash accents'}) do local l=s:newLayer(); l.name=name; layers[#layers+1]=l end
for i=2,6 do s:newEmptyFrame() end
-- Head origin, front elbow, hand, blade tip, rear foot, forward foot.
local poses={
 {11,7,19,18,22,16,28,7,9,22},
 {10,8,15,15,13,9,21,1,8,21},
 {13,8,22,16,24,14,30,6,7,25},
 {14,9,23,18,25,18,31,17,7,26},
 {13,10,21,20,23,23,28,30,8,25},
 {11,8,19,19,21,18,28,11,9,23}
}
for f,p in ipairs(poses) do
 s.frames[f].duration=.100
 local hx,hy,ex,ey,gx,gy,tx,ty,back,front=table.unpack(p)
 local bx,by=hx+2,hy+10
 for li,l in ipairs(layers) do
  img=Image(32,32,ColorMode.RGB); img:clear()
  if li==1 then
   local lift=({0,-2,-3,-2,0,1})[f]
   poly({{hx+2,hy+9},{hx-2,hy+7},{3,hy+5+lift},{5,hy+9+lift},{1,hy+11+lift},{hx-1,hy+11}},'wine')
   poly({{hx+1,hy+9},{hx-3,hy+8},{3,hy+5+lift},{6,hy+8+lift},{4,hy+9+lift},{hx-1,hy+10}},'red')
   line(5,hy+7+lift,hx-1,hy+9,'scarlet')
  elseif li==2 then
   -- Two bent legs and planted tabi boots.
   line(bx,by+4,back+2,25,'ink',2); line(back+2,25,back,28,'ink',2)
   line(bx,by+4,back+2,25,'navy',1); line(back+2,25,back,28,'deep',1)
   line(bx+2,by+4,front-2,24,'ink',2); line(front-2,24,front,28,'ink',2)
   line(bx+2,by+4,front-2,24,'light',1); line(front-2,24,front,28,'navy',1)
   rect(back-2,28,6,2,'ink'); rect(front-2,28,7,2,'ink')
   line(front-1,28,front+3,28,'light'); line(back-1,28,back+1,28,'navy')
   poly({{hx,hy+8},{hx+6,hy+8},{bx+5,by+5},{bx-3,by+6},{hx-2,hy+13}},'ink')
   poly({{hx+1,hy+9},{hx+5,hy+9},{bx+3,by+3},{bx-2,by+4},{hx-1,hy+13}},'navy')
   line(hx+2,hy+10,bx+1,by+2,'light')
   line(hx,hy+11,hx-2,hy+15,'ink',1); line(hx-2,hy+15,hx+2,hy+17,'ink',1)
   line(hx,hy+11,hx-2,hy+15,'light'); line(hx-2,hy+15,hx+2,hy+17,'navy')
   line(bx-2,by+3,bx+4,by+3,'ink'); line(bx-1,by+4,bx+3,by+4,'wine')
   -- Hood, eye slit, and face mask: facing right.
   poly({{hx+1,hy-1},{hx+6,hy-1},{hx+8,hy+2},{hx+8,hy+7},{hx+5,hy+9},{hx,hy+8},{hx-2,hy+5},{hx-2,hy+2}},'ink')
   poly({{hx+1,hy},{hx+5,hy},{hx+7,hy+2},{hx+7,hy+6},{hx+4,hy+8},{hx,hy+7},{hx-1,hy+4}},'navy')
   line(hx+1,hy,hx+4,hy,'light'); line(hx-1,hy+2,hx-1,hy+4,'light')
   rect(hx+3,hy+3,5,2,'skin'); line(hx+4,hy+3,hx+7,hy+3,'skinlight')
   px(hx+6,hy+3,'ink'); px(hx+7,hy+3,'white')
   rect(hx+2,hy+5,6,2,'deep'); line(hx+3,hy+5,hx+6,hy+5,'light')
   line(hx,hy+8,hx+5,hy+8,'red'); line(hx+1,hy+8,hx+3,hy+8,'scarlet')
   line(hx+5,hy+11,ex,ey,'ink',2); line(ex,ey,gx,gy,'ink',1)
   line(hx+5,hy+11,ex,ey,'light',1); line(ex,ey,gx,gy,'navy')
   rect(gx-1,gy-1,3,3,'ink'); rect(gx,gy-1,2,2,'edge')
  elseif li==3 then
   local dx,dy=tx-gx,ty-gy
   local n=math.sqrt(dx*dx+dy*dy); local ux,uy=dx/n,dy/n
   local sx,sy=math.floor(gx+ux*3+.5),math.floor(gy+uy*3+.5)
   line(gx,gy,sx,sy,'ink',1); line(gx,gy,sx,sy,'wine')
   line(sx-uy*2,sy+ux*2,sx+uy*2,sy-ux*2,'steel')
   local ax,ay=sx+ux,sy+uy
   line(ax,ay,tx,ty,'blue',1)
   line(ax,ay,tx,ty,'steel'); line(ax-uy,ay+ux,tx,ty,'white')
  elseif li==4 then
   if f==3 then
    line(20,2,25,3,'blue'); line(25,3,29,6,'arc'); line(29,6,31,10,'white')
    line(23,5,26,6,'arc')
   elseif f==4 then
    line(29,7,31,11,'blue'); line(31,12,31,16,'arc')
    line(27,10,29,13,'arc'); px(30,21,'white'); px(28,22,'blue')
   elseif f==5 then
    line(31,21,30,25,'arc'); line(30,25,27,28,'blue'); px(29,19,'white')
   end
  end
  s:newCel(l,f,img,Point(0,0))
 end
end
local tag=s:newTag(1,6); tag.name='attack'; tag.aniDir=AniDir.FORWARD
s:saveAs('ninja_attack.aseprite')
app.command.ExportSpriteSheet{ui=false,type=SpriteSheetType.HORIZONTAL,textureFilename='ninja_attack_sheet.png',splitLayers=false,splitTags=false,listLayers=false,listTags=false,listSlices=false,trimSprite=false,trim=false,extrude=false,padding=0}
s:saveCopyAs('ninja_attack.gif')
print('Created ninja_attack.aseprite, ninja_attack_sheet.png, ninja_attack.gif')
