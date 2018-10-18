'use strict';

coinBuySellApp.filter('currencyFormat', function () {
	return function(input, precision){
		return input.toFixed(precision);
	};
});
