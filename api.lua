---
-- Autoconfiguration.
-- Copyright (c) 2016 Blizzard Entertainment
---
local p = premake
local autoconf = p.modules.autoconf
autoconf.cache = {}

---
-- register autoconfigure api.
---
p.api.register {
	name = "autoconfigure",
	scope = "config",
	kind = "table:keyed"
}

---
-- try compiling a piece of c/c++
---
function try_compile(cfg, cpp)
	local ts = autoconf.toolset(cfg)
	if ts then
		return ts.try_compile(cfg, cpp)
	else
		p.warnOnce('autoconf', 'no toolset found, autoconf always failing.')
	end
end

---
-- check for the a particular include file.
---
function check_include(cfg, variable, filename)
	local res = autoconf.cache[variable]
	if res == nil then
		local cpp = p.capture(function ()
			p.outln('#include <' .. filename .. '>')
			p.outln('int main(void) { return 0; }')
		end)

		res = try_compile(cfg, cpp)
		if res ~= nil then
			autoconf.cache[variable] = true
		else
			autoconf.cache[variable] = false
		end
	end

	if res then
		p.outln("#define " .. variable)
	else
		p.outln("// #undef " .. variable)
	end

	return res
end


---
-- check for size of a particular type.
---
function check_type_size(cfg, variable, type)
	check_include(cfg, 'HAVE_SYS_TYPES_H', 'sys/types.h')
	check_include(cfg, 'HAVE_STDINT_H', 'stdint.h')
	check_include(cfg, 'HAVE_STDDEF_H', 'stddef.h')

	local res = autoconf.cache[variable .. cfg.platform]
	if not res then
		local cpp = p.capture(function ()
			if autoconf.cache['HAVE_SYS_TYPES_H'] then
				p.outln('#include <sys/types.h>')
			end

			if autoconf.cache['HAVE_STDINT_H'] then
				p.outln('#include <stdint.h>')
			end

			if autoconf.cache['HAVE_STDDEF_H'] then
				p.outln('#include <stddef.h>')
			end

			p.outln("")
			p.outln("#define SIZE (sizeof(" .. type .. "))")
			p.outln("char info_size[] =  {'I', 'N', 'F', 'O', ':', 's','i','z','e','[',")
			p.outln("  ('0' + ((SIZE / 10000)%10)),")
			p.outln("  ('0' + ((SIZE / 1000)%10)),")
			p.outln("  ('0' + ((SIZE / 100)%10)),")
			p.outln("  ('0' + ((SIZE / 10)%10)),")
			p.outln("  ('0' +  (SIZE     %10)),")
			p.outln("  ']', '\\0'};")

			p.outln("int main(int argc, char *argv[]) {")
			p.outln("  int require = 0;")
			p.outln("  require += info_size[argc];")
			p.outln("  (void)argv;")
			p.outln("  return require;")
			p.outln("}")
		end)

		res = try_compile(cfg, cpp)
		if res then
			local content = io.readfile(res)
			if content then
				local size = string.find(content, 'INFO:size')
				if size then
					res = tonumber(string.sub(content, size+10, size+14))
				else
					res = false
				end
			else
				res = false
			end
		end

		-- cache result.
		autoconf.cache[variable .. cfg.platform] = res
	end

	if res then
		p.outln('#define HAVE_' .. variable)
		p.outln('#define ' .. variable .. ' ' .. res)
		return true
	else
		p.outln("// #undef " .. variable)
	end
end


---
-- get the current configured toolset, or the default.
---
function autoconf.toolset(cfg)
	local ts = p.config.toolset(cfg)
	if not ts then
		local tools = {
			['vs2010']   = p.tools.msc,
			['vs2012']   = p.tools.msc,
			['vs2013']   = p.tools.msc,
			['vs2015']   = p.tools.msc,
			['gmake']    = p.tools.gcc,
			['codelite'] = p.tools.gcc,
			['xcode']    = p.tools.clang,
		}
		ts = tools[_ACTION]
	end
	return ts
end

---
-- attach ourselfs to the running action.
---
p.override(p.action, 'call', function (base, name)
	local a = p.action.get(name)

	-- store the old callback.
	local onBaseProject = a.onProject or a.onproject

	-- override it with our own.
	a.onProject = function(prj)
		-- go through each configuration, and call the setup configuration methods.
		for cfg in p.project.eachconfig(prj) do
			if cfg.autoconfigure then
				verbosef('Running auto config steps for "%s/%s".', prj.name, cfg.name)
				for file, func in pairs(cfg.autoconfigure) do
					local filename = path.join(cfg.objdir, file)
					local result = p.capture(function()
						func(cfg)
					end)
					os.mkdir(cfg.objdir)
					os.writefile_ifnotequal(result, filename)
				end
			end
		end

		-- then call the old onProject.
		onBaseProject(prj)
	end

	-- now call the original action.call methods
	base(name)
end)
