$(document).ready(function(){
	var nav = $('.navbar-fixed-top');
	var scrolled = false;

	$(window).scroll(function () {

	    if (50 < $(window).scrollTop() && !scrolled) {
	        nav.addClass('visible').animate({ top: '0px' });
	        scrolled = true;
	    }

	   if (50 > $(window).scrollTop() && scrolled) {
	        nav.removeClass('visible').css('top', '0px');
	        scrolled = false;
	    }
	});
});
