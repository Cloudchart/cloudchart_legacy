// Set caret position easily in jQuery
// Written by and Copyright of Luke Morton, 2011
// Licensed under MIT
(function ($) {
    // Behind the scenes method deals with browser
    // idiosyncrasies and such
    $.caretTo = function (el, index) {
        if (el.createTextRange) { 
            var range = el.createTextRange(); 
            range.move("character", index); 
            range.select(); 
        } else if (el.selectionStart != null) { 
            el.focus(); 
            el.setSelectionRange(index, index); 
        }
    };

    // Another behind the scenes that collects the
    // current caret position for an element

    // TODO: Get working with Opera
    $.caretPos = function (el) {
        if ("selection" in document) {
            var range = el.createTextRange();
            try {
                range.setEndPoint("EndToStart", document.selection.createRange());
            } catch (e) {
                // Catch IE failure here, return 0 like
                // other browsers
                return 0;
            }
            return range.text.length;
        } else if (el.selectionStart != null) {
            return el.selectionStart;
        }
    };

    // The following methods are queued under fx for more
    // flexibility when combining with $.fn.delay() and
    // jQuery effects.

    // Set caret to a particular index
    $.fn.caret = function (index, offset) {
        if (typeof(index) === "undefined") {
            return $.caretPos(this.get(0));
        }

        return this.queue(function (next) {
            if (isNaN(index)) {
                var i = $(this).val().indexOf(index);

                if (offset === true) {
                    i += index.length;
                } else if (typeof(offset) !== "undefined") {
                    i += offset;
                }

                $.caretTo(this, i);
            } else {
                $.caretTo(this, index);
            }

            next();
        });
    };

    // Set caret to beginning of an element
    $.fn.caretToStart = function () {
        return this.caret(0);
    };

    // Set caret to the end of an element
    $.fn.caretToEnd = function () {
        return this.queue(function (next) {
            $.caretTo(this, $(this).val().length);
            next();
        });
    };

    // Get selection
    $.fn.getSelectionStart = function(){
        if(this.lengh == 0) return -1;
        input = this[0];

        var pos = input.value.length;

        if (input.createTextRange) {
            var r = document.selection.createRange().duplicate();
            r.moveEnd('character', input.value.length);
            if (r.text == '') 
            pos = input.value.length;
            pos = input.value.lastIndexOf(r.text);
        } else if(typeof(input.selectionStart)!="undefined")
        pos = input.selectionStart;

        return pos;
    }

    $.fn.getSelectionEnd = function(){
        if(this.lengh == 0) return -1;
        input = this[0];

        var pos = input.value.length;

        if (input.createTextRange) {
            var r = document.selection.createRange().duplicate();
            r.moveStart('character', -input.value.length);
            if (r.text == '') 
            pos = input.value.length;
            pos = input.value.lastIndexOf(r.text);
        } else if(typeof(input.selectionEnd)!="undefined")
            pos = input.selectionEnd;

            return pos;
    }

    $.fn.caretSelection = function(){
        if(this.lengh == 0) return -1;
        var s = $(this).getSelectionStart();
        var e = $(this).getSelectionEnd();
        return this[0].value.substring(s,e);
    }
    
    $.fn.setCaretSelection = function(selectionStart, selectionEnd) {
        if(this.lengh == 0) return this;
        input = this[0];

        if (input.createTextRange) {
            var range = input.createTextRange();
            range.collapse(true);
            range.moveEnd('character', selectionEnd);
            range.moveStart('character', selectionStart);
            range.select();
        } else if (input.setSelectionRange) {
            input.focus();
            input.setSelectionRange(selectionStart, selectionEnd);
        }

        return this;
    }

    // Get a current line number for actual caret position
    $.fn.caretLine = function () {
        var lines = $(this).val().substr(0, $.caretPos(this.get(0))).match(/\n/g);
        return (lines === null ? 1 : lines.length + 1);
    }
}(jQuery));