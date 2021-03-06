#! /usr/bin/env texlua

-- '?' は 'Pro' 等に置換される（今のところ sc では不使用）
local foundry = {
   ['noEmbed']   = {
      mr='!STSong-Light',
      gr='!STHeiti-Regular',
      {'n'},
   },
   ['adobe']   = {
      noncid = false,
      mr='AdobeSongStd-Light.otf',
      gr='AdobeHeitiStd-Regular.otf',
      {''},
   },
   ['arphic']   = {  -- gr がサンセリフになっていない
      noncid = true,
      mr='gbsn00lp.ttf %!PS BousungEG-Light-GB',
      gr='gkai00mp.ttf %!PS GBZenKai-Medium',
      {''},
   },
   ['cjkunifonts']   = {  -- gr がサンセリフになっていない
      noncid = true,
      mr=':0:uming.ttc %!PS UMingCN',
      gr=':0:ukai.ttc %!PS UKaiCN',
      {''},
   },
   ['cjkunifonts-ttf']   = {  -- gr がサンセリフになっていない
      noncid = true,
      mr='uming.ttf %!PS ShanHeiSun-Uni',  -- (-Adobe-GB1)
      gr='ukai.ttf %!PS ZenKai-Uni',       -- (-Adobe-GB1)
      {''},
   },
   ['fandol']   = {
      noncid = false,
      mr='FandolSong-Regular.otf',
      gr='FandolHei-Regular.otf',
      {''},
   },
   ['founder']   = {
      noncid = true,
      mr='FZSSK.TTF %!PS FZSSK--GBK1-0',
      gr='FZHTK.TTF %!PS FZHTK--GBK1-0',
      {''},
   },
   ['ms']   = {
      noncid = true,
      mr=':0:simsun.ttc %!PS SimSun',
      gr='simhei.ttf %!PS SimHei',
      {''},
   },
   ['ms-osx']   = {
      noncid = true,
      mr='simsun.ttf %!PS SimSun',
      gr='simhei.ttf %!PS SimHei',
      {''},
   },
--   ['sinotype']   = { -- Adobe-GB1 cmap unavailable
--      noncid = true,
--      mr='STSong.ttf',
--      gr='STHeiti.ttf',
--      {''},
--   },
}

local suffix = {
   -- { '?' 置換, scEmbed 接尾辞, (ttc index mov)}
   ['']   = {'', ''},          -- 非 CID フォント用ダミー
   ['n']  = {'!', ''},         -- 非埋め込みに使用
   ['4']  = {'Pro', ''},
   ['6']  = {'Pr6', '-pr6'},
}

-- '#' は 'h', 'v' に置換される
-- '@' は scEmbed の値に置換される
local maps = {
   ['uptex-sc-@'] = {
      {'upstsl-#', 'UniGB-UTF16-#', 'mr'},
      {'upstht-#', 'UniGB-UTF16-#', 'gr'},
   },
   ['otf-sc-@'] = {
      '% CID',
      {'otf-ccmr-#', 'Identity-#',     'mr'},
      {'otf-ccgr-#', 'Identity-#',     'gr'},
      '% Unicode',
      {'otf-ucmr-#', 'UniGB-UCS2-#', 'mr'},
      {'otf-ucgr-#', 'UniGB-UCS2-#', 'gr'},
   },
}

local jis2004_flag = 'n'
local gsub = string.gsub

function string.explode(s, sep)
   local t = {}
   sep = sep or '\n'
   string.gsub(s, "([^"..sep.."]*)"..sep, function(c) t[#t+1]=c end)
   return t
end

local function ret_suffix(fd, s, fa)
      return suffix[s][1]
end

local function replace_index(line, s)
   local ttc_mov = suffix[s][3]
   if ttc_mov then
      local ttc_index, ttc_dir = line:match('#(%d)(.)')
      if tonumber(ttc_index) then
	 return line:gsub('#..', ':' .. tostring(tonumber(ttc_index)+tonumber(ttc_dir .. ttc_mov)) .. ':')
      end
   end
   return line
end

local function make_one_line(o, fd, s)
   if type(o) == 'string' then
      return '\n' .. o .. '\n'
   else
      local fx = foundry[fd]
      local fn = replace_index(gsub(fx[o[3]], '?', ret_suffix(fd,s,o[3])), s)
      if fx.noncid and string.match(o[2],'Identity') then
	 if string.match(fn, '%!PS') then
	    fn = gsub(fn, ' %%!PS', '/AG14 %%!PS')
	 else
	    fn = fn .. '/AG14'
	 end
      end
      if string.match(o[1], '#') then -- 'H', 'V' 一括出力
	 return gsub(o[1], '#', 'h') .. '\t' .. gsub(o[2], '#', 'H') .. '\t' .. fn .. '\n'
          .. gsub(o[1], '#', 'v') .. '\t' .. gsub(o[2], '#', 'V') .. '\t' .. fn .. '\n'
      else
	 return o[1] .. '\t' .. o[2] .. '\t' .. fn .. '\n'
      end
   end
end

for fd, v1 in pairs(foundry) do
   for _,s in pairs(v1[1]) do
      local dirname = fd .. suffix[s][2]
      print('scEmbed: ' .. dirname)
      -- Linux しか想定していない
      os.execute('mkdir ' .. dirname .. ' &>/dev/null')
      for mnx, mcont in pairs(maps) do
	 --if not string.match(mnx, '-04') or string.match(s, jis2004_flag) then
	 if not string.match(mnx, '-04') or not foundry[fd].noncid then
	    local mapbase = gsub(mnx, '@', dirname)
	    local f = io.open(dirname .. '/' .. mapbase .. '.map', 'w+')
	    for _,x in ipairs(mcont) do
	       f:write(make_one_line(x, fd, s))
	    end
	    f:close()
	 end
      end
   end
end
