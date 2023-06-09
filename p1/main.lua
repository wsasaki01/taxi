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

    count = 0
    for dropoff in all(dropoffs) do
        print(dropoff.dist, dropoff.x, dropoff.y, 7)
        if 60 < dropoff.dist and dropoff.dist < 400 then
            count += 1
            ind = raycast(p.x, p.y, dropoff.x, dropoff.y, c.x-64, c.y-64)
            circfill(ind[1], ind[2], sqrt(dropoff.dist), 1)
        end
    end

    -- UI
    camera(0, 0)

    rectfill(0, 120, 20, 128, 6)
    rectfill(0, 120, 0+(p.charge/p.limit*20), 128, 7)
    if p.boost then
        rectfill(0, 120, 20, 128, 10)
    end

    print("", 0, 0, 7)
    print(p.cc) -- score
    print(p.score, 10)
    print("")
    print(p.x)
    print(p.y)

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

function raycast(x0, y0, x1, y1, cx, cy)
    -- raycast from point 0 to point 1, within camera bounds
    local a=atan2(x1-x0,y1-y0)
    local xi=cos(a)>=0 and 1 or -1
    local yi=sin(a)>=0 and 1 or -1
    local x=x0
    local y=y0
    local p={x0, y0}

    while cx<=p[1] and p[1]<=cx+128 and cy<=p[2] and p[2]<=cy+128 do
        local nv=p[1]+1
        local nh=p[2]+1
        local xd=(nv-x)/cos(a)
        local yd=(nh-y)/sin(a)
        if xd<yd then
            p[1]+=xi
            y+=(sin(a)/cos(a))*(nv-x)
            x=nv
        else
            p[2]+=yi
            x+=(nh-y)/(sin(a)/cos(a))
            y=nh
        end
    end

    return p
end

function within_bounds(x, y)
    return (0 < x) and (x < 128) and (0 < y) and (y < 128)
end
