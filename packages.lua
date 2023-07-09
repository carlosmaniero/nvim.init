local packages = {
  installed = {}
}

local config_dir = vim.fn.stdpath('config')

local function parser_url(url)
  local name = url:match(".+/(.+)$")
  return {
    name = name,
    dir = config_dir .. '/pack/' .. name .. '/opt/' .. name,
    url = url
  }
end

local function clone(repo)
  vim.cmd(string.format('!mkdir -p %s; git clone %s %s', repo.dir, repo.url, repo.dir))
end

function packages.install(url)
  local repo = parser_url(url)

  table.insert(packages.installed, repo)

  if vim.fn.isdirectory(repo.dir) ~= 1 then
    clone(repo)
  end

  vim.cmd('packadd ' .. repo.name)
end

function packages.update_all()
  local commands = ''

  for _, repo in ipairs(packages.installed) do
    commands = commands .. ' ; ' .. string.format('cd %s; echo "Updating %s"; git pull; cd -', repo.dir, repo.name)
  end

  vim.cmd('terminal ' .. commands .. '; echo "Completed... Restart the editor"')
end

return packages
