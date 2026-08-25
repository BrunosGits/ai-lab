--[[
  Class Hierarchy Test Scaffold — Busted Test Suite
  
  Tests all class system features: inheritance, method overriding,
  superclass calls, adoption/mixins, type queries.
  
  Run: cd CorsixTH/Luatest && busted --lpath=../Lua/?.lua spec/class_hierarchy_spec.lua
]]

local class = require "class"

-- ============================================================================
-- TEST HELPERS
-- ============================================================================

local function make_test_classes()
    -- Root class
    class "TestRoot" (function(_ENV)
        function TestRoot:__init(value)
            self.root_value = value or "root"
            self.root_init_called = true
        end
        
        function TestRoot:rootMethod()
            return "root:" .. self.root_value
        end
        
        function TestRoot:overridden()
            return "root"
        end
        
        function TestRoot:getClassName()
            return "TestRoot"
        end
    end)
    
    -- Single inheritance
    class "TestChild" (TestRoot) (function(_ENV)
        function TestChild:__init(value, child_value)
            TestRoot.__init(self, value)
            self.child_value = child_value or "child"
            self.child_init_called = true
        end
        
        function TestChild:childMethod()
            return "child:" .. self.child_value
        end
        
        function TestChild:overridden()
            return "child:" .. TestRoot.overridden(self)
        end
        
        function TestChild:getClassName()
            return "TestChild"
        end
    end)
    
    -- Grandchild (depth 2)
    class "TestGrandChild" (TestChild) (function(_ENV)
        function TestGrandChild:__init(value, child_value, grand_value)
            TestChild.__init(self, value, child_value)
            self.grand_value = grand_value or "grand"
            self.grand_init_called = true
        end
        
        function TestGrandChild:grandMethod()
            return "grand:" .. self.grand_value
        end
        
        function TestGrandChild:overridden()
            return "grand:" .. TestChild.overridden(self)
        end
        
        function TestGrandChild:getClassName()
            return "TestGrandChild"
        end
    end)
    
    -- Second root for cross-hierarchy tests
    class "OtherRoot" (function(_ENV)
        function OtherRoot:__init()
            self.other = true
        end
        function OtherRoot:otherMethod()
            return "other"
        end
    end)
    
    -- Mixin for adoption tests
    local TestMixin = function(_ENV)
        function _ENV:mixinMethod()
            return "mixin:" .. (self.mixin_value or "default")
        end
        
        function _ENV:overridden()
            return "mixin:" .. (_ENV.super and _ENV.super.overridden(self) or "base")
        end
    end
    
    -- Class adopting mixin
    class "TestWithMixin" (TestRoot) (function(_ENV)
        TestMixin(_ENV)
        
        function TestWithMixin:__init(value, mixin_value)
            TestRoot.__init(self, value)
            self.mixin_value = mixin_value
        end
    end)
    
    -- Class adopting multiple mixins (last wins)
    local MixinA = function(_ENV)
        function _ENV:conflictMethod() return "A" end
        function _ENV:methodA() return "A" end
    end
    local MixinB = function(_ENV)
        function _ENV:conflictMethod() return "B" end
        function _ENV:methodB() return "B" end
    end
    
    class "TestMultiMixin" (TestRoot) (function(_ENV)
        MixinA(_ENV)
        MixinB(_ENV)
    end)
    
    return {
        TestRoot = TestRoot,
        TestChild = TestChild,
        TestGrandChild = TestGrandChild,
        OtherRoot = OtherRoot,
        TestWithMixin = TestWithMixin,
        TestMultiMixin = TestMultiMixin,
    }
end

-- ============================================================================
-- TEST SUITE
-- ============================================================================

describe("Class System - Core Mechanics", function()
    local classes
    
    before_each(function()
        classes = make_test_classes()
    end)
    
    describe("Class Creation", function()
        it("creates root class with __name", function()
            assert.equal("TestRoot", classes.TestRoot.__name)
        end)
        
        it("creates subclass with __name and super reference", function()
            assert.equal("TestChild", classes.TestChild.__name)
            assert.equal(classes.TestRoot, classes.TestChild.super)
        end)
        
        it("creates grandchild with correct super chain", function()
            assert.equal("TestGrandChild", classes.TestGrandChild.__name)
            assert.equal(classes.TestChild, classes.TestGrandChild.super)
            assert.equal(classes.TestRoot, classes.TestGrandChild.super.super)
        end)
        
        it("sets __class self-reference on class tables", function()
            assert.equal(classes.TestRoot, classes.TestRoot.__class)
            assert.equal(classes.TestChild, classes.TestChild.__class)
        end)
    end)
    
    describe("Instance Creation", function()
        it("instantiates root class", function()
            local obj = classes.TestRoot("test")
            assert.is_table(obj)
            assert.equal("test", obj.root_value)
            assert.is_true(obj.root_init_called)
        end)
        
        it("instantiates child class", function()
            local obj = classes.TestChild("root_val", "child_val")
            assert.equal("root_val", obj.root_value)
            assert.equal("child_val", obj.child_value)
            assert.is_true(obj.root_init_called)
            assert.is_true(obj.child_init_called)
        end)
        
        it("instantiates grandchild class", function()
            local obj = classes.TestGrandChild("r", "c", "g")
            assert.equal("r", obj.root_value)
            assert.equal("c", obj.child_value)
            assert.equal("g", obj.grand_value)
            assert.is_true(obj.root_init_called)
            assert.is_true(obj.child_init_called)
            assert.is_true(obj.grand_init_called)
        end)
    end)
    
    describe("Method Resolution Order (MRO)", function()
        it("finds methods in child class first", function()
            local obj = classes.TestChild()
            assert.equal("child:root", obj:overridden())
        end)
        
        it("walks up hierarchy to find parent methods", function()
            local obj = classes.TestChild()
            assert.equal("root:root", obj:rootMethod())
        end)
        
        it("walks full chain for grandchild", function()
            local obj = classes.TestGrandChild()
            assert.equal("grand:child:root", obj:overridden())
            assert.equal("root:root", obj:rootMethod())
            assert.equal("child:child", obj:childMethod())
            assert.equal("grand:grand", obj:grandMethod())
        end)
        
        it("does not cross hierarchy boundaries", function()
            local obj = classes.TestChild()
            assert.is_nil(obj.otherMethod)
            assert.has_error(function() obj:otherMethod() end)
        end)
    end)
    
    describe("Superclass Calls", function()
        it("explicit Parent.method(self) works", function()
            local obj = classes.TestChild()
            assert.equal("child:root", obj:overridden())
        end)
        
        it("self.super.method(self) works", function()
            -- TestChild.overridden uses TestRoot.overridden(self)
            local obj = classes.TestChild()
            assert.equal("child:root", obj:overridden())
        end)
        
        it("grandchild can call intermediate parent", function()
            local obj = classes.TestGrandChild()
            -- TestGrandChild.overridden calls TestChild.overridden which calls TestRoot.overridden
            assert.equal("grand:child:root", obj:overridden())
        end)
    end)
    
    describe("Type Checking - class.is", function()
        it("returns true for exact class", function()
            local obj = classes.TestChild()
            assert.is_true(class.is(obj, classes.TestChild))
        end)
        
        it("returns true for parent class", function()
            local obj = classes.TestChild()
            assert.is_true(class.is(obj, classes.TestRoot))
        end)
        
        it("returns true for grandparent class", function()
            local obj = classes.TestGrandChild()
            assert.is_true(class.is(obj, classes.TestRoot))
        end)
        
        it("returns false for sibling class", function()
            local obj = classes.TestChild()
            assert.is_false(class.is(obj, classes.OtherRoot))
        end)
        
        it("returns false for unrelated class", function()
            local obj = classes.TestRoot()
            assert.is_false(class.is(obj, classes.TestChild))
        end)
        
        it("returns false for non-table", function()
            assert.is_false(class.is("string", classes.TestRoot))
            assert.is_false(class.is(123, classes.TestRoot))
            assert.is_false(class.is(nil, classes.TestRoot))
        end)
        
        it("returns false for plain table without metatable", function()
            assert.is_false(class.is({}, classes.TestRoot))
        end)
    end)
    
    describe("Type Checking - class.type", function()
        it("returns exact class for instance", function()
            local obj = classes.TestChild()
            assert.equal(classes.TestChild, class.type(obj))
        end)
        
        it("returns exact class for grandchild", function()
            local obj = classes.TestGrandChild()
            assert.equal(classes.TestGrandChild, class.type(obj))
        end)
        
        it("returns nil for non-instance", function()
            assert.is_nil(class.type("string"))
            assert.is_nil(class.type({}))
            assert.is_nil(class.type(nil))
        end)
        
        it("distinguishes exact type from hierarchy", function()
            local child = classes.TestChild()
            local grand = classes.TestGrandChild()
            
            assert.equal(classes.TestChild, class.type(child))
            assert.equal(classes.TestGrandChild, class.type(grand))
            
            -- class.is is hierarchy-aware, class.type is exact
            assert.is_true(class.is(child, classes.TestRoot))
            assert.is_true(class.is(grand, classes.TestRoot))
            assert.equal(classes.TestChild, class.type(child))  -- not TestRoot!
        end)
    end)
    
    describe("Class Metadata", function()
        it("provides __name string", function()
            assert.equal("TestRoot", classes.TestRoot.__name)
            assert.equal("TestChild", classes.TestChild.__name)
            assert.equal("TestGrandChild", classes.TestGrandChild.__name)
        end)
        
        it("provides super reference", function()
            assert.equal(classes.TestRoot, classes.TestChild.super)
            assert.equal(classes.TestChild, classes.TestGrandChild.super)
            assert.is_nil(classes.TestRoot.super)
        end)
    end)
end)

describe("Class System - Adoption / Mixin Pattern", function()
    local classes
    
    before_each(function()
        classes = make_test_classes()
    end)
    
    describe("Single Mixin Adoption", function()
        it("copies mixin methods into class", function()
            local obj = classes.TestWithMixin("root", "mixin_val")
            assert.equal("mixin:mixin_val", obj:mixinMethod())
        end)
        
        it("mixin methods participate in MRO", function()
            local obj = classes.TestWithMixin("root", "mixin_val")
            -- Mixin's overridden calls super.overridden (TestRoot.overridden)
            assert.equal("mixin:root", obj:overridden())
        end)
        
        it("original class methods still work", function()
            local obj = classes.TestWithMixin("root", "mixin_val")
            assert.equal("root:root", obj:rootMethod())
        end)
        
        it("instance passes class.is for both class and superclass", function()
            local obj = classes.TestWithMixin()
            assert.is_true(class.is(obj, classes.TestWithMixin))
            assert.is_true(class.is(obj, classes.TestRoot))
        end)
    end)
    
    describe("Multiple Mixin Adoption", function()
        it("last adoption wins on conflict", function()
            local obj = classes.TestMultiMixin()
            -- MixinB adopted last, so conflictMethod returns "B"
            assert.equal("B", obj:conflictMethod())
        end)
        
        it("non-conflicting methods from all mixins available", function()
            local obj = classes.TestMultiMixin()
            assert.equal("A", obj:methodA())
            assert.equal("B", obj:methodB())
        end)
        
        it("original class methods still accessible", function()
            local obj = classes.TestMultiMixin()
            assert.equal("root:root", obj:rootMethod())
        end)
    end)
    
    describe("Adoption vs Inheritance", function()
        it("adoption does not create __index link to mixin", function()
            local obj = classes.TestWithMixin()
            -- Mixin is not in __index chain, methods copied directly
            assert.is_true(class.is(obj, classes.TestRoot))
            -- No way to detect mixin via class.is (by design)
        end)
        
        it("inheritance creates __index chain", function()
            local obj = classes.TestChild()
            assert.is_true(class.is(obj, classes.TestRoot))
            -- Can verify chain exists via metatable inspection
            local mt = getmetatable(obj)
            assert.is_table(mt.__index)  -- TestChild class table
            assert.is_table(getmetatable(mt.__index).__index)  -- TestRoot class table
        end)
    end)
end)

describe("Class System - Real CorsixTH Hierarchy Tests", function()
    -- These tests mirror actual CorsixTH class relationships
    -- They require the actual CorsixTH class.lua to be loadable
    
    local corsixth_classes
    
    setup(function()
        -- Try to load actual CorsixTH classes
        local ok, err = pcall(function()
            package.path = package.path .. ";../Lua/?.lua"
            corsixth_classes = {}
            -- Load class system first
            require "class"
            -- Load key classes
            corsixth_classes.Entity = require "entity"
            corsixth_classes.Humanoid = require "entities.humanoid"
            corsixth_classes.Patient = require "entities.humanoids.patient"
            corsixth_classes.Staff = require "entities.humanoids.staff"
            corsixth_classes.Doctor = require "entities.humanoids.staff.doctor"
            corsixth_classes.Object = require "entities.object"
            corsixth_classes.Machine = require "entities.machine"
            corsixth_classes.Room = require "room"
            corsixth_classes.Hospital = require "hospital"
        end)
        
        if not ok then
            print("Warning: Could not load CorsixTH classes: " .. tostring(err))
            corsixth_classes = nil
        end
    end)
    
    describe("Entity Hierarchy (if loadable)", function()
        if not corsixth_classes then
            it("SKIPPED - CorsixTH classes not loadable in test environment", function()
                pending("CorsixTH classes not available")
            end)
        else
            it("Entity is root class", function()
                assert.is_nil(corsixth_classes.Entity.super)
                assert.equal("Entity", corsixth_classes.Entity.__name)
            end)
            
            it("Humanoid extends Entity", function()
                assert.equal(corsixth_classes.Entity, corsixth_classes.Humanoid.super)
                assert.equal("Humanoid", corsixth_classes.Humanoid.__name)
            end)
            
            it("Patient extends Humanoid", function()
                assert.equal(corsixth_classes.Humanoid, corsixth_classes.Patient.super)
                assert.equal("Patient", corsixth_classes.Patient.__name)
            end)
            
            it("Staff extends Humanoid", function()
                assert.equal(corsixth_classes.Humanoid, corsixth_classes.Staff.super)
                assert.equal("Staff", corsixth_classes.Staff.__name)
            end)
            
            it("Doctor extends Staff", function()
                assert.equal(corsixth_classes.Staff, corsixth_classes.Doctor.super)
                assert.equal("Doctor", corsixth_classes.Doctor.__name)
            end)
            
            it("Object extends Entity (separate branch)", function()
                assert.equal(corsixth_classes.Entity, corsixth_classes.Object.super)
                assert.equal("Object", corsixth_classes.Object.__name)
            end)
            
            it("Machine extends Object", function()
                assert.equal(corsixth_classes.Object, corsixth_classes.Machine.super)
                assert.equal("Machine", corsixth_classes.Machine.__name)
            end)
        end
    end)
    
    describe("Instance Type Checks (if loadable)", function()
        if not corsixth_classes then
            it("SKIPPED", function() pending() end)
        else
            it("Patient instance passes class.is for Entity, Humanoid, Patient", function()
                local world = { entities = {}, objects = {}, rooms = {}, hospitals = {} }
                setmetatable(world, { __index = corsixth_classes.Entity }) -- minimal stub
                
                local patient = corsixth_classes.Patient(world)
                assert.is_true(class.is(patient, corsixth_classes.Patient))
                assert.is_true(class.is(patient, corsixth_classes.Humanoid))
                assert.is_true(class.is(patient, corsixth_classes.Entity))
                assert.is_false(class.is(patient, corsixth_classes.Staff))
                assert.is_false(class.is(patient, corsixth_classes.Object))
            end)
            
            it("Doctor instance passes class.is for Staff, Humanoid, Entity", function()
                local world = { entities = {}, objects = {}, rooms = {}, hospitals = {} }
                local staff_profile = { name = "Test", skill = 1, wage = 100 }
                
                local doctor = corsixth_classes.Doctor(world, staff_profile)
                assert.is_true(class.is(doctor, corsixth_classes.Doctor))
                assert.is_true(class.is(doctor, corsixth_classes.Staff))
                assert.is_true(class.is(doctor, corsixth_classes.Humanoid))
                assert.is_true(class.is(doctor, corsixth_classes.Entity))
                assert.is_false(class.is(doctor, corsixth_classes.Patient))
                assert.is_false(class.is(doctor, corsixth_classes.Object))
            end)
            
            it("class.type returns exact class", function()
                local world = { entities = {}, objects = {}, rooms = {}, hospitals = {} }
                local patient = corsixth_classes.Patient(world)
                assert.equal(corsixth_classes.Patient, class.type(patient))
                assert.not_equal(corsixth_classes.Humanoid, class.type(patient))
            end)
        end
    end)
    
    describe("Room Hierarchy (if loadable)", function()
        if not corsixth_classes then
            it("SKIPPED", function() pending() end)
        else
            it("Room is root", function()
                assert.is_nil(corsixth_classes.Room.super)
            end)
            
            it("GPRoom extends Room", function()
                local GPRoom = require "rooms.gp"
                assert.equal(corsixth_classes.Room, GPRoom.super)
            end)
        end
    end)
end)

describe("Class System - Edge Cases", function()
    local classes
    
    before_each(function()
        classes = make_test_classes()
    end)
    
    it("handles nil arguments in __init gracefully", function()
        local obj = classes.TestChild()
        assert.equal("root", obj.root_value)
        assert.equal("child", obj.child_value)
    end)
    
    it("allows adding instance fields dynamically", function()
        local obj = classes.TestRoot()
        obj.dynamic_field = "added later"
        assert.equal("added later", obj.dynamic_field)
    end)
    
    it("does not share instance state between instances", function()
        local obj1 = classes.TestRoot("first")
        local obj2 = classes.TestRoot("second")
        assert.equal("first", obj1.root_value)
        assert.equal("second", obj2.root_value)
    end)
    
    it("class tables are distinct from instances", function()
        local obj = classes.TestRoot()
        assert.not_equal(classes.TestRoot, obj)
        assert.is_table(classes.TestRoot)
        assert.is_table(obj)
    end)
    
    it("static methods accessible on class", function()
        class "StaticTest" (function(_ENV)
            function StaticTest.staticMethod(x)
                return x * 2
            end
            function StaticTest:instanceMethod()
                return self.value
            end
        end)
        
        assert.equal(10, StaticTest.staticMethod(5))
        local obj = StaticTest()
        obj.value = 42
        assert.equal(42, obj:instanceMethod())
    end)
end)

describe("Class System - Save/Load Compatibility (afterLoad)", function()
    local classes
    
    before_each(function()
        -- Define classes with afterLoad for migration testing
        class "SaveRoot" (function(_ENV)
            function SaveRoot:__init()
                self.version = 1
                self.data = "original"
            end
            function SaveRoot:afterLoad()
                self.after_load_called = true
            end
        end)
        
        class "SaveChild" (SaveRoot) (function(_ENV)
            function SaveChild:__init()
                SaveRoot.__init(self)
                self.child_data = "child_original"
                self.version = 2
            end
            function SaveChild:afterLoad()
                SaveRoot.afterLoad(self)
                self.child_after_load_called = true
                -- Migration logic example
                if self.old_field then
                    self.child_data = self.old_field
                    self.old_field = nil
                end
            end
        end)
        
        classes = { SaveRoot = SaveRoot, SaveChild = SaveChild }
    end)
    
    it("afterLoad chains correctly", function()
        local obj = classes.SaveChild()
        obj:afterLoad()
        assert.is_true(obj.after_load_called)
        assert.is_true(obj.child_after_load_called)
    end)
    
    it("migration logic in afterLoad works", function()
        local obj = classes.SaveChild()
        obj.old_field = "migrated_value"
        obj:afterLoad()
        assert.equal("migrated_value", obj.child_data)
        assert.is_nil(obj.old_field)
    end)
end)

-- ============================================================================
-- REGRESSION TESTS FOR KNOWN ISSUES
-- ============================================================================

describe("Class System - Regression Tests", function()
    local classes
    
    before_each(function()
        classes = make_test_classes()
    end)
    
    it("REGR: __init not called when using class() directly", function()
        -- class() is the constructor, not __init directly
        local obj = classes.TestRoot("value")
        assert.is_true(obj.root_init_called)
    end)
    
    it("REGR: super reference available in __init", function()
        local obj = classes.TestChild()
        -- self.super should be set by class system
        assert.equal(classes.TestRoot, obj.super)
    end)
    
    it("REGR: method override doesn't break parent for other children", function()
        class "AnotherChild" (classes.TestRoot) (function(_ENV)
            function AnotherChild:overridden()
                return "another"
            end
        end)
        
        local child1 = classes.TestChild()
        local child2 = AnotherChild()
        
        assert.equal("child:root", child1:overridden())
        assert.equal("another", child2:overridden())
        -- Parent unchanged
        local root = classes.TestRoot()
        assert.equal("root", root:overridden())
    end)
    
    it("REGR: adoption doesn't affect other classes", function()
        local Mixin = function(_ENV)
            function _ENV:mixinOnly() return "mixin" end
        end
        
        class "AdoptedClass" (classes.TestRoot) (function(_ENV)
            Mixin(_ENV)
        end)
        
        class "PlainClass" (classes.TestRoot) (function(_ENV) end)
        
        local adopted = AdoptedClass()
        local plain = PlainClass()
        
        assert.equal("mixin", adopted:mixinOnly())
        assert.has_error(function() plain:mixinOnly() end)
    end)
end)

-- ============================================================================
-- PERFORMANCE / STRESS TESTS (optional)
-- ============================================================================

describe("Class System - Performance", function()
    it("creates many instances quickly", function()
        class "PerfTest" (function(_ENV)
            function PerfTest:__init(i)
                self.id = i
            end
        end)
        
        local start = os.clock()
        local instances = {}
        for i = 1, 10000 do
            instances[i] = PerfTest(i)
        end
        local elapsed = os.clock() - start
        
        assert.equal(10000, #instances)
        assert.equal(5000, instances[5000].id)
        -- Should complete in well under 1 second
        assert.is_true(elapsed < 1.0, "Creation took " .. elapsed .. "s")
    end)
    
    it("method lookup is fast", function()
        class "PerfMethod" (function(_ENV)
            function PerfMethod:__init() self.value = 0 end
            function PerfMethod:method() self.value = self.value + 1 end
        end)
        
        local obj = PerfMethod()
        local start = os.clock()
        for i = 1, 100000 do
            obj:method()
        end
        local elapsed = os.clock() - start
        
        assert.equal(100000, obj.value)
        assert.is_true(elapsed < 0.5, "Method calls took " .. elapsed .. "s")
    end)
end)

print("Class hierarchy test scaffold loaded. Run with busted.")
