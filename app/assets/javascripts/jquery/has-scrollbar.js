(function($) {
    $.fn.hasScrollBar = function() {
        return this.get(0).scrollHeight > this.innerHeight() || this.get(0).scrollWidth > this.innerWidth();
    }
})(jQuery);
