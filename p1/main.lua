function _init()
    p = {
        x = 40,
        y = 40,
        w = 8,
        h = 8,
        dir = 0.75, -- direction

        vel = 0, -- velocity
        acc = 0.45, -- acceleration
        fr = 0.8, -- friction

        score = 0
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

    coins = {}
    for i=1, 5 do
        add(coins, {rnd(128), rnd(128), true})
    end
end

function _update60()
    drive = btn(5) or btn(2)

    -- change direction
    if drive and btn(0) then p.dir-=0.02 end
    if drive and btn(1) then p.dir+=0.02 end

    -- if driving, accelerate
    if drive then
        p.vel += p.acc
    end

    -- boost with x
    if btnp(5) then
        p.vel += 5
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

    check_collision()
end

function _draw()
    camera(c.x-64, c.y-64)

    cls(0)
    map(0, 0, 0, 0)
    pset(p.x, p.y, 12)
    spr(4, p.x-3, p.y-3)
    pset(p.x+3*sin(p.dir), p.y+3*cos(p.dir), 7)

    draw_coins()

    print(p.score, c.x-64, c.y-64, 7)
end

function draw_coins()
    for coin in all(coins) do
        if coin[3] then
            spr(3, coin[1]-4, coin[2]-4)
        end
    end
end

function check_collision()
    for coin in all(coins) do
        -- if within hitbox, remove coin and add score
        if p.x-0.5*(p.w) < coin[1] and
        p.x+0.5*(p.w) > coin[1] and
        p.y-0.5*(p.h) < coin[2] and
        p.y+0.5*(p.h) > coin[2] then
            coin[3] = false
            p.score += 1
        end
    end
end