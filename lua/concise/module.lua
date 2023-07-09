local rules = require("concise.rules")

-- module represents a lua module for the plugin
local M = {}

M.my_first_function = function()
  return "hello world!"
end

M.selection = function()
  vim.cmd.normal({ '"zy', bang = true })
  local text = vim.fn.getreg("z")

  print("SELECTION\n", text)
  for _, v in pairs(rules.rules()) do
    text = M.run(text, v[1], v[2])
  end
  print("REPLACEMENT\n", text)
  vim.fn.setreg("z", text)
  vim.cmd.normal({ 'gv"zp', bang = true })
end

-- Reverse a table
local function reverse(tbl)
  for i = 1, math.floor(#tbl / 2) do
    tbl[i], tbl[#tbl - i + 1] = tbl[#tbl - i + 1], tbl[i]
  end

  return tbl
end

local function contains(table, val)
  for i = 1, #table do
    if table[i] == val then
      return true
    end
  end
  return false
end

-- Replace using the frontier pattern to allow matching on whole words
local function find_and_replace(source, find, replace, whole_word)
  whole_word = false
  if whole_word then
    find = "%f[%a]" .. find .. "%f[%A]"
  end

  local original_source = source
  local matches = {}
  -- for startpos, match, endpos in original_source:lower():gmatch("()" .. find .. "()") do
  for startpos, match, endpos in original_source:lower():gmatch("()(" .. find .. ")()") do
    print(startpos, match, endpos)
    -- Push matches to an array so it can be reversed
    table.insert(matches, { startpos, endpos })
  end
  -- local reversed_matches = reverse(matches)
  local reversed_matches = reverse(matches)
  for _, value in ipairs(reversed_matches) do
    local startpos, endpos = value[1], value[2]
    local first_character_of_match = source:sub(startpos, startpos)
    local replacement = replace
    local match_is_at_the_beginning = (startpos == 1)
    local character_before_before_match = source:sub(startpos - 2, startpos - 2)

    -- If there was a trailing comma before and after the match, ensure it is removed as well.
    -- If the replacement isn't an empty string, and the original started with a capital, ensure the replacement also starts with a capital letter.
    if replacement == "" then
      local character_after = source:sub(endpos, endpos)
      local character_before = source:sub(startpos - 1, startpos - 1)
      print("character_before", '"' .. character_before .. '"')
      print("character_after", '"' .. character_after .. '"')
      print("character_before_before_match", '"' .. character_before_before_match .. '"')
      -- Check and remove one space before or after the replacement.
      if
        not match_is_at_the_beginning
        and character_before == " "
        and contains({ ",", ".", "?", " " }, character_after)
      then
        -- If the letter before this is a non alphanumeric, then actually go the other way.
        if character_after == "," and not character_before_before_match:match("%w") then
          endpos = endpos + 2
          print("here1")
        else
          startpos = startpos - 1
          print("here2")
        end
      end
    end

    local after = source:sub(endpos)
    print("first_character_of_match", first_character_of_match)

    local first_character_of_match_is_uppercase = (
      first_character_of_match == first_character_of_match:upper() -- Matches upper
      and first_character_of_match ~= first_character_of_match:lower() -- But does not match lower (e.g. might be neutral character / number)
    )

    -- Fix capitalisation of post-replacement
    if replacement ~= "" and first_character_of_match_is_uppercase then
      replacement = replacement:sub(1, 1):upper() .. replacement:sub(2)
    end

    local in_the_middle_of_a_sentence = character_before_before_match:match("%w")
    if replacement == "" and first_character_of_match_is_uppercase and not in_the_middle_of_a_sentence then
      local first_character_of_after = after:sub(1, 1)
      local second_character_of_after = after:sub(2, 2)
      if first_character_of_after:match("%a") then
        first_character_of_after = first_character_of_after:upper()
      else
        second_character_of_after = second_character_of_after:upper()
      end
      after = first_character_of_after .. second_character_of_after .. after:sub(3)
    end
    print("after", after)

    -- Splice the replacement in new_source where the match was found (in source)
    source = source:sub(1, startpos - 1) .. replacement .. after
  end

  return source
end

M.run = function(text, match, replace)
  replace = replace or ""

  -- Given some text, find the match, and replace it
  text = find_and_replace(text, match, replace, true)

  -- Strip remaining normally invalid whitespace.
  -- text = find_and_replace(text, "  ", " ")

  return text
end

return M
