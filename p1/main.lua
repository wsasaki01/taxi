function _init()
    p = {
        x = 40,
        y = 40,
        d = 0.75,
        v = 0,
        acc = 0.6,
        fr = 0.8
    }
end

function _update60()
    drive = btn(5) or btn(2)
    if drive and btn(0) then p.d-=0.02 end
    if drive and btn(1) then p.d+=0.02 end

    if drive then
        p.v += p.acc
    end

    if btnp(5) then
        p.v += 5
    end

    if p.v != 0 then
        p.v *= p.fr
    end

    p.x+=sin(p.d)*p.v
    p.y+=cos(p.d)*p.v
end

function _draw()
    cls(0)
    map(0, 0, 0, 0)
    camera(p.x-64, p.y-64)
    pset(p.x, p.y, 0)
    pset(p.x+3*sin(p.d), p.y+3*cos(p.d), 7)

    print(p.v, p.x+4, p.y+4, 7)
end
