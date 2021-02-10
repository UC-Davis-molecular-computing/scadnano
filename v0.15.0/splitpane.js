

// The script below constrains the target to move horizontally between a left and a right virtual boundaries.
// - the left limit is positioned at 0% of the screen width
// - the right limit is positioned at 100% of the screen width
var leftLimit = 0;
var rightLimit = 100;

const _LOCAL_STORAGE_PREFIX = "scadnano:";

function setup_split_drag(left_pane_id, right_pane_id, separator_id) {
    var leftPane = document.getElementById(left_pane_id);
    var rightPane = document.getElementById(right_pane_id);
    var paneSep = document.getElementById(separator_id);
    paneSep.sdrag(function (el, pageX, startX, pageY, startY, fix) {

        fix.skipX = true;

        if (pageX < window.innerWidth * leftLimit / 100) {
            pageX = window.innerWidth * leftLimit / 100;
            fix.pageX = pageX;
        }
        if (pageX > window.innerWidth * rightLimit / 100) {
            pageX = window.innerWidth * rightLimit / 100;
            fix.pageX = pageX;
        }

        var cur = pageX / window.innerWidth * 100;
        if (cur < 0) {
            cur = 0;
        }
        if (cur > window.innerWidth) {
            cur = window.innerWidth;
        }

        var right = (100-cur-1);
        leftPane.style.width = cur + '%';
        rightPane.style.width = right + '%';

        var side_pane_width_key = _LOCAL_STORAGE_PREFIX + 'side_pane_width';
        window.localStorage[side_pane_width_key] = leftPane.style.width;

    }, null, 'horizontal');
}

function clear_split_drag(pane_id) {
    var pane = document.getElementById(pane_id);
    // delete pane.style;
    pane.style = "";
    delete pane.style;
}