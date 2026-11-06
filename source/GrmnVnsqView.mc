import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Futuristic HUD watch face for the Venu Sq 2 (320x360 AMOLED).
// Built only from primitives Connect IQ can draw (lines, polygons, text):
// corner brackets, segmented bars, chamfered stat panels, offset "shadow" digits.
// Always-on mode: dim time + date that shift every minute (AMOLED burn-in rules).
class GrmnVnsqView extends WatchUi.WatchFace {

    const CYAN = 0x00E5FF;
    const CYAN_SHADOW = 0x003B47;
    const FRAME = 0x0E5563;
    const SEG_OFF = 0x0F2328;
    const MAGENTA = 0xFF2D95;
    const AMBER = 0xFFB000;
    const NEON_GREEN = 0x39FF88;
    const TEXT_DIM = 0x8FA6AD;

    hidden var _isAwake as Boolean = true;
    hidden var _w as Number = 320;
    hidden var _h as Number = 360;
    hidden var _lblSteps as String = "";
    hidden var _lblHr as String = "";
    hidden var _lblKcal as String = "";
    hidden var _days as Array<String> = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    hidden var _months as Array<String> = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                           "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _lblSteps = WatchUi.loadResource(Rez.Strings.LabelSteps) as String;
        _lblHr = WatchUi.loadResource(Rez.Strings.LabelHr) as String;
        _lblKcal = WatchUi.loadResource(Rez.Strings.LabelKcal) as String;
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();
        if (_isAwake) {
            drawActive(dc);
        } else {
            drawLowPower(dc);
        }
    }

    function onEnterSleep() as Void {
        _isAwake = false;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isAwake = true;
        WatchUi.requestUpdate();
    }

    // ---------------------------------------------------------------- active

    hidden function drawActive(dc as Dc) as Void {
        var settings = System.getDeviceSettings();
        var clock = System.getClockTime();
        var cx = _w / 2;

        // Status row
        drawConnection(dc, 26, 28, settings.phoneConnected, settings.notificationCount);
        drawBattery(dc, _w - 20, 28);

        // Date with HUD side rules
        drawDateRule(dc, cx, 70);

        // Time block inside corner brackets
        drawBrackets(dc, 12, 102, _w - 24, 136, 18, FRAME, 2);
        drawTime(dc, cx, 170);
        dc.setColor(TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_w - 22, 116, Graphics.FONT_XTINY, getMeridiem(clock.hour, settings.is24Hour),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_w - 22, 224, Graphics.FONT_XTINY, clock.sec.format("%02d"),
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        // Segmented step-goal bar
        var am = ActivityMonitor.getInfo();
        var steps = (am.steps != null) ? am.steps as Number : 0;
        var goal = (am.stepGoal != null && (am.stepGoal as Number) > 0) ? am.stepGoal as Number : 0;
        drawSegments(dc, 246, steps, goal);

        // Stat panels
        var kcal = (am.calories != null) ? (am.calories as Number).toString() : "--";
        var hr = getHeartRate();
        var pw = 92;
        var gap = 8;
        var px = (_w - (pw * 3 + gap * 2)) / 2;
        drawPanel(dc, px, 266, pw, 64, steps.toString(), _lblSteps, CYAN);
        drawPanel(dc, px + pw + gap, 266, pw, 64, (hr != null) ? hr.toString() : "--", _lblHr, MAGENTA);
        drawPanel(dc, px + (pw + gap) * 2, 266, pw, 64, kcal, _lblKcal, AMBER);
    }

    hidden function drawTime(dc as Dc, cx as Number, cy as Number) as Void {
        var parts = getTimeParts();
        var hh = parts[0];
        var mm = parts[1];
        var sep = ":";

        // Biggest number font that fits inside the brackets.
        var font = Graphics.FONT_NUMBER_THAI_HOT;
        var total = dc.getTextWidthInPixels(hh + sep + mm, font);
        if (total > _w - 40) {
            font = Graphics.FONT_NUMBER_HOT;
            total = dc.getTextWidthInPixels(hh + sep + mm, font);
        }

        var x = cx - total / 2;
        var xs = x + dc.getTextWidthInPixels(hh, font);
        var xm = xs + dc.getTextWidthInPixels(sep, font);
        var j = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        // Offset shadow layer for depth
        dc.setColor(CYAN_SHADOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + 3, cy + 3, font, hh, j);
        dc.drawText(xm + 3, cy + 3, font, mm, j);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, hh, j);
        dc.setColor(FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xs, cy, font, sep, j);
        dc.setColor(CYAN, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xm, cy, font, mm, j);
    }

    hidden function drawDateRule(dc as Dc, cx as Number, cy as Number) as Void {
        var date = getDateString();
        var font = Graphics.FONT_TINY;
        var half = dc.getTextWidthInPixels(date, font) / 2 + 12;

        dc.setPenWidth(1);
        dc.setColor(FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(24, cy, cx - half, cy);
        dc.drawLine(cx + half, cy, _w - 24, cy);
        dc.setColor(CYAN, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(cx - half - 4, cy - 2, 4, 4);
        dc.fillRectangle(cx + half, cy - 2, 4, 4);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, font, date, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawBrackets(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                                 arm as Number, color as Number, pen as Number) as Void {
        var r = x + w;
        var b = y + h;
        dc.setPenWidth(pen);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x, y, x + arm, y);
        dc.drawLine(x, y, x, y + arm);
        dc.drawLine(r, y, r - arm, y);
        dc.drawLine(r, y, r, y + arm);
        dc.drawLine(x, b, x + arm, b);
        dc.drawLine(x, b, x, b - arm);
        dc.drawLine(r, b, r - arm, b);
        dc.drawLine(r, b, r, b - arm);
        dc.setPenWidth(1);
    }

    hidden function drawSegments(dc as Dc, y as Number, value as Number, goal as Number) as Void {
        var count = 24;
        var segW = 8;
        var gap = 3;
        var total = count * segW + (count - 1) * gap;
        var x = (_w - total) / 2;
        var lit = 0;
        if (goal > 0) {
            lit = (value * count) / goal;
            if (lit > count) {
                lit = count;
            }
        }
        var onColor = (goal > 0 && value >= goal) ? NEON_GREEN : CYAN;
        for (var i = 0; i < count; i++) {
            dc.setColor(i < lit ? onColor : SEG_OFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(x + i * (segW + gap), y, segW, 8);
        }
    }

    hidden function drawPanel(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                              value as String, label as String, color as Number) as Void {
        var c = 10;
        var r = x + w;
        var b = y + h;
        dc.setPenWidth(1);
        dc.setColor(FRAME, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(x + c, y, r, y);
        dc.drawLine(r, y, r, b - c);
        dc.drawLine(r, b - c, r - c, b);
        dc.drawLine(r - c, b, x, b);
        dc.drawLine(x, b, x, y + c);
        dc.drawLine(x, y + c, x + c, y);

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + c + 4, y - 1, 20, 3);
        dc.drawText(x + w / 2, y + 18, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + w / 2, y + 44, Graphics.FONT_SMALL, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawBattery(dc as Dc, right as Number, cy as Number) as Void {
        var pct = System.getSystemStats().battery;
        var segs = 5;
        var segW = 7;
        var gap = 2;
        var total = segs * segW + (segs - 1) * gap;
        var left = right - total;

        var color = CYAN;
        if (pct <= 15) {
            color = MAGENTA;
        } else if (pct <= 35) {
            color = AMBER;
        }
        var lit = ((pct + 19) / 20).toNumber();
        for (var i = 0; i < segs; i++) {
            dc.setColor(i < lit ? color : SEG_OFF, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + i * (segW + gap), cy - 6, segW, 12);
        }

        dc.setColor(TEXT_DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left - 8, cy, Graphics.FONT_XTINY, pct.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawConnection(dc as Dc, x as Number, cy as Number,
                                   connected as Boolean, notifs as Number) as Void {
        var s = 6;
        if (connected) {
            dc.setColor(CYAN, Graphics.COLOR_TRANSPARENT);
            dc.fillPolygon([[x, cy - s], [x + s, cy], [x, cy + s], [x - s, cy]]);
        } else {
            dc.setPenWidth(1);
            dc.setColor(FRAME, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(x, cy - s, x + s, cy);
            dc.drawLine(x + s, cy, x, cy + s);
            dc.drawLine(x, cy + s, x - s, cy);
            dc.drawLine(x - s, cy, x, cy - s);
        }
        if (notifs > 0) {
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x + 14, cy, Graphics.FONT_XTINY, notifs.toString(),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // ------------------------------------------------------------- low power

    hidden function drawLowPower(dc as Dc) as Void {
        var parts = getTimeParts();
        var min = System.getClockTime().min;
        var time = parts[0] + ":" + parts[1];

        // Shift every minute on a 5x5 grid for burn-in protection.
        var dx = ((min % 5) - 2) * 10;
        var dy = (((min / 5) % 5) - 2) * 14;
        var cx = _w / 2 + dx;
        var cy = _h / 2 + dy;

        var font = Graphics.FONT_NUMBER_MEDIUM;
        var bw = dc.getTextWidthInPixels(time, font) + 28;
        drawBrackets(dc, cx - bw / 2, cy - 38, bw, 76, 8, 0x1A4A52, 1);

        dc.setColor(0x2C8C99, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, font, time, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x3A5F66, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 56, Graphics.FONT_XTINY, getDateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // --------------------------------------------------------------- helpers

    hidden function getTimeParts() as Array<String> {
        var clock = System.getClockTime();
        var hour = clock.hour;
        var is24 = System.getDeviceSettings().is24Hour;
        if (!is24) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return [is24 ? hour.format("%02d") : hour.format("%d"), clock.min.format("%02d")];
    }

    hidden function getMeridiem(hour as Number, is24 as Boolean) as String {
        if (is24) {
            return "24H";
        }
        return hour < 12 ? "AM" : "PM";
    }

    // Always English, independent of the device language.
    hidden function getDateString() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow = info.day_of_week as Number;
        var mon = info.month as Number;
        var day = info.day as Number;
        return _days[dow - 1] + "  " + day.format("%02d") + " " + _months[mon - 1];
    }

    hidden function getHeartRate() as Number? {
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            return act.currentHeartRate;
        }
        if (ActivityMonitor has :getHeartRateHistory) {
            var sample = ActivityMonitor.getHeartRateHistory(1, true).next();
            if (sample != null && sample.heartRate != null
                    && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                return sample.heartRate;
            }
        }
        return null;
    }
}
