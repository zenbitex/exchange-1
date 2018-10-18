$(document).ready(function(){
  function getSearchParameters() {
    var prmstr = window.location.search.substr(1);
    return prmstr != null && prmstr != "" ? transformToAssocArray(prmstr) : {};
  }

  function transformToAssocArray( prmstr ) {
    var params = {};
    var prmarr = prmstr.split("&");
    for ( var i = 0; i < prmarr.length; i++) {
        var tmparr = prmarr[i].split("=");
        params[tmparr[0]] = tmparr[1];
    }
    return params;
  }

  function getAsUriParameters(data) {
    var url = '';
    for (var prop in data) {
      url += encodeURIComponent(prop) + '=' + encodeURIComponent(data[prop]) + '&';
    }
    return url.substring(0, url.length - 1);
  }

  function changeLanguage(lang){
    var href = String(window.location.href);
    var anchor = href.indexOf("#") >=0 ? href.substring(href.indexOf("#")) : "";
    var params = getSearchParameters();
    params.lang = lang;
    var urlParameters = $.map(params, function(val,index) {                    
      var str = index + "=" + val;
      return str;
    }).join("&");  
    window.location = "?" + urlParameters;
  }
  $(".select_language").click(function(){
    changeLanguage($(this).attr("data"));
  });
  $('.button-menu-sp').click(function() {
    $('#menu-left').css('left', '100%');
    $('#menu-left').toggleClass('active');
    $("#menu-left.active").animate({left: "0"}, "fast", function() {});
  });
});

