function _init()
    dropoffs = {}

    -- get list of dropoff locations
    for mx=1, 1016 do
        for my=1, 504 do
            if fget(mget(mx, my)) == 1 then
                add(dropoffs, {x=mx*8+4, y=my*8+4})
            end
        end
    end

    p = {
        x = 64,
        y = 64,
        w = 8,
        h = 8,
        dir = 0.75, -- direction
        turn = 0.015, -- turning power; increase for sharper turn

        vel = 0, -- velocity
        acc = 0.45, -- acceleration
        fr = 0.8, -- friction

        cc = 0,
        score = 0,
        limit = 1, -- boost recharge time, in sec
        charge = 0,
        time = 0,
        boost = true
    }

    c = {
        x = p.x,
        y = p.y,
        dir = 0.75,

        vel = 0,
        acc = 0.65,
        fr = 0.85,
        dist = 0
    }

    threshold = 2

    coins = {}
    gen_coins()
end

function _update60()
    for dropoff in all(dropoffs) do
        dropoff.xd = abs(dropoff.x - p.x)
        dropoff.yd = abs(dropoff.y - p.y)
        if dropoff.xd > 100 or dropoff.yd > 100 then
            dropoff.dist = 1000
        else
            dropoff.dist = flr(sqrt((dropoff.x-p.x)^2 + (dropoff.y-p.y)^2)) -- dist
        end
        
        dropoff.dir = atan2(p.y-dropoff.y, p.x-dropoff.x) -- angle
    end

    drive = btn(5) or btn(2)

    -- change direction
    if drive and btn(0) then
        p.dir-=p.turn
        p.dir+=0.0005*p.cc
    elseif drive and btn(1) then
        p.dir+=p.turn
        p.dir-=0.0005*p.cc
    end

    -- if driving, accelerate
    if drive then
        p.vel += p.acc-0.001*p.cc
    end

    -- boost with x
    if btnp(5) and drive and p.boost then
        p.vel += 5-0.05*p.cc
        p.boost = false
        p.charge = 0
        p.time = t()
    end

    -- charge up boost
    if not p.boost then
        if p.charge < p.limit then
            p.charge = t() - p.time
        else
            p.boost = true
        end
    end

    -- drop coins with o
    if btnp(4) and drive then
        p.cc -= 1
        add(coins, {c.x, c.y})
    end

    -- decelerate due to friction
    if p.vel != 0 then
        p.vel *= p.fr
    end

    -- apply movement to player
    p.x+=sin(p.dir)*p.vel
    p.y+=cos(p.dir)*p.vel

    -- calc angle and distance between camera and player
    c.dir = atan2(p.y-c.y, p.x-c.x)
    c.dist = sqrt((c.x-p.x)^2 + (c.y-p.y)^2)

    -- if player is far enough away, start moving camera
    if c.dist > 10 then
        c.vel += c.acc
    end

    -- decelerate camera
    if c.vel != 0 then
        c.vel *= c.fr
    end

    -- apply movement to camera
    c.x+=sin(c.dir)*c.vel
    c.y+=cos(c.dir)*c.vel

    coin_pickup()
    check_collision()
    check_drop()
end

function _draw()
    -- apply camera position
    camera(c.x-64, c.y-64)

    cls(0)
    map(0, 0, 0, 0)

    spr(4, p.x-3, p.y-3) -- player sprite
    pset(p.x+3*sin(p.dir), p.y+3*cos(p.dir), 7) -- direction indicator

    draw_coins()

    -- UI
    camera(0, 0)
    
    count = 0
    for dropoff in all(dropoffs) do
        if dropoff.dist < 300 then
            count += 1
            ind = raycast(dropoff)
            spr(2, ind[1], ind[2])
        end
    end

    rectfill(0, 120, 20, 128, 6)
    rectfill(0, 120, 0+(p.charge/p.limit*20), 128, 7)
    if p.boost then
        rectfill(0, 120, 20, 128, 10)
    end

    print(p.cc, 0, 0, 7) -- score
    print(p.score, 10)
    print(p.x)
    print(p.y)
    print(count)

    -- apply camera position
    camera(c.x-64, c.y-64)
end

function gen_coins()
    for i=1, 200 do
        add(coins, {rnd(1016), rnd(504)})
    end
end

function draw_coins()
    for coin in all(coins) do
        spr(3, coin[1]-4, coin[2]-4)
    end
end

function coin_pickup()
    for coin in all(coins) do
        -- if within hitbox, remove coin and add score
        if p.x-0.5*(p.w) < coin[1]+5 and -- add 5 to coin hitbox
        p.x+0.5*(p.w) > coin[1]-5 and -- makes it more generous
        p.y-0.5*(p.h) < coin[2]+5 and
        p.y+0.5*(p.h) > coin[2]-5 then
            p.cc += 1
            del(coins, coin)
        end
    end
end

function check_collision()
    if p.vel < threshold and fget(mget(p.x\8, p.y\8)) == 2 then
        p.fr = 0
    end
end

function check_drop()
    if fget(mget(p.x\8, p.y\8)) == 1 then
        p.score += 10*p.cc
        p.cc = 0
        if #coins == 0 then
            gen_coins()
        end
    end
end

function raycast(dest)
    local angle = dest.dir*-1+0.25

    local vx = cos(angle)
    local vy = sin(angle)
    
    --if dist. to next pixel is positive, set increment to positive
    if vx >= 0 then
        stepx = 1
    else
        stepx = -1
    end

    --repeat for y
    if vy >= 0 then
        stepy = 1
    else 
        stepy = -1
    end

    --copy the player coords to use in calculations
    local x = p.x
    local y = p.y

    --store the most recent visited pixel
    local current = {x, y}

    while within_bounds(current[1], current[2]) do
        --calculate the next horizontal and vertical coords
        local next_vert = current[1]+1
        local next_hori = current[2]+1

        --calculate the distances to the next horizontal and vertical pixels
        local tmax_x = (next_vert - x) / vx
        local tmax_y = (next_hori - y) / vy

        --if moving horizontally is next...
        if tmax_x < tmax_y then
            --move to the next pixel
            local temp = current[1]
            current[1] = temp + stepx

            --change the horizontal position
            y += sin(angle)/cos(angle) * (next_vert - x)

            --set the current x to the pixel we've moved to
            x = next_vert
        --if moving vertically is next...
        else
            --move to the next pixel
            local temp = current[2]
            current[2] = temp + stepy

            --change the vertical position
            x += (next_hori - y) / sin(angle)/cos(angle) 

            --set the current y to the pixel we've moved to
            y = next_hori
        end
    end

    return current
end

function within_bounds(x, y)
    return (0 < x) and (x < 128) and (0 < y) and (y < 128)
end
