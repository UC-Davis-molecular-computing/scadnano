

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
    var parent = leftPane.parentElement;
    console.log("leftPane.id: " + leftPane.id + " rightPane.id: " + rightPane.id + " separator_id: " + separator_id);
    console.log("parent: " + parent.id + " parent.offsetWidth: " + parent.offsetWidth);
    paneSep.sdrag(function (el, pageX, startX, pageY, startY, fix) {

        fix.skipX = true;

        if (pageX < parent.offsetWidth * leftLimit / 100) {
            pageX = parent.offsetWidth * leftLimit / 100;
            fix.pageX = pageX;
        }
        if (pageX > parent.offsetWidth * rightLimit / 100) {
            pageX = parent.offsetWidth * rightLimit / 100;
            fix.pageX = pageX;
        }

        var cur = pageX / parent.offsetWidth * 100;
        if (cur < 0) {
            cur = 0;
        }
        if (cur > parent.offsetWidth) {
            cur = parent.offsetWidth;
        }

        var right = (100-cur-1);
        leftPane.style.width = cur + '%';
        rightPane.style.width = right + '%';

        var left_pane_width_key = _LOCAL_STORAGE_PREFIX + left_pane_id +'-width';
        window.localStorage[left_pane_width_key] = leftPane.style.width;

        console.log(leftPane.id + " width: " + leftPane.style.width + "; " + rightPane.id + " width: " + rightPane.style.width);

    }, null, 'horizontal');
}

function clear_split_drag(pane_id) {
    var pane = document.getElementById(pane_id);
    // delete pane.style;
    pane.style = "";
    delete pane.style;
}