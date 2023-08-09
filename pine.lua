local Pine3D = require("Pine3D-minified")
local scanner = peripheral.find("plethora:scanner")

-- movement and turn speed of the camera
local speed = 2 -- units per second
local turnSpeed = 180 -- degrees per second

-- create a new frame
local ThreeDFrame = Pine3D.newFrame()

-- initialize our own camera and update the frame camera
local camera = {
  x = 0,
  y = 0,
  z = 0,
  rotX = 0,
  rotY = 0,
  rotZ = 0,
}
ThreeDFrame:setCamera(camera)

local models = Pine3D.models

-- helper function to create a new Polygon
function newPoly(x1, y1, z1, x2, y2, z2, x3, y3, z3, c)
  return {
    x1 = x1, y1 = y1, z1 = z1, x2 = x2, y2 = y2, z2 = z2, x3 = x3, y3 = y3, z3 = z3,
    c = c,
  }
end
-- define the objects to be rendered
local objects = {}

local function byteStr(str)
  local t = {}
  str:gsub(".",function(c) table.insert(t,c) end)
  --Code from a stack overflow thread
  local res = ""
  for v,k in ipairs(t) do
    local n = string.byte(k)
    res = res .. tostring(n)
  end
  return res
end

local directions = {
  east = 270*math.pi/180,
  north = 0*math.pi/180,
  west = 90*math.pi/180,
  south = 180*math.pi/180
}

local function chunk()
    objects = {}
    for k,block in pairs(scanner.scan()) do
        if not (block.name == "minecraft:air") then
            if block.name == "computercraft:turtle_advanced" then
                local facing = scanner.getBlockMeta(block.x,block.y,block.z).state.facing
                local direction = directions[facing]
                table.insert(objects,ThreeDFrame:newObject("models/turtle", block.x, block.y, block.z, nil, direction))
            elseif block.name == "computercraft:turtle_normal" then
                local facing = scanner.getBlockMeta(block.x,block.y,block.z).state.facing
                local direction = directions[facing]
                table.insert(objects,ThreeDFrame:newObject("models/turtle", block.x, block.y, block.z, nil, direction))
            else
                if block.name == "minecraft:grass_block" then
                  -- creates a very simple grass block model
                  local cube = models:cube({
                    color = colors.orange,
                    top = colors.lime,
                    bottom = colors.brown,
                  })
                else
                  math.randomseed(tonumber(byteStr(block.name)))
                  local cube = models:cube({
                    side2 = 2^math.floor(math.random(16)),
                    side = 2^math.floor(math.random(16)),
                    top = 2^math.floor(math.random(16)),
                    bottom = 2^math.floor(math.random(16)),
                    bottom2 = 2^math.floor(math.random(16))
                  })
                end
                table.insert(objects,ThreeDFrame:newObject(cube, block.x, block.y, block.z))
            end
        end
    end
end

chunk()

-- handle all keypresses and store in a lookup table
-- to check later if a key is being pressed
local keysDown = {}
local mousePress = false
local mousex = 0
local mousey = 0
local function keyInput()
  while true do
    -- wait for an event
    local event, key, x, y = os.pullEvent()

    if event == "key" then -- if a key is pressed, mark it as being pressed down
      keysDown[key] = true
    elseif event == "key_up" then -- if a key is released, reset its value
      keysDown[key] = nil
    elseif event == "mouse_click" then
      mousePress = true
      mousex = x
      mousey = y
    end
  end
end

-- update the camera position based on the keys being pressed
-- and the time passed since the last step
local function handleCameraMovement(dt)
  local dx, dy, dz = 0, 0, 0 -- will represent the movement per second

  -- handle arrow keys for camera rotation
  if keysDown[keys.left] then
    camera.rotY = (camera.rotY - turnSpeed * dt) % 360
  end
  if keysDown[keys.right] then
    camera.rotY = (camera.rotY + turnSpeed * dt) % 360
  end
  if keysDown[keys.down] then
    camera.rotZ = math.max(-80, camera.rotZ - turnSpeed * dt)
  end
  if keysDown[keys.up] then
    camera.rotZ = math.min(80, camera.rotZ + turnSpeed * dt)
  end

  -- handle wasd keys for camera movement
  if keysDown[keys.w] then
    dx = speed * math.cos(math.rad(camera.rotY)) + dx
    dz = speed * math.sin(math.rad(camera.rotY)) + dz
  end
  if keysDown[keys.s] then
    dx = -speed * math.cos(math.rad(camera.rotY)) + dx
    dz = -speed * math.sin(math.rad(camera.rotY)) + dz
  end
  if keysDown[keys.a] then
    dx = speed * math.cos(math.rad(camera.rotY - 90)) + dx
    dz = speed * math.sin(math.rad(camera.rotY - 90)) + dz
  end
  if keysDown[keys.d] then
    dx = speed * math.cos(math.rad(camera.rotY + 90)) + dx
    dz = speed * math.sin(math.rad(camera.rotY + 90)) + dz
  end

  -- space and left shift key for moving the camera up and down
  if keysDown[keys.space] then
    dy = speed + dy
  end
  if keysDown[keys.leftShift] then
    dy = -speed + dy
  end

  -- update the camera position by adding the offset
  camera.x = camera.x + dx * dt
  camera.y = camera.y + dy * dt
  camera.z = camera.z + dz * dt

  ThreeDFrame:setCamera(camera)
end

local block = ""

local shellt = false

-- handle game logic
local function handleGameLogic(dt)
  if mousePress then
    mousePress = false
    local objectIndex, polyIndex = ThreeDFrame:getObjectIndexTrace(objects, mousex, mousey) -- detect on what and object the player clicked
    if objectIndex then -- if the player clicked on an object (not void)
      local object = objects[objectIndex]
      local x, y, z = object[1], object[2], object[3]
      local meta = scanner.getBlockMeta(x,y,z)
      block = meta.name
    end
  end

  --Handle turtle movement
  if keysDown[keys.u] then
    turtle.forward()
    chunk()
  end
  if keysDown[keys.j] then
    turtle.back()
    chunk()
  end
  if keysDown[keys.h] then
    turtle.turnLeft()
    chunk()
  end
  if keysDown[keys.k] then
    turtle.turnRight()
    chunk()
  end
  if keysDown[keys.q] then
    turtle.down()
    chunk()
  end
  if keysDown[keys.e] then
    turtle.up()
    chunk()
  end
  if keysDown[keys.r] then
    chunk()
  end
  if keysDown[keys.c] then
    local input = read()
    shellt = true
    shell.run(input)
    shellt = false
    chunk()
  end
end

-- handle the game logic and camera movement in steps
local function gameLoop()
  local lastTime = os.clock()

  while true do
    -- compute the time passed since last step
    local currentTime = os.clock()
    local dt = currentTime - lastTime
    lastTime = currentTime

    -- run all functions that need to be run
    handleGameLogic(dt)
    handleCameraMovement(dt)

    -- use a fake event to yield the coroutine
    os.queueEvent("gameLoop")
    os.pullEventRaw("gameLoop")
  end
end

-- render the objects
local function rendering()
  while true do
    if shellt == false then
      -- load all objects onto the buffer and draw the buffer
      ThreeDFrame:drawObjects(objects)
      ThreeDFrame:drawBuffer()
      term.setCursorPos(1,1)
      term.write(block)
    end
    -- use a fake event to yield the coroutine
    os.queueEvent("rendering")
    os.pullEventRaw("rendering")
  end
end

-- start the functions to run in parallel
parallel.waitForAny(keyInput, gameLoop, rendering)