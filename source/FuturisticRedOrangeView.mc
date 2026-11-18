import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;

// Crimson HUD — futuristic red/orange watch face for Venu Sq 2 (320x360 AMOLED).
//
// Layout (y ranges):
//   header 22-55 · time 85-195 · step gauge 205-255 · telemetry 265-335
// Every element keeps >= 16 px from the screen edge (rounded bezel).
// Sleep / always-on: minimal dim time + thin battery bar, shifted every minute.
class FuturisticRedOrangeView extends WatchUi.WatchFace {

    const MARGIN = 16;

    hidden var isSleeping as Boolean = false;
    hidden var _w as Number = 320;
    hidden var _h as Number = 360;

    hidden var _lblHr as String = "BPM";
    hidden var _lblSteps as String = "STEPS";
    hidden var _lblKcal as String = "KCAL";
    hidden var _lblGoal as String = "STEP GOAL";
    hidden var _lblSec as String = "SEC";

    hidden var _days as Array<String> = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"];
    hidden var _months as Array<String> = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                                           "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        _w = dc.getWidth();
        _h = dc.getHeight();
        _lblHr = WatchUi.loadResource(Rez.Strings.LabelHr) as String;
        _lblSteps = WatchUi.loadResource(Rez.Strings.LabelSteps) as String;
        _lblKcal = WatchUi.loadResource(Rez.Strings.LabelKcal) as String;
        _lblGoal = WatchUi.loadResource(Rez.Strings.LabelGoal) as String;
        _lblSec = WatchUi.loadResource(Rez.Strings.LabelSec) as String;
    }

    function onUpdate(dc as Dc) as Void {
        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }
        dc.setColor(HudRenderer.COLOR_BG, HudRenderer.COLOR_BG);
        dc.clear();

        if (isSleeping) {
            drawLowPower(dc);
        } else {
            drawActive(dc);
        }
    }

    function onEnterSleep() as Void {
        isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        isSleeping = false;
        WatchUi.requestUpdate();
    }

    // ================================================================ active

    hidden function drawActive(dc as Dc) as Void {
        var left = MARGIN;
        var right = _w - MARGIN;

        // Background layer: grid + cybernetic corner frame
        HudRenderer.drawGrid(dc, left + 8, right - 8, 88, 196, 12, HudRenderer.COLOR_CRIMSON_DARK);
        HudRenderer.drawFrame(dc, left, MARGIN, right, _h - MARGIN, 46, 12,
            HudRenderer.COLOR_CRIMSON, HudRenderer.COLOR_ORANGE_NEON);

        drawHeader(dc);
        drawTime(dc);
        drawStepGauge(dc);
        drawTelemetry(dc);
    }

    // ---------------------------------------------------------------- header

    hidden function drawHeader(dc as Dc) as Void {
        var cy = 38;
        var settings = System.getDeviceSettings();
        var connected = false;
        var notifs = 0;
        if (settings != null) {
            connected = settings.phoneConnected == true;
            if (settings.notificationCount != null) {
                notifs = settings.notificationCount;
            }
        }

        // Left: bluetooth + notifications
        HudRenderer.drawBluetooth(dc, 34, cy,
            connected ? HudRenderer.COLOR_CRIMSON : HudRenderer.COLOR_CRIMSON_DARK);
        var envColor = (notifs > 0) ? HudRenderer.COLOR_ORANGE_NEON : HudRenderer.COLOR_CRIMSON_DARK;
        HudRenderer.drawEnvelope(dc, 48, cy, envColor);
        if (notifs > 0) {
            dc.setColor(HudRenderer.COLOR_ORANGE_NEON, Graphics.COLOR_TRANSPARENT);
            dc.drawText(66, cy, Graphics.FONT_XTINY, notifs > 9 ? "9+" : notifs.toString(),
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }

        // Center: date
        dc.setColor(HudRenderer.COLOR_ORANGE_NEON, Graphics.COLOR_TRANSPARENT);
        dc.drawText(_w / 2, cy, Graphics.FONT_TINY, getDateString(),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Right: battery segments (top) + percentage (below)
        var pct = getBatteryPct();
        var right = _w - MARGIN - 14;
        HudRenderer.drawBatterySegments(dc, right, cy - 7, pct);
        var pctColor = (pct != null && pct < 20) ? HudRenderer.COLOR_CRIMSON : HudRenderer.COLOR_TEXT_SUB;
        dc.setColor(pctColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(right + 4, cy + 10, Graphics.FONT_XTINY, (pct != null) ? pct.toString() + "%" : "--%",
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ------------------------------------------------------------------ time

    hidden function drawTime(dc as Dc) as Void {
        var parts = getTimeParts();
        var hh = parts[0];
        var mm = parts[1];
        var sep = ":";
        var cy = 136;

        // Seconds box on the right; the time is centered in the space left of it.
        var boxW = 40;
        var boxH = 34;
        var boxX = _w - MARGIN - 8 - boxW;
        var areaL = MARGIN + 8;
        var areaR = boxX - 8;

        var fonts = [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT, Graphics.FONT_NUMBER_MEDIUM];
        var font = fonts[fonts.size() - 1];
        for (var i = 0; i < fonts.size(); i++) {
            if (dc.getTextWidthInPixels(hh + sep + mm, fonts[i]) <= areaR - areaL) {
                font = fonts[i];
                break;
            }
        }

        var wH = dc.getTextWidthInPixels(hh, font);
        var wS = dc.getTextWidthInPixels(sep, font);
        var total = wH + wS + dc.getTextWidthInPixels(mm, font);
        var x = (areaL + areaR) / 2 - total / 2;
        var xm = x + wH + wS;
        var j = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;

        // Layered halo (fake glow): dark crimson copies offset in 4 directions
        dc.setColor(HudRenderer.COLOR_CRIMSON_DARK, Graphics.COLOR_TRANSPARENT);
        var offs = [[-2, 0], [2, 0], [0, -2], [0, 2]];
        for (var k = 0; k < offs.size(); k++) {
            var o = offs[k];
            dc.drawText(x + o[0], cy + o[1], font, hh, j);
            dc.drawText(xm + o[0], cy + o[1], font, mm, j);
        }

        dc.setColor(HudRenderer.COLOR_AMBER_GLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, cy, font, hh, j);
        dc.setColor(HudRenderer.COLOR_CRIMSON, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x + wH, cy, font, sep, j);
        dc.setColor(HudRenderer.COLOR_ORANGE_NEON, Graphics.COLOR_TRANSPARENT);
        dc.drawText(xm, cy, font, mm, j);

        // Neon underline under the hours, thin crimson rail under the rest
        var uy = cy + (dc.getFontHeight(font) * 0.40).toNumber();
        if (uy > 192) {
            uy = 192;
        }
        dc.setColor(HudRenderer.COLOR_ORANGE_NEON, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, uy, wH, 3);
        dc.setColor(HudRenderer.COLOR_CRIMSON_DARK, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x + wH + 4, uy + 1, total - wH - 4, 1);

        // Seconds HUD box (active mode only — never drawn while sleeping)
        var boxY = cy - boxH / 2;
        dc.setColor(HudRenderer.COLOR_TEXT_SUB, Graphics.COLOR_TRANSPARENT);
        dc.drawText(boxX + boxW / 2, boxY - 12, Graphics.FONT_XTINY, _lblSec,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        HudRenderer.drawHudBox(dc, boxX, boxY, boxW, boxH, 6, HudRenderer.COLOR_CRIMSON);
        dc.setColor(HudRenderer.COLOR_CRIMSON, Graphics.COLOR_TRANSPARENT);
        dc.drawText(boxX + boxW / 2, cy, Graphics.FONT_TINY, System.getClockTime().sec.format("%02d"),
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ------------------------------------------------------------ step gauge

    hidden function drawStepGauge(dc as Dc) as Void {
        var steps = getSteps();
        var goal = getStepGoal();
        var left = MARGIN + 8;
        var right = _w - MARGIN - 8;

        dc.setColor(HudRenderer.COLOR_TEXT_SUB, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, 214, Graphics.FONT_XTINY, _lblGoal,
            Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);

        var pctText = "--%";
        if (steps != null && goal != null && goal > 0) {
            pctText = (steps.toLong() * 100 / goal).toString() + "%";
        }
        dc.setColor(HudRenderer.COLOR_ORANGE_NEON, Graphics.COLOR_TRANSPARENT);
        dc.drawText(right, 214, Graphics.FONT_XTINY, pctText,
            Graphics.TEXT_JUSTIFY_RIGHT | Graphics.TEXT_JUSTIFY_VCENTER);

        HudRenderer.drawSegmentedBar(dc, left, right, 253, 8, 24, 24,
            (steps != null) ? steps : 0, (goal != null) ? goal : 0);
    }

    // ------------------------------------------------------------- telemetry

    hidden function drawTelemetry(dc as Dc) as Void {
        var left = MARGIN;
        var colW = (_w - 2 * MARGIN) / 3;
        var top = 265;
        var bottom = 335;

        dc.setPenWidth(1);
        dc.setColor(HudRenderer.COLOR_CRIMSON_DARK, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(left + colW, top + 4, left + colW, bottom - 4);
        dc.drawLine(left + colW * 2, top + 4, left + colW * 2, bottom - 4);

        var hr = getHeartRate();
        var steps = getSteps();
        var kcal = getCalories();

        drawCard(dc, left + colW / 2, :heart, _lblHr,
            (hr != null) ? hr.toString() : "--", HudRenderer.COLOR_CRIMSON);
        drawCard(dc, left + colW + colW / 2, :steps, _lblSteps,
            (steps != null) ? steps.toString() : "--", HudRenderer.COLOR_ORANGE_NEON);
        drawCard(dc, left + colW * 2 + colW / 2, :flame, _lblKcal,
            (kcal != null) ? kcal.toString() : "--", HudRenderer.COLOR_AMBER_GLOW);
    }

    hidden function drawCard(dc as Dc, cx as Number, icon as Symbol, label as String,
                             value as String, color as Number) as Void {
        var labelY = 282;
        var lw = dc.getTextWidthInPixels(label, Graphics.FONT_XTINY);
        var iconX = cx - lw / 2 - 6;
        var textX = cx + 8;

        if (icon == :heart) {
            HudRenderer.drawHeart(dc, iconX, labelY, 7, color);
        } else if (icon == :steps) {
            HudRenderer.drawFootprints(dc, iconX, labelY, color);
        } else {
            HudRenderer.drawFlame(dc, iconX, labelY, color);
        }

        dc.setColor(HudRenderer.COLOR_TEXT_SUB, Graphics.COLOR_TRANSPARENT);
        dc.drawText(textX, labelY, Graphics.FONT_XTINY, label,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Drop to a smaller font when the value would spill out of its column
        var colW = (_w - 2 * MARGIN) / 3;
        var font = Graphics.FONT_MEDIUM;
        if (dc.getTextWidthInPixels(value, font) > colW - 10) {
            font = Graphics.FONT_SMALL;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, 314, font, value,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ============================================================= low power

    hidden function drawLowPower(dc as Dc) as Void {
        var parts = getTimeParts();
        var time = parts[0] + ":" + parts[1];
        var min = System.getClockTime().min;

        // Shift every minute on a 5x5 grid so no pixel stays lit (burn-in).
        var dx = ((min % 5) - 2) * 10;
        var dy = (((min / 5) % 5) - 2) * 14;
        var cx = _w / 2 + dx;
        var cy = _h / 2 + dy - 10;

        // Dim amber time, no glow, no seconds, no decoration
        dc.setColor(0x8A5200, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy, Graphics.FONT_NUMBER_MEDIUM, time,
            Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Thin battery bar
        var barW = 60;
        var barX = cx - barW / 2;
        var barY = cy + 44;
        dc.setColor(0x2A0202, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(barX, barY, barW, 2);
        var pct = getBatteryPct();
        if (pct != null && pct > 0) {
            var fill = barW * pct / 100;
            dc.setColor(pct < 20 ? 0x7A0E0E : 0x7A3500, Graphics.COLOR_TRANSPARENT);
            dc.fillRectangle(barX, barY, fill, 2);
        }
    }

    // =============================================================== helpers

    hidden function getTimeParts() as Array<String> {
        var clock = System.getClockTime();
        var hour = clock.hour;
        var settings = System.getDeviceSettings();
        var is24 = (settings == null) || settings.is24Hour;
        if (!is24) {
            hour = hour % 12;
            if (hour == 0) {
                hour = 12;
            }
        }
        return [is24 ? hour.format("%02d") : hour.format("%d"), clock.min.format("%02d")];
    }

    hidden function getDateString() as String {
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dow = info.day_of_week as Number;
        var mon = info.month as Number;
        var day = info.day as Number;
        if (dow < 1 || dow > 7 || mon < 1 || mon > 12) {
            return "";
        }
        return _days[dow - 1] + " " + day.format("%02d") + " " + _months[mon - 1];
    }

    hidden function getBatteryPct() as Number? {
        var stats = System.getSystemStats();
        if (stats == null || stats.battery == null) {
            return null;
        }
        var pct = stats.battery.toNumber();
        if (pct < 0) {
            pct = 0;
        } else if (pct > 100) {
            pct = 100;
        }
        return pct;
    }

    hidden function getMonitorInfo() as ActivityMonitor.Info? {
        return ActivityMonitor.getInfo();
    }

    hidden function getSteps() as Number? {
        var info = getMonitorInfo();
        return (info != null) ? info.steps : null;
    }

    hidden function getStepGoal() as Number? {
        var info = getMonitorInfo();
        return (info != null) ? info.stepGoal : null;
    }

    hidden function getCalories() as Number? {
        var info = getMonitorInfo();
        return (info != null) ? info.calories : null;
    }

    hidden function getHeartRate() as Number? {
        var act = Activity.getActivityInfo();
        if (act != null && act.currentHeartRate != null) {
            return act.currentHeartRate;
        }
        if (ActivityMonitor has :getHeartRateHistory) {
            var history = ActivityMonitor.getHeartRateHistory(1, true);
            if (history != null) {
                var sample = history.next();
                if (sample != null && sample.heartRate != null
                        && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    return sample.heartRate;
                }
            }
        }
        return null;
    }
}
