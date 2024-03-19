local ls = require'luasnip'

local function create_ex_snippet(ex_command, snip)
  vim.api.nvim_buf_create_user_command(0, ex_command, function(opts)
    local fargs = opts.fargs
    ls.snip_expand(snip, {expand_params = {captures = fargs}})
  end, { nargs = '*' })
end

local function table_create_preamble(args, parent, old_state, user_args)
  local cnt = tonumber(parent.captures[1])
  return string.rep('c', cnt)
end

local function table_create_table(args, parent, old_state, user_args)
  local cols = tonumber(parent.captures[1])
  local rows = tonumber(parent.captures[2])

  local ctr = 1
  local ret = {}

  table.insert(ret, t{"  \\toprule", "  "})

  for c = 1, cols do
    table.insert(ret, i(ctr))
    if c ~= cols then
      table.insert(ret, t" & ")
    else
      table.insert(ret, t" \\\\ ")
    end
    ctr = ctr + 1
  end

  table.insert(ret, t{"", "  \\midrule"})

  for r = 1, rows do
    table.insert(ret, t{"", "  "})
    for c = 1, cols do
      table.insert(ret, i(ctr))
      if c ~= cols then
        table.insert(ret, t" & ")
      else
        table.insert(ret, t" \\\\ ")
      end
      ctr = ctr + 1
    end
  end

  table.insert(ret, t{"", "  \\bottomrule"})

  return sn(nil, ret)
end

local snip = s("",
  fmta([[
  \begin{tabular}{<>}
  <>
  \end{tabular}
  ]],
  {
    f(table_create_preamble),
    d(1, table_create_table),
  }
  )
)

create_ex_snippet('PStab', snip) -- PS jako Pavlvovy Snippety

return {
  s({trig = ";env", snippetType="autosnippet"},
    fmta([[
    \begin{<>}
      <>
    \end{<>}
    ]],
    {
      i(1),
      i(0),
      rep(1),
    }
    )
  ),
}
