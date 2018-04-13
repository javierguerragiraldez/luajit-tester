local options = {}

local logs = {
	short = {},
	long = {},
	tests = 0,
	passes = 0,
	fails = 0,
}
local lineform = '%-40s [ %s ] %-25s\n'
local detailform = '%s -- %s\n%s\n-----\n\n'

local function finish()
	if not options.q then
		local outfile = options.e and io.stderr or io.stdout
		for _, l in ipairs(logs.short) do
			outfile:write (l)
		end
		if options.v then
			outfile:write ("---------- output ----------\n")
			for _, l in ipairs(logs.long) do
				outfile:write (l)
			end
		end
		print (string.format("tests: %d, passes: %d, fails %d",
			logs.tests, logs.passes, logs.fails
		))
	end

	os.exit(logs.fails == 0 and nil or 1)
end

local function logpass(msg)
	logs.passes = logs.passes + 1
	table.insert(logs.short, lineform:format(msg, 'pass', ''))
end

local function logerror(name, status, msg, detail)
	logs.fails = logs.fails + 1
	table.insert(logs.short, lineform:format(msg, status, name))
	table.insert(logs.long, detail and detailform:format(name, msg, detail))
	if options.f then finish() end
end

local function extend(a, b, ...)
	if not b then return a end
	for k, v in pairs(b) do
		a[k] = v
	end
	return extend(a, ...)
end

local function isiterable(x) return (pcall(pairs, x)) end
local function is_in(a, b)
	for k, v in pairs(a) do
		if not (v == b[k] or is_in(v, b[k])) then return false end
	end
	return true
end
local function deep_eq(a, b)
	if isiterable(a) and isiterable(b) then
		for k, v in pairs(a) do
			if not deep_eq(v, b[k]) then return false end
		end
		for k, v in pairs(b) do
			if not deep_eq(a[k], v) then return false end
		end
		return true
	end
	return a == b
end
local _M = {is_in=is_in, deep_eq=deep_eq}

local function one_test(test)
	logs.tests = logs.tests + 1

	if test:find('%.lua$') then
		local testfunc, err = assert(loadfile(test, 'bt', extend({}, _G, _M)))
		if not testfunc then
			logerror (test, 'parse', err)
			return
		end
		local ok, res = xpcall(testfunc, function (err)
			logerror (test, 'fail', err, debug.traceback('', 3))
		end)

		if ok then logpass(test) end

	else
		local outf = assert(io.popen(test))
		local output = outf:read('*a')
		outf:close()
		if output == '' then
			logpass(test)
		else
			logerror(test, 'fail', ret, output)
		end
	end
end

local function onearg(a)
	a = a:gsub('#.*$', ''):match('^%s*(.-)%s*$')
	if a == '' then return end
	local op, oparg = a:match('^-(%w+)=?(.*)$')
	local fname = a:match('^@(.*)$')
	if op then
		options[op] = oparg
	elseif fname then
		for l in io.lines(fname ~= '' and fname or nil) do
			onearg(l)
		end
	else
		one_test(a)
	end
end

if (...)=='tester' then		-- is it a require()'d module?
	return _M
end

for _, a in ipairs(arg) do onearg(a) end
finish()
