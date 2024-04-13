package image

// import "core:log"

Vertex :: [2]u16; // point on the image plane
Position :: [2]Vertex; // start and end point

Line :: struct($PixelDataT: typeid) {
    pos: Position,
    fill: PixelDataT,
}

LineBGR8  :: Line(BGR8);
LineBGR16 :: Line(BGR16);
LineBGR32 :: Line(BGR32);

Oval :: struct($PixelDataT: typeid) {
    pos: Vertex,
    radius: u16,
    fill: PixelDataT,
}

OvalBGR8  :: Oval(BGR8);
OvalBGR16 :: Oval(BGR16);
OvalBGR32 :: Oval(BGR32);

WindingOrder :: enum u8 {
    CLOCKWISE = 0, // default
    ANTICLOCKWISE = 1,
}

Polygon :: struct($PixelDataT: typeid, $N: u8) {
    pos: [N]Vertex,
    fill: PixelDataT,
    face: WindingOrder, 
}

// notably most used polygon types defined here:
TriangleBGR8     :: Polygon(BGR8, 3);
TriangleBGR16    :: Polygon(BGR16, 3);
TriangleBGR32    :: Polygon(BGR32, 3);

TriangleRGBA8    :: Polygon(RGBA8, 3);
TriangleRGBA16   :: Polygon(RGBA16, 3);
TriangleRGBA32   :: Polygon(RGBA32, 3);

RectangleBGR8    :: Polygon(BGR8, 4);
RectangleBGR16   :: Polygon(BGR16, 4);
RectangleBGR32   :: Polygon(BGR32, 4);

RectangleRGBA8   :: Polygon(RGBA8, 4);
RectangleRGBA16  :: Polygon(RGBA16, 4);
RectangleRGBA32  :: Polygon(RGBA32, 4);

HexagonBGR8      :: Polygon(BGR8, 6);
HexagonBGR16     :: Polygon(BGR16, 6);
HexagonBGR32     :: Polygon(BGR32, 6);

HexagonRGBA8     :: Polygon(RGBA8, 6);
HexagonRGBA16    :: Polygon(RGBA16, 6);
HexagonRGBA32    :: Polygon(RGBA32, 6);

insert_line :: proc "contextless" (using img: ^Image2(BGR($PixelDataT)), line: Line(BGR(PixelDataT))) {
    dx, dy := math.abs(line.pos[1].x - line.pos[0].x), math.abs(line.pos[1].y - line.pos[0].y);
    p := 2 * dy - dx;
    x, y, x_end: u16;
    if line.pos[0].x > line.pos[1].x {
        x = line.pos[1].x;
        x_end = line.pos[0].x;
    } 
    else {
        x = line.pos[0].x;
        x_end = line.pos[1].x;
    }

    if line.pos[0].y > line.pos[1].y do y = line.pos[1].y;
    else do y = line.pos[0].y;

    data[y * u16(size.x) + x] = line.fill;

    for x + 1 < x_end {
        x += 1;
        if p < 0 do p = p + 2*dy;
        else {
            y += 1;
            p = p + 2*(dy - dx);
        }
        data[y * u16(size.x) + x] = line.fill;
    }
}

insert_circle :: proc "contextless" (using img: ^Image2(BGR($PixelDataT)), oval: Oval(BGR(PixelDataT))) {
    r := oval.radius;
    r_sq := r * r;
    m, n := oval.pos.x + r, oval.pos.y + r;
    for y in oval.pos.y..<oval.pos.y+2*r {
        for x in oval.pos.x..<oval.pos.x+2*r {
            if ((x - m) * (x - m) + (y- n) * (y - n)) == r_sq {
                img.data[y * u16(img.size.x) + x] = oval.fill;
            }
        }
    }
}

insert_circle_fill :: proc "contextless" (using img: ^Image2(BGR($PixelDataT)), oval: Oval(BGR(PixelDataT))) {
    r := oval.radius;
    r_sq := r * r;
    m, n := oval.pos.x + r, oval.pos.y + r;
    for y in oval.pos.y..<oval.pos.y+2*r {
        for x in oval.pos.x..<oval.pos.x+2*r {
            if ((x - m) * (x - m) + (y- n) * (y - n)) <= r_sq {
                img.data[y * u16(img.size.x) + x] = oval.fill;
            }
        }
    }
}

insert_triangle :: proc "contextless" (using img: ^Image2(BGR($PixelDataT)), triangle: Polygon(PixelDataT, 3)) {
    assert(false, "TODO!");
}