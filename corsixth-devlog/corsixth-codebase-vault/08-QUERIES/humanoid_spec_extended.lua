require("corsixth")
require("class_test_base")

require("entity")
require("entities.humanoid")

describe("humanoid_extended.lua: Humanoid state machine", function()
  local humanoid

  before_each(function()
    local animation = {setHitTestResult = function() end}
    humanoid = Humanoid(animation)
  end)

  describe("Action queue", function()
    it("queues and retrieves actions", function()
      local action1 = {name = "action1"}
      local action2 = {name = "action2"}
      humanoid:queueAction(action1)
      humanoid:queueAction(action2)

      assert.are.equal(2, #humanoid.action_queue)
      assert.are.equal(action1, humanoid.action_queue[1])
      assert.are.equal(action2, humanoid.action_queue[2])
    end)

    it("getCurrentAction returns first action", function()
      local action1 = {name = "action1"}
      local action2 = {name = "action2"}
      humanoid:queueAction(action1)
      humanoid:queueAction(action2)

      local current = humanoid:getCurrentAction()
      assert.are.equal(action1, current)
    end)

    it("isLeaving reflects the head action flag", function()
      humanoid.action_queue = {{name = "go", is_leaving = true}}
      assert.is_true(humanoid:isLeaving())
      humanoid.action_queue = {{name = "stay"}}
      assert.is_false(humanoid:isLeaving())
    end)

    it("hasLeavingAction scans the whole queue", function()
      humanoid:queueAction({name = "stay"})
      assert.is_false(humanoid:hasLeavingAction())
      humanoid:queueAction({name = "go", is_leaving = true})
      assert.is_true(humanoid:hasLeavingAction())
    end)
  end)

  describe("Mood table", function()
    it("isMoodActive reflects active_moods contents", function()
      assert.is_false(humanoid:isMoodActive("happy"))
      humanoid.active_moods["happy"] = {priority = 1}
      assert.is_true(humanoid:isMoodActive("happy"))
      humanoid.active_moods["happy"] = nil
      assert.is_false(humanoid:isMoodActive("happy"))
    end)

    it("setCallCompleted is safe with no on_call", function()
      humanoid.on_call = nil
      humanoid:setCallCompleted()
      assert.is_true(true)
    end)
  end)
end)
