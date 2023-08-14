local fs = {}

function fs.get_relative_path(file_path)
  return vim.fn.fnamemodify(file_path, ':~:.')
end

function fs.is_file(path)
  local stat = vim.loop.fs_stat(path)
  return stat and stat.type == "file"
end

return fs
