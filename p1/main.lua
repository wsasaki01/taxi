function _init()
    p = {
        x = 40,
        y = 40,
        d = 0.75
    }
end

function _update60()
    if btn(0) then p.d-=0.02 end
    if btn(1) then p.d+=0.02 end

    if btn(5) then
        p.x+=sin(p.d)
        p.y+=cos(p.d)
    end
end

function _draw()
    cls(3)
    map(0, 0, 0, 0)
    camera(p.x-64, p.y-64)
    pset(p.x, p.y, 0)
    pset(p.x+3*sin(p.d), p.y+3*cos(p.d), 7)
end
