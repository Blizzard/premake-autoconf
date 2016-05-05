---
-- Autoconfiguration.
-- Copyright (c) 2016 Blizzard Entertainment
---
local p = premake
local msc = p.tools.msc

function msc.try_compile(cfg, text)
	-- write the text to a temporary file.
	local cppFile = path.join(cfg.objdir, "temp.cpp")
	if not io.writefile(cppFile, text) then
		return nil
	end

	-- write out a batch file.
	local batch = p.capture(function ()
		p.outln('@echo off')
		p.outln('SET mypath=%~dp0')
		p.outln('pushd %mypath%')

		local map = {
			vs2010 = 'VS100COMNTOOLS',
			vs2012 = 'VS110COMNTOOLS',
			vs2013 = 'VS120COMNTOOLS',
			vs2015 = 'VS140COMNTOOLS',
		}

		local a = map[_ACTION]
		if a then
			a = path.translate(os.getenv(a), '/')
			a = path.join(a, '../../VC/vcvarsall.bat')

			if cfg.platform == 'x86' then
				p.outln('call "' .. a .. '" > NUL')
			else
				p.outln('call "' .. a .. '" amd64 > NUL')
			end

			p.outln('cl.exe /nologo temp.cpp > NUL')
		else
			error('Unsupported Visual Studio version: ' .. _ACTION)
		end
	end)

	local batchFile = path.join(cfg.objdir, "compile.bat")
	if not io.writefile(batchFile, batch) then
		return nil
	end

	if os.execute(batchFile) then
		return path.join(cfg.objdir, "temp.exe")
	else
		return nil
	end
end
