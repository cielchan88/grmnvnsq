import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Digital watch face for the Venu Sq 2 (320x360 AMOLED).
// Active mode: status row, date, large time, step-goal bar, three stats.
// Always-on (low power): small dim time that shifts every minute to
// satisfy AMOLED burn-in rules (<10% pixels lit, no static pixels).
class GrmnVnsqView extends WatchUi.WatchFace {

    const ACCENT = 0x00AAFF;
    const DIM = 0x555555;

    hidden var _isAwake as Boolean = true;
    hidden var _w as Number = 320;
    hidden var _h as Number = 360;
    hidden var _lblSteps as String = "";
    hidden var _lblHr as String = "";
    hidden var _lblKcal as String = "";

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
        var cx = _w / 2;

        // Status row
        drawConnection(dc, 24, 30, settings.phoneConnected, settings.notificationCount);
        drawBattery(dc, _w - 20, 30);

        // Date
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 78, Graphics.FONT_SMALL, getDateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Time: hours white, minutes accent
        drawTime(dc, cx, 170);

        // Step goal progress bar
        var am = ActivityMonitor.getInfo();
        var steps = (am.steps != null) ? am.steps as Number : 0;
        var goal = (am.stepGoal != null && (am.stepGoal as Number) > 0) ? am.stepGoal as Number : 0;
        drawProgress(dc, 30, 252, _w - 60, 6, steps, goal);

        // Stats row
        var kcal = (am.calories != null) ? (am.calories as Number).toString() : "--";
        var hr = getHeartRate();
        var colW = _w / 3;
        drawStat(dc, colW / 2, 300, steps.toString(), _lblSteps, ACCENT);
        drawStat(dc, cx, 300, (hr != null) ? hr.toString() : "--", _lblHr, Graphics.COLOR_RED);
        drawStat(dc, _w - colW / 2, 300, kcal, _lblKcal, Graphics.COLOR_ORANGE);
    }

    hidden function drawTime(dc as Dc, cx as Number, cy as Number) as Void {
        var parts = getTimeParts();
        var hh = parts[0];
        var mm = parts[1];
        var sep = ":";

        // Use the biggest number font that fits the screen width.
        var font = Graphics.FONT_NUMBER_THAI_HOT;
        var total = dc.getTextWidthInPixels(hh + sep + mm, font);
        if (total > _w - 16) {
            font = Graphics.FONT_NUMBER_HOT;
            total = dc.getTextWidthInPixels(hh + sep + mm, font);
        }

        var x = cx - total / 2;
        var j = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, hh, j);
        x += dc.getTextWidthInPixels(hh, font);

        dc.setColor(DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, sep, j);
        x += dc.getTextWidthInPixels(sep, font);

        dc.setColor(ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, mm, j);
    }

    hidden function drawStat(dc as Dc, x as Number, y as Number, value as String,
                             label as String, color as Number) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, Graphics.FONT_SMALL, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y + 30, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawProgress(dc as Dc, x as Number, y as Number, w as Number, h as Number,
                                 value as Number, goal as Number) as Void {
        dc.setColor(0x222222, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, w, h, h / 2);
        if (goal <= 0 || value <= 0) {
            return;
        }
        var fill = (w * value) / goal;
        if (fill > w) {
            fill = w;
        }
        if (fill < h) {
            fill = h;
        }
        dc.setColor(value >= goal ? Graphics.COLOR_GREEN : ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(x, y, fill, h, h / 2);
    }

    hidden function drawBattery(dc as Dc, right as Number, cy as Number) as Void {
        var pct = System.getSystemStats().battery;
        var bw = 34;
        var bh = 16;
        var left = right - bw - 3;
        var top = cy - bh / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawRoundedRectangle(left, top, bw, bh, 3);
        dc.fillRectangle(left + bw, cy - 4, 3, 8);

        var color = Graphics.COLOR_GREEN;
        if (pct <= 15) {
            color = Graphics.COLOR_RED;
        } else if (pct <= 35) {
            color = Graphics.COLOR_YELLOW;
        }
        var fill = ((bw - 4) * pct / 100).toNumber();
        if (fill > 0) {
            dc.setColor(color, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(left + 2, top + 2, fill, bh - 4);
        }

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left - 6, cy, Graphics.FONT_XTINY, pct.format("%d") + "%",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    hidden function drawConnection(dc as Dc, x as Number, cy as Number,
                                   connected as Boolean, notifs as Number) as Void {
        dc.setColor(connected ? ACCENT : DIM, Graphics.COLOR_TRANSPARENT);
        if (connected) {
            dc.fillCircle(x, cy, 6);
        } else {
            dc.drawCircle(x, cy, 6);
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

        // Shift a few pixels every minute (5x5 grid) for burn-in protection.
        var dx = ((min % 5) - 2) * 10;
        var dy = (((min / 5) % 5) - 2) * 14;
        var cx = _w / 2 + dx;
        var cy = _h / 2 + dy;

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_MEDIUM, parts[0] + ":" + parts[1],
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(DIM, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 50, Graphics.FONT_XTINY, getDateString(),
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

    hidden function getDateString() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        return Lang.format("$1$, $2$ $3$", [info.day_of_week, info.day, info.month]).toUpper();
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
