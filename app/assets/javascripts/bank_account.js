$(document).ready(function() {

  $('#bank_account_account_number').on('input', function() {
    var position = this.selectionStart - 1;    
    fixed = this.value.replace(/[^0-9]/g, ''); 
    
    if (this.value !== fixed) {
      this.value = fixed;
      this.selectionStart = position;
      this.selectionEnd = position;
    }
  });

});