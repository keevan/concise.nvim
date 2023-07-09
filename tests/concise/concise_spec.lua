local plugin = require("concise")

describe("setup", function()
  it("removes unnecessary words", function()
    assert("I think I can = I can", plugin.run("I think I can"))
  end)

  it("replaces words with concise counterparts", function()
    assert("It is 12 noon = It is noon", plugin.run())
  end)

  it("removes words based on user defined rules", function()
    assert("my first function with param = run!", plugin.run())
  end)

  it("replaces words based on user defined rules", function()
    assert("my first function with param = run!", plugin.run())
  end)
end)
