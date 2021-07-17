-- fontproof / a tool for testing fonts
-- copyright 2016-2020 SIL International and released under the MIT/X11 license

local plain = SILE.require("classes/plain")
local fontproof = plain { id = "fontproof" }

SILE.scratch.fontproof = {}
SILE.scratch.fontproof = {
  runhead = {},
  section = {},
  subsection = {},
  testfont = {},
  groups = {}
}

-- set defaults
SILE.scratch.fontproof.testfont.family = "Gentium Plus"
SILE.scratch.fontproof.testfont.size = "8pt"
SILE.scratch.fontproof.runhead.family = "Gentium Plus"
SILE.scratch.fontproof.runhead.size = "5pt"
SILE.scratch.fontproof.section.family = "Gentium Plus"
SILE.scratch.fontproof.section.size = "12pt"
SILE.scratch.fontproof.subsection.family = "Gentium Plus"
SILE.scratch.fontproof.subsection.size = "12pt"
SILE.scratch.fontproof.sileversion = SILE.version

fontproof.defaultFrameset = {
  content = {
    left = "8%pw",
    right = "92%pw",
    top = "6%ph",
    bottom = "96%ph"
  },
  runningHead = {
    left = "left(content)",
    right = "right(content)",
    top = "top(content)-3%ph",
    bottom = "top(content)-1%ph"
  }
}

local hb = require("justenoughharfbuzz")
SILE.scratch.fontproof.hb = hb.version()

function fontproof:init ()
  self:loadPackage("linespacing")
  self:loadPackage("lorem")
  self:loadPackage("specimen")
  self:loadPackage("rebox")
  self:loadPackage("features")
  self:loadPackage("color")
  self:loadPackage("fontprooftexts")
  self:loadPackage("fontproofgroups")
  self:loadPackage("gutenberg-client")
  SILE.settings.set("document.parindent", SILE.nodefactory.glue(0))
  SILE.settings.set("document.spaceskip")
  return plain.init(self)
end

local function getGitCommit()
  -- If we are in a git repository, report the latest commit ID
  local fh = io.popen("git describe --long --tags --abbrev=7 --always --dirty='*'")
  local commit = fh:read()
  if commit then
    return " ["..commit.."]"
  end
  return ""
end

function fontproof:endPage ()
  SILE.call("nofolios")
  local runheadinfo
  if SILE.scratch.fontproof.testfont.filename then
    local gitcommit = getGitCommit()
    runheadinfo = "Fontproof for: " .. SILE.scratch.fontproof.testfont.filename .. gitcommit .. " - Input file: " ..  SILE.masterFilename .. ".sil - " .. os.date("%A %d %b %Y %X %z %Z") .. " - SILE " .. SILE.scratch.fontproof.sileversion .. " - HarfBuzz " ..  SILE.scratch.fontproof.hb
  else
    runheadinfo = "Fontproof for: " .. SILE.scratch.fontproof.testfont.family .. " - Input file: " .. SILE.masterFilename .. ".sil - " .. os.date("%A %d %b %Y %X %z %Z") .. " - SILE " .. SILE.scratch.fontproof.sileversion .. " - HarfBuzz " ..  SILE.scratch.fontproof.hb
  end
  SILE.typesetNaturally(SILE.getFrame("runningHead"), function()
    SILE.settings.set("document.rskip", SILE.nodefactory.hfillglue())
    SILE.settings.set("typesetter.parfillskip", SILE.nodefactory.glue(0))
    SILE.settings.set("document.spaceskip", SILE.shaper:measureChar(" ").width)
    SILE.call("font", {
        family = SILE.scratch.fontproof.runhead.family,
        size = SILE.scratch.fontproof.runhead.size
      }, { runheadinfo })
    SILE.call("par")
  end)
  return plain.endPage(self)
end

SILE.registerCommand("setTestFont", function (options, _)
  local testfilename = options.filename or nil
  local testfamily = options.family or nil
  if options.size then
    SILE.scratch.fontproof.testfont.size = options.size
  end
  if testfilename == nil then
    -- NOTE: fontfile is a variable that can only be set on the command line (see docs)
    -- See also https://github.com/sile-typesetter/sile/issues/722
    -- luacheck: ignore fontfile
    testfilename = fontfile
  end
  if testfamily then
    SILE.scratch.fontproof.testfont.family = testfamily
  else
    SILE.scratch.fontproof.testfont.filename = testfilename
  end
  options.family = testfamily
  options.filename = testfilename
  options.size = SILE.scratch.fontproof.testfont.size
  SILE.call("font", options, {})
end)

-- optional way to override defaults
SILE.registerCommand("setRunHeadStyle", function (options, _)
  SILE.scratch.fontproof.runhead.family = options.family
  SILE.scratch.fontproof.runhead.size = options.size or "8pt"
end)

-- basic text styles
SILE.registerCommand("basic", function (_, content)
  SILE.settings.temporarily(function()
    SILE.call("font", {
        filename = SILE.scratch.fontproof.testfont.filename,
        size = SILE.scratch.fontproof.testfont.size
      }, function () SILE.call("raggedright", {}, content) end)
  end)
end)

SILE.registerCommand("section", function (_, content)
  SILE.typesetter:leaveHmode()
  SILE.call("goodbreak")
  SILE.call("bigskip")
  SILE.call("noindent")
  SILE.call("font", {
      family = SILE.scratch.fontproof.section.family,
      size = SILE.scratch.fontproof.section.size
    }, function () SILE.call("raggedright", {}, content) end)
  SILE.call("novbreak")
  SILE.call("medskip")
  SILE.call("novbreak")
  SILE.typesetter:inhibitLeading()
end)

SILE.registerCommand("subsection", function (_, content)
  SILE.typesetter:leaveHmode()
  SILE.call("goodbreak")
  SILE.call("bigskip")
  SILE.call("noindent")
  SILE.call("font", {
      family = SILE.scratch.fontproof.subsection.family,
      size = SILE.scratch.fontproof.subsection.size
    }, function () SILE.call("raggedright", {}, content) end)
  SILE.call("novbreak")
  SILE.call("medskip")
  SILE.call("novbreak")
  SILE.typesetter:inhibitLeading()
end)

-- useful functions
local function fontsource (fam, file)
  local family, filename
  if file then
    family = nil
    filename = file
  elseif fam then
    family = fam
    filename = nil
  elseif SILE.scratch.fontproof.testfont.filename then
    filename = SILE.scratch.fontproof.testfont.filename
    family = nil
  else
    family = SILE.scratch.fontproof.testfont.family
    filename = nil
  end
  return family, filename
end

local function sizesplit (str)
  local sizes = {}
  for s in string.gmatch(str, "%w+") do
    if not string.find(s, "%a") then s = s .. "pt" end
    table.insert(sizes, s)
  end
  return sizes
end

local function processtext (str)
  local newstr = str
  local temp = str[1]
  if string.sub(temp, 1, 5) == "text_" then
    local textname = string.sub(temp, 6)
    if SILE.scratch.fontproof.texts[textname] ~= nil then
      newstr[1] = SILE.scratch.fontproof.texts[textname].text
    end
  end
  return newstr
end

-- special tests
SILE.registerCommand("proof", function (options, content)
  local proof = {}
  local procontent = processtext(content)
  if options.type ~= "pattern" then
    if options.heading then
      SILE.call("subsection", {}, { options.heading })
    else
      SILE.call("bigskip")
    end
  end
  if options.size then
    proof.sizes = sizesplit(options.size)
  else proof.sizes = { SILE.scratch.fontproof.testfont.size }
  end
  if options.shapers then
    if SILE.settings.declarations["harfbuzz.subshapers"] then
      SILE.settings.set("harfbuzz.subshapers", options.shapers)
    else SU.warn("Can't use shapers on this version of SILE; upgrade!")
    end
  end
  proof.family, proof.filename = fontsource(options.family, options.filename)
  SILE.call("color", options, function ()
    for i = 1, #proof.sizes do
      SILE.settings.temporarily(function ()
        local fontoptions = {
          family = proof.family,
          filename = proof.filename,
          size = proof.sizes[i]
        }
        -- Pass on some options from \proof to \font.
        local tocopy = { "language"; "direction"; "script" }
        for j = 1, #tocopy do
          if options[tocopy[j]] then fontoptions[tocopy[j]] = options[tocopy[j]] end
        end
        -- Add feature options
        if options.featuresraw then fontoptions.features = options.featuresraw end
        if options.features then
          for j in SU.gtoke(options.features, ",") do
            if j.string then
              local feat = {}
              local _, _, k, v = j.string:find("(%w+)=(.*)")
              feat[k] = v
              SILE.call("add-font-feature", feat, {})
            end
          end
        end
        SILE.call("font", fontoptions, {})
        SILE.call("raggedright", {}, procontent)
      end)
    end
  end)
end)

SILE.registerCommand("pattern", function(options, content)
  --SU.required(options, "reps")
  local chars = std.string.split(options.chars, ",")
  local reps = std.string.split(options.reps, ",")
  local format = options.format or "table"
  local size = options.size or SILE.scratch.fontproof.testfont.size
  local cont = processtext(content)[1]
  local paras = {}
  if options.heading then SILE.call("subsection", {}, { options.heading })
  else SILE.call("bigskip")
  end
  for i, _ in ipairs(chars) do
    local char, group = chars[i], reps[i]
    local gitems
    if string.sub(group, 1, 6) == "group_" then
      local groupname = string.sub(group, 7)
      gitems = SU.splitUtf8(SILE.scratch.fontproof.groups[groupname])
    else
      gitems = SU.splitUtf8(group)
    end
    local newcont = ""
    for r = 1, #gitems do
      if gitems[r] == "%" then gitems[r] = "%%" end
      local newstr = string.gsub(cont, char, gitems[r])
      newcont = newcont .. char .. newstr
    end
    cont = newcont
  end
  if format == "table" then
    if chars[2] then
      paras = std.string.split(cont, chars[2])
    else
      table.insert(paras, cont)
    end
  elseif format == "list" then
    for _, c in ipairs(chars) do
      cont = string.gsub(cont, c, chars[1])
    end
    paras = std.string.split(cont, chars[1])
  else
    table.insert(paras, cont)
  end
  for _, para in ipairs(paras) do
    for _, c in ipairs(chars) do
      para = string.gsub(para, c, " ")
    end
    SILE.call("proof", { size = size, type = "pattern" }, { para })
  end
end)

SILE.registerCommand("patterngroup", function(options, content)
  SU.required(options, "name")
  local group = content[1]
  SILE.scratch.fontproof.groups[options.name] = group
end)

-- Try and find a dictionary
local dict = {}
local function shuffle(tbl)
  local size = #tbl
  for i = size, 1, -1 do
    local rand = math.random(size)
    tbl[i], tbl[rand] = tbl[rand], tbl[i]
  end
  return tbl
end

SILE.registerCommand("adhesion", function(options, _)
  local chars = SU.required(options, "characters")
  local f
  if #dict == 0 then
    if options.dict then
      f = io.open(options.dict, "r")
    else
      f = io.open("/usr/share/dict/words", "r")
      if not f then
        f = io.open("/usr/dict/words", "r")
      end
    end
    if f then
      for line in f:lines() do
        line = line:gsub("\n", "")
        table.insert(dict, line)
      end
    else
      SU.error("Couldn't find a dictionary file to use")
    end
  end
  local wordcount = options.wordcount or 120
  local words = {}
  shuffle(dict)
  for _, word in ipairs(dict) do
    if wordcount == 0 then break end
    -- This is fragile. Would be better to check and escape.
    if word:match("^["..chars.."]+$") then
      table.insert(words, word)
      wordcount = wordcount - 1
    end
  end
  SILE.typesetter:typeset(table.concat(words, " ")..".")
end)

local hasGlyph = function(g)
  local options = SILE.font.loadDefaults({})
  local newItems = SILE.shapers.harfbuzz:shapeToken(g, options)
  for i = 1, #newItems do
    if newItems[i].gid > 0 then
      return true
    end
  end
  return false
end

SILE.registerCommand("pi", function (options, _)
  local digits = tonumber(options.digits) or 100
  digits = digits + 4 -- to match previous behaviour
  local pi = "3.141592653589793238462643383279502884197169399375105820974944592307816406286208998628034825342117067982148086513282306647093844609550582231725359408128481117450284102701938521105559644622948954930381964428810975665933446128475648233786783165271201909145648566923460348610454326648213393607260249141273724587006606315588174881520920962829254091715364367892590360011330530548820466521384146951941511609433057270365759591953092186117381932611793105118548074462379962749567351885752724891227938183011949129833673362440656643086021394946395224737190702179860943702770539217176293176752384674818467669405132000568127145263560827785771342757789609173637178721468440901224953430146549585371050792279689258923542019956112129021960864034418159813629774771309960518707211349999998372978049951059731732816096318595024459455346908302642522308253344685035261931188171010003137838752886587533208381420617177669147303598253490428755468731159562863882353787593751957781857780532171226806613001927876611195909216420198938095257201065485863278865936153381827968230301952035301852968995773622599413891249721775283479131515574857242454150695950829533116861727855889075098381754637464939319255060400927701671139009848824012858361603563707660104710181942955596198946767837449448255379774726847104047534646208046684259069491293313677028989152104752162056966024058038150193511253382430035587640247496473263914199272604269922796782354781636009341721641219924586315030286182974555706749838505494588586926995690927210797509302955321165344987202755960236480665499119881834797753566369807426542527862551818417574672890977772793800081647060016145249192173217214772350141441973568548161361157352552133475741849468438523323907394143334547762416862518983569485562099219222184272550254256887671790494601653466804988627232791786085784383827967976681454100953883786360950680064225125205117392984896084128488626945604241965285022210661186306744278622039194945047123713786960956364371917287467764657573962413890865832645995813390478027590099465764078951269468398352595709825822"
  local pi_digits = pi:sub(1, digits)
  for i = 1, #pi_digits do
    SILE.typesetter:typeset(pi_digits:sub(i, i))
    SILE.typesetter:pushPenalty({}) -- Ugly
  end
end)

SILE.registerCommand("unicharchart", function (options, _)
  local type = options.type or "all"
  local showheader = SU.boolean(options.showheader, true)
  local rows = tonumber(options.rows) or 16
  local columns = tonumber(options.columns) or 12
  local charsize = tonumber(options.charsize) or 14
  local usvsize = tonumber(options.usvsize) or 6
  local glyphs = {}
  local rangeStart
  local rangeEnd
  if type == "range" then
    rangeStart = tonumber(SU.required(options, "start"), 16)
    rangeEnd = tonumber(SU.required(options, "end"), 16)
    for cp = rangeStart, rangeEnd do
      local uni = SU.utf8charfromcodepoint(tostring(cp))
      glyphs[#glyphs+1] = { present = hasGlyph(uni), cp = cp, uni = uni }
    end
  else
    -- XXX For now, brute force inspect the glyph set
    local allglyphs = {}
    for cp = 0x1, 0xFFFF do
      allglyphs[#allglyphs+1] = SU.utf8charfromcodepoint(tostring(cp))
    end
    local s = table.concat(allglyphs, "")
    local shape_options = SILE.font.loadDefaults({})
    local items = SILE.shapers.harfbuzz:shapeToken(s, shape_options)
    for i in ipairs(items) do
      local cp = SU.codepoint(items[i].text)
      if items[i].gid ~= 0 and cp > 0 then
        glyphs[#glyphs+1] = {
          present = true,
          cp = cp,
          uni = items[i].text
        }
      end
    end
  end
  local width = SILE.measurement("100%fw"):absolute() / columns
  local done = 0
  while done < #glyphs do
    -- header row
    if type == "range" and showheader then
      SILE.call("font", { size = charsize }, function()
        for j = 0, columns-1 do
          local ix = done + j * rows
          local cp = rangeStart+ix
          if cp > rangeEnd then break end
          SILE.call("hbox")
          SILE.call("hbox", {}, function ()
            local header = string.format("%04X", cp)
            local hexDigits = string.len(header) - 1
            SILE.typesetter:typeset(header:sub(1, hexDigits))
          end)
          local nbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
          local centeringglue = SILE.nodefactory.glue((width-nbox.width)/2)
          SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = centeringglue
          SILE.typesetter:pushHorizontal(nbox)
          SILE.typesetter:pushGlue(centeringglue)
          SILE.call("hbox")
        end
      end)
      SILE.call("bigskip")
      SILE.call("hbox")
    end
    for i = 0, rows-1 do
      for j = 0, columns-1 do
        local ix = done + j * rows + i
        SILE.call("font", { size = charsize }, function ()
          if glyphs[ix+1] then
            local char = glyphs[ix+1].uni
            if glyphs[ix+1].present then
              local left = SILE.shaper:measureChar(char).width
              local centeringglue = SILE.nodefactory.glue((width-left)/2)
              SILE.typesetter:pushGlue(centeringglue)
              SILE.typesetter:typeset(char)
              SILE.typesetter:pushGlue(centeringglue)
            else
              SILE.typesetter:pushGlue(width)
            end
            SILE.call("hbox")
          end
        end)

      end
      SILE.call("par")
      SILE.call("hbox")
      SILE.call("font", { size = usvsize }, function()
        for j = 0, columns-1 do
          local ix = done + j * rows + i
          if glyphs[ix+1] then
            SILE.call("hbox", {}, function ()
              SILE.typesetter:typeset(string.format("%04X", glyphs[ix+1].cp))
            end)
            local nbox = SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes]
            local centeringglue = SILE.nodefactory.glue((width-nbox.width)/2)
            SILE.typesetter.state.nodes[#SILE.typesetter.state.nodes] = centeringglue
            SILE.typesetter:pushHorizontal(nbox)
            SILE.typesetter:pushGlue(centeringglue)
            SILE.call("hbox")
          end
        end
      end)
      SILE.call("bigskip")
    end
    SILE.call("pagebreak")
    done = done + rows * columns
  end
end)

return fontproof
