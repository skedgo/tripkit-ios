$(function(){
	$('a[href*="#"]')
	  // Remove links that don't actually link to anything
	  .not('[href="#"]')
	  .not('[href="#0"]')
	  .click(function(event) {
	    // On-page links
	    if (
	      location.pathname.replace(/^\//, '') == this.pathname.replace(/^\//, '') 
	      && 
	      location.hostname == this.hostname
	    ) {
	      // Figure out element to scroll to
	      var target = $(this.hash);
	      target = target.length ? target : $('[name=' + this.hash.slice(1) + ']');
	      // Does a scroll target exist?
	      if (target.length) {
	        // Only prevent default if animation is actually gonna happen
	        event.preventDefault();
	        $('html, body').animate({
	          scrollTop: target.offset().top
	        }, 500, function() {
	          // Callback after animation
	          // Must change focus!
	          var $target = $(target);
	          $target.focus();
	          if ($target.is(":focus")) { // Checking if the target was focused
	            return false;
	          } else {
	            $target.attr('tabindex','-1'); // Adding tabindex for elements not focusable
	            $target.focus(); // Set focus again
	          };
	        });
	      }
	    }
	  });
	// Keyboard navigation
    document.addEventListener("keydown", function(e) {
        if ($(e.target).is(':input')) return true;
        var key = e.which || e.keyCode || window.event && window.event.keyCode;
        var page;
        switch (key) {
            case 39:   // right arrow
                page = $('[role="navigation"] a:contains(Next):first').prop('href');
                break;
            case 37:   // left arrow
                page = $('[role="navigation"] a:contains(Previous):first').prop('href');
                break;
            // case 83:   // s
            //     e.preventDefault();
            //     $keyboard_modal.modal('hide');
            //     $search_modal.modal('show');
            //     $search_modal.find('#mkdocs-search-query').focus();
            //     break;
            // case 191:  // ?
            //     $keyboard_modal.modal('show');
            //     break;
            default: break;
        }
        if (page) {
            // $keyboard_modal.modal('hide');
            window.location.href = page;
        }
    });

    reloadSideNav();

	$('a.menu-toggle').click(function() {
		$('a.search').toggleClass('hide');
		if (!($(this).hasClass('-toggle'))) {
			$(this).addClass('-toggle');
			$('.menu').addClass('-show').attr('aria-hidden', 'true');
			$('.navbar').addClass('-expanded');

		} else {
			$(this).removeClass('-toggle');
			$('.menu').removeClass('-show').attr('aria-hidden', 'false');
			$('.navbar').removeClass('-expanded');
		}
	});

	$('a.search').click(function(){
		$(this).toggleClass('cross');
		if (!($('.search-form').hasClass('show')))	{
			$('.search-form').addClass('show');
			$('body').addClass('lock');
			$('#mkdocs-search-query').focus();
		} else {
			$('.search-form').removeClass('show');
			$('body').removeClass('lock');
		}
	});
})

$(window).scroll(function(){
	reloadSideNav();
});

function reloadSideNav() {
	var valueMin = 999999999;
	var currentHeight = 0;
	var currentsideitem = '';
	var currentsidebarpos = 0;
	$('.content h1[id]').each(function(){
		var value = Math.abs($(this).offset().top - $(window).scrollTop());
		if ( value < valueMin) {
			valueMin = value;
			var sideitem = 'a[href="#';	
			currentsideitem = sideitem.concat($(this).attr('id').toLowerCase(), '"]');
		}
	});
	$('.content h2[id]').each(function(){
		var value = Math.abs($(this).offset().top - $(window).scrollTop());
		if ( value < valueMin) {
			valueMin = value;
			var sideitem = 'a[href="#';	
			currentsideitem = sideitem.concat($(this).attr('id').toLowerCase(), '"]');
		}
	});
	currentsidebarpos =  Math.abs($(currentsideitem).offset().top - $('.sidebar').offset().top);
	currentHeight = $(currentsideitem).outerHeight();
	$('.sidebar > .indicator').css({'top': currentsidebarpos, 'height': currentHeight});
}