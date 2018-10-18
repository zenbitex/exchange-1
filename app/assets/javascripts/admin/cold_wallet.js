$(document).ready(function() {
  $('#count_fee').click(function(event) {
    var cold_wallet_address = $('#cold_wallet_address').val();
    var cold_wallet_amount = $('#cold_wallet_amount').val();
    var fee = $('#cold_wallet_fee').val();
    var currency = $('#cold_wallet_currency').val();

    if (cold_wallet_address == "") {
      alert("Address must be filled out");
      return false;
    }

    if (cold_wallet_amount == "") {
      alert("Amount must be filled out");
      return false;
    }

    if (fee == "") {
      fee = 0;
    }

    if (currency == 'btc' || currency == 'bch') {
      var data = {
        currency: currency,
        address: cold_wallet_address,
        amount: cold_wallet_amount,
        fee: fee
      }
      $.ajax({
          type: "POST",
          url: "https://bit-trading.online/api/v2/count_fee",
          cache: false,
          data: data,
          dataType: "json",
          success: function(response) {
            alert("Fee must be greater or equal " + response.fee + " " + currency.toUpperCase());
          },
          error: function(err) {
            alert("Invalid address or amount");
          }
      });
    }
  });
});