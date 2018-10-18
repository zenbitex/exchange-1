//= require jquery
//= require jquery_ujs
//= require bootstrap
//= require bootstrap-wysihtml5/b3
//= require bootstrap-datetimepicker
//= require ZeroClipboard
//= require admin/app
//= require admin/flag
//= require qrcode
//= require admin/bank_confirm
//= require admin/go
//= require admin/referral_diagram
//= require admin/cold_wallet

$(document).ready(function(){
  //show QR code cold wallet
  $('.admin-show-qr-code').hide();

  $('.btn-show-qr-code').click(function(){
    $('.admin-show-qr-code').hide();
    var f = $(this).attr('id');
    $('.ad-wallet-qr-code').parent().find('.'+f).show();
  });
  // validate buy-option
  $('.edit-taocoin').on('input',function() {
    var tao = $(this).val();
    if (tao < 0) {
        $(this).val("");
        return false;
      }

      if (tao == '') {
        return false;
      }
  });

  $('.edit-amount').on('input',function() {
    var amount = $(this).val();
    if (amount < 0) {
        $(this).val("");
        return false;
      }

      if (amount == '') {
        return false;
      }
  });

  $('.edit-taocoin').keypress(function(eve) {
    if ((eve.which != 46 || $(this).val().indexOf('.') != -1) && (eve.which < 48 || eve.which > 57) || (eve.which == 46 && $(this).caret().start == 0) ) {
      eve.preventDefault();
    }

  // this part is when left part of number is deleted and leaves a . in the leftmost position. For example, 33.25, then 33 is deleted
   $('.edit-taocoin').keyup(function(eve) {
    if($(this).val().indexOf('.') == 0) {    $(this).val($(this).val().substring(1));
    }
   });
  });

  $('.edit-amount').keypress(function(eve) {
    if ((eve.which != 46 || $(this).val().indexOf('.') != -1) && (eve.which < 48 || eve.which > 57) || (eve.which == 46 && $(this).caret().start == 0) ) {
      eve.preventDefault();
    }
  });

	// this part is when left part of number is deleted and leaves a . in the leftmost position. For example, 33.25, then 33 is deleted
	 $('.edit-amount').keyup(function(eve) {
	  if($(this).val().indexOf('.') == 0) {
      $(this).val($(this).val().substring(1));
	  }
	 });

  $(".btn-download-fee").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start_date=" + $('#date_start').val() + "&end_date=" + $('#date_end').val();
    });
  });

  $(".btn-download-price-report").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_').val() + "&end=" + $('#date_end_').val();
    });
  });

  $(".btn-download-balance-report").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&date_select=" + $('#date_select').val();
    });
  });

  $(".btn-download-trade-fee").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start_fee=" + $('#date_start_fee').val() + "&end_fee=" + $('#date_end_fee').val();
    });
  });

  $(".btn-download-withdraw-history").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_withdraw').val() + "&end=" + $('#date_end_withdraw').val();
    });
  });

  $(".btn-download-deposit-history").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_deposit').val() + "&end=" + $('#date_end_deposit').val();
    });
  });

  $(".btn-download-order-ask").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_order_ask').val() + "&end=" + $('#date_end_order_ask').val();
    });
  });

  $(".btn-download-order-bid").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_order_bid').val() + "&end=" + $('#date_end_order_bid').val();
    });
  });

  $(".btn-download-trade").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_trade').val() + "&end=" + $('#date_end_trade').val();
    });
  });

  $(".btn-download-order-cancel").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&start=" + $('#date_start_order_cancel').val() + "&end=" + $('#date_end_order_cancel').val();
    });
  });

  $("#arb_download").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&date=" + $('#arb_date').val();
    });
  });

  $("#arb_by_month_download").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&date=" + $('#arb_by_month_date').val();
    });
  });

  $("#download-acc-version").click(function () {
    $(this).attr("href", function() {
      return this.href + "?&member_id=" + $('#member_id').text();
    });
  });

  $(".btn-count-order").click(function() {
    $(this).attr("href", function() {
      return this.href + "?&from=" + $('#from_date').val() + "&to=" + $('#to_date').val();
    });
  });
});
