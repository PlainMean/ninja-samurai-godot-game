-- Independent read-only source/export audit inside Aseprite.
local dir=app.params['out'] or '.'
local specs={
 {'ninja_support',32,32,{'Scarf','Body','Blade'},{{'idle',400,400},{'guard',100,100},{'dodge',100,100,100},{'hurt',100,100},{'defeat',100,100,200}},'090c17 111727 1d283c 2e3f53 445667 b72036 ef3e47 68162b d5a47d f8ce9b 9db8c6 e4f7f7 567a94'},
 {'samurai_support',32,32,{'Armor','Arms and blade','Cloth'},{{'idle',400,400},{'warn_cut',100},{'warn_heavy',100},{'hurt',100,100},{'defeat',100,100,200}},'151625 23253e 353b60 505c80 7485a0 572c40 914758 be6b70 766044 b89a61 e0c887 c29880 ebc6a0 6d8397 b7cbd3 edf2df 7fabb8 c5ded9'},
 {'dojo_backdrops',195,128,{'Sky or wall','Architecture','Floor'},{{'gate',100},{'courtyard',100},{'dojo',100}}},
 {'dojo_props',16,32,{'Fixture','Light or emblem'},{{'lantern',300,300},{'banner_gate',100},{'banner_retainer',100},{'banner_master',100}}},
 {'combat_fx',32,32,{'Core','Accents'},{{'block',60,60,100},{'dodge',80,80,80},{'hit',60,60,100},{'seal',100,100,200}}},
 {'dojo_icons',16,16,{'Outline','Fill'},{{'heart_full',100},{'heart_empty',100},{'seal_empty',100},{'seal_full',100},{'cut',100},{'heavy',100},{'double_cut',100},{'mend',100},{'long_breath',100},{'iron_resolve',100}}}
}
local report={'Aseprite '..tostring(app.version),'Command: aseprite --batch --script-param out=<archive> --script verify_moonlit_dojo.lua'}
local checks=0
local function check(ok,msg) checks=checks+1;assert(ok,msg) end
for _,sp in ipairs(specs) do
 local name,w,h,ls,tags=table.unpack(sp)
 local s=app.open(app.fs.joinPath(dir,name..'.aseprite'))
 local sheet=Image{fromFile=app.fs.joinPath(dir,name..'_sheet.png')}
 local file=assert(io.open(app.fs.joinPath(dir,name..'.json')));local meta=json.decode(file:read('*a'));file:close()
 check(s.width==w and s.height==h and s.colorMode==ColorMode.RGB,name..' canvas')
 check(#s.layers==#ls,name..' layer count');for i,l in ipairs(ls) do check(s.layers[i].name==l,name..' layer') end
 local allowed={};for hex in (sp[6] or '151625 23253e 353b60 505c80 7485a0 572c40 914758 766044 b89a61 e0c887 b7cbd3 edf2df 7fabb8 493b45 9aaeb2'):gmatch('%x+') do allowed[tonumber(hex,16)]=true end
 local f=0;local previous={}
 check(#s.tags==#tags and #meta.meta.frameTags==#tags,name..' tags')
 for ti,t in ipairs(tags) do
  local first=f
  for k=2,#t do
   f=f+1
   check(math.abs(s.frames[f].duration*1000-t[k])<0.001,name..' duration')
   local r=meta.frames[f];check(r.duration==t[k] and r.frame.x==(f-1)*w and r.frame.y==0 and r.frame.w==w and r.frame.h==h and not r.trimmed and not r.rotated,name..' JSON frame')
   local flat=Image(w,h,ColorMode.RGB);flat:drawSprite(s,f)
   local signature={};local sole=false
   for y=0,h-1 do for x=0,w-1 do
    local p=flat:getPixel(x,y);local q=sheet:getPixel((f-1)*w+x,y);local a=app.pixelColor.rgbaA(p)
    check(a==0 or a==255,name..' binary alpha')
    check((a==0 and app.pixelColor.rgbaA(q)==0) or p==q,name..' flattened equality')
    if a>0 then
     local rgb=app.pixelColor.rgbaR(p)*65536+app.pixelColor.rgbaG(p)*256+app.pixelColor.rgbaB(p)
     check(allowed[rgb],name..' palette')
     if name=='ninja_support' or name=='samurai_support' then check(y<30,name..' bottom clearance');if y==29 then sole=true end end
    end
    if name=='dojo_backdrops' then check(a==255,name..' opaque scenery') end
    signature[#signature+1]=tostring(a==0 and 0 or p)
   end end
   if name=='ninja_support' or name=='samurai_support' then check(sole,name..' planted sole') end
   local key=table.concat(signature,',');check(not previous[key],name..' distinct frame');previous[key]=true
  end
  local st=s.tags[ti];local jt=meta.meta.frameTags[ti]
  check(st.name==t[1] and st.fromFrame.frameNumber==first+1 and st.toFrame.frameNumber==f and st.aniDir==AniDir.FORWARD,name..' source tag')
  check(jt.name==t[1] and jt.from==first and jt.to==f-1 and jt.direction=='forward',name..' JSON tag')
 end
 check(#s.frames==f and #meta.frames==f and sheet.width==w*f and sheet.height==h,name..' strip')
 report[#report+1]='PASS '..name..': '..f..' distinct frames; layers, tags, durations, palette, alpha, source/sheet equality'
 s:close()
end
report[#report+1]='PASS '..checks..' assertions'
local f=assert(io.open(app.fs.joinPath(dir,'verification.txt'),'w'));f:write(table.concat(report,'\n')..'\n');f:close();print(table.concat(report,'\n'))
