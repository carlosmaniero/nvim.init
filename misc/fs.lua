local fs = {}

function fs.get_relative_path(file_path)
  return vim.fn.fnamemodify(file_path, ':~:.')
end

return fs
