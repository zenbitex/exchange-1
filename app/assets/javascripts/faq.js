$(document).ready(function() {
  
  function click_tab(){
    var url = window.location.href; 
    var level = url.substring(url.indexOf('=') + 1, url.indexOf('#')); 

    if (level < '1' || level > '3')
      level = '1';
   
    $("#tab-content1").removeClass("in active");
    $("#tab1").removeClass("active");    
    $("#tab" + level).dblclick();
    $("#tab" + level).addClass("active");
    $("#tab-content" + level).addClass("in active");
  }

  click_tab();

  $('.accordion').find('.accordion-toggle').click(function() {
    $(this).next().slideToggle('600');
    $(".accordion-content").not($(this).next()).slideUp('600');
  });
  $('.accordion-toggle').on('click', function() {
    $(this).toggleClass('active').siblings().removeClass('active');
  });

  $('.faq-category a').click(function () {
      var target = $(this.hash);
      target = target.length ? target : $('[name=' + this.hash.substr(1) + ']');
      if (target.length) {
          scroll_to(target);
      }
  });

  var regex = /#(\w.+)&id=(\w.+)/;
  var params = window.location.hash.match(regex);
  var $target = null ;

  if (params && params[1] != 'undefined') {
    $target = $('[name=' + params[1] + ']');
    scroll_to($target);
    if (params[2] != 'undefined') {
      var $toggle = $target.find('#' + params[2]);
      $toggle.next().slideToggle('600');
    }
  }

  function scroll_to($target){
    $('html,body').animate({
        scrollTop: $target.offset().top - 100
    }, 1000);
    return false;
  }


});
