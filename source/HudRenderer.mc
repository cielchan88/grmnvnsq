import Toybox.Graphics;
import Toybox.Lang;

// Stateless drawing helpers for the Crimson HUD face.
// Everything is procedural (lines, polygons, circles) — no bitmaps.
module HudRenderer {

    // Palette: Futuristic Crimson & Neon Orange
    const COLOR_BG = 0x000000;
    const COLOR_CRIMSON_DARK = 0x4A0404;
    const COLOR_CRIMSON = 0xE61919;
    const COLOR_ORANGE_NEON = 0xFF6B00;
    const COLOR_AMBER_GLOW = 0xFFAA00;
    const COLOR_TEXT_SUB = 0xB0B0B0;

    // Chamfered L-bracket. (x, y) is the outer corner point; dirX/dirY (+1 or -1)
    // point the arms toward the screen interior.
    function drawChamferCorner(dc as Dc, x as Number, y as Number, dirX as Number, dirY as Number,
                               arm as Number, chamfer as Number, color as Number, pen as Number) as Void {
        dc.setPenWidth(pen);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y + dirY * arm, x, y + dirY * chamfer);
        dc.drawLine(x, y + dirY * chamfer, x + dirX * chamfer, y);
        dc.drawLine(x + dirX * chamfer, y, x + dirX * arm, y);
        dc.setPenWidth(1);
    }

    // Four chamfered brackets framing a rectangle.
    function drawFrame(dc as Dc, left as Number, top as Number, right as Number, bottom as Number,
                       arm as Number, chamfer as Number, color as Number, accent as Number) as Void {
        drawChamferCorner(dc, left, top, 1, 1, arm, chamfer, color, 2);
        drawChamferCorner(dc, right, top, -1, 1, arm, chamfer, color, 2);
        drawChamferCorner(dc, left, bottom, 1, -1, arm, chamfer, color, 2);
        drawChamferCorner(dc, right, bottom, -1, -1, arm, chamfer, color, 2);

        // Accent ticks at the end of each horizontal arm
        dc.setColor(accent, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(left + arm + 4, top - 1, 6, 3);
        dc.fillRectangle(right - arm - 10, top - 1, 6, 3);
        dc.fillRectangle(left + arm + 4, bottom - 1, 6, 3);
        dc.fillRectangle(right - arm - 10, bottom - 1, 6, 3);
    }

    // Small HUD box with chamfered top-left and bottom-right corners.
    function drawHudBox(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                        c as Number, color as Number) as Void {
        var r = x + w;
        var b = y + h;
        dc.setPenWidth(1);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x + c, y, r, y);
        dc.drawLine(r, y, r, b - c);
        dc.drawLine(r, b - c, r - c, b);
        dc.drawLine(r - c, b, x, b);
        dc.drawLine(x, b, x, y + c);
        dc.drawLine(x, y + c, x + c, y);
    }

    // Thin horizontal sci-fi grid lines.
    function drawGrid(dc as Dc, left as Number, right as Number, top as Number, bottom as Number,
                      step as Number, color as Number) as Void {
        dc.setPenWidth(1);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        for (var y = top; y <= bottom; y += step) {
            dc.drawLine(left, y, right, y);
        }
    }

    // Equalizer-style segmented progress bar. Segments ramp up in height and
    // blend from crimson to neon orange; unlit segments use the dark track color.
    function drawSegmentedBar(dc as Dc, left as Number, right as Number, baseline as Number,
                              minH as Number, maxH as Number, count as Number,
                              value as Number, goal as Number) as Void {
        var gap = 3;
        var segW = ((right - left) - (count - 1) * gap) / count;
        if (segW < 2) {
            segW = 2;
        }
        var total = count * segW + (count - 1) * gap;
        var x = left + ((right - left) - total) / 2;

        var lit = 0;
        if (goal > 0 && value > 0) {
            lit = (value.toLong() * count / goal).toNumber();
            if (lit > count) {
                lit = count;
            }
        }

        for (var i = 0; i < count; i++) {
            var t = (count > 1) ? i.toFloat() / (count - 1) : 1.0;
            var h = minH + ((maxH - minH) * t).toNumber();
            var color = (i < lit) ? lerpColor(COLOR_CRIMSON, COLOR_ORANGE_NEON, t) : COLOR_CRIMSON_DARK;
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + i * (segW + gap), baseline - h, segW, h);
        }
    }

    // Battery: row of small segments.
    function drawBatterySegments(dc as Dc, right as Number, cy as Number, pct as Number?) as Void {
        var segs = 5;
        var segW = 6;
        var segH = 10;
        var gap = 2;
        var total = segs * segW + (segs - 1) * gap;
        var left = right - total;

        var lit = 0;
        var color = COLOR_ORANGE_NEON;
        if (pct != null) {
            lit = (pct + 19) / 20;
            if (pct < 20) {
                color = COLOR_CRIMSON;
            }
        }
        for (var i = 0; i < segs; i++) {
            dc.setColor(i < lit ? color : COLOR_CRIMSON_DARK, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + i * (segW + gap), cy - segH / 2, segW, segH);
        }
        // Terminal nub
        dc.setColor(COLOR_CRIMSON_DARK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(right + 2, cy - 2, 2, 4);
    }

    // ---------------------------------------------------------------- icons

    function drawHeart(dc as Dc, cx as Number, cy as Number, s as Number, color as Number) as Void {
        var r = s / 2;
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx - r, cy - r / 2, r);
        dc.fillCircle(cx + r, cy - r / 2, r);
        dc.fillPolygon([[cx - s, cy - r / 4], [cx + s, cy - r / 4], [cx, cy + s]]);
    }

    function drawFootprints(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillEllipse(cx - 3, cy - 2, 2, 4);
        dc.fillEllipse(cx + 3, cy + 2, 2, 4);
    }

    function drawFlame(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx, cy - 8], [cx + 5, cy], [cx + 4, cy + 5], [cx, cy + 7],
                        [cx - 4, cy + 5], [cx - 5, cy], [cx - 2, cy - 3]]);
    }

    function drawBluetooth(dc as Dc, cx as Number, cy as Number, color as Number) as Void {
        dc.setPenWidth(2);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx, cy - 8, cx, cy + 8);
        dc.drawLine(cx, cy - 8, cx + 5, cy - 4);
        dc.drawLine(cx + 5, cy - 4, cx - 5, cy + 4);
        dc.drawLine(cx, cy + 8, cx + 5, cy + 4);
        dc.drawLine(cx + 5, cy + 4, cx - 5, cy - 4);
        dc.setPenWidth(1);
    }

    function drawEnvelope(dc as Dc, x as Number, cy as Number, color as Number) as Void {
        var w = 14;
        var h = 10;
        var top = cy - h / 2;
        dc.setPenWidth(1);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, top, w, h);
        dc.drawLine(x, top, x + w / 2, top + h / 2);
        dc.drawLine(x + w / 2, top + h / 2, x + w - 1, top);
    }

    // --------------------------------------------------------------- color

    function lerpColor(a as Number, b as Number, t as Float) as Number {
        var ar = (a >> 16) & 0xFF;
        var ag = (a >> 8) & 0xFF;
        var ab = a & 0xFF;
        var br = (b >> 16) & 0xFF;
        var bg = (b >> 8) & 0xFF;
        var bb = b & 0xFF;
        var r = (ar + (br - ar) * t).toNumber();
        var g = (ag + (bg - ag) * t).toNumber();
        var bl = (ab + (bb - ab) * t).toNumber();
        return (r << 16) | (g << 8) | bl;
    }
}
