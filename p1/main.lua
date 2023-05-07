function _init()
    p = {
        x = 40,
        y = 40,
        dir = 0.75, -- direction

        vel = 0, -- velocity
        acc = 0.45, -- acceleration
        fr = 0.8 -- friction
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
end

function _draw()
    cls(0)
    map(0, 0, 0, 0)

    camera(c.x-64, c.y-64)

    pset(p.x, p.y, 12)
    pset(p.x+3*sin(p.dir), p.y+3*cos(p.dir), 7)
end