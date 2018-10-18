$(document).ready(function() {
  function isEmpty(){
    var tab_current = $(".tab-pane.active form");
    var input_list = tab_current.find(".form-input input[type='text']");
    var file_list = tab_current.find(".form-input input[type='file']");
    var radio_list = tab_current.find(".radio .block-wrapper");
    var select_list = tab_current.find(".form-input select");
    var text_list = tab_current.find(".form-input textarea");
    var is_empty = false;
    is_croll = false;
    var empty_message = I18n.t('id_documents.errors.empty');
    $(".form-error").remove();
    input_list.each(function(index, element)
    {
      if($(element).val() == "")
      {
        is_empty = true;
        addError($(element).parent(), empty_message);
      }
    });
    text_list.each(function(index, element)
    {
      if($(element).val() == "")
      {
        is_empty = true;
        addError($(element).parent(), empty_message);
      }
    });
    select_list.each(function(index, element)
    {
      if($(element).val() == "")
      {
        is_empty = true;
        addError($(element).parent(), empty_message);
      }
    });

    file_list.each(function(index, element)
    {
      gallery = $(element).parents(".gallery");
      if($(element).val() == "" && gallery.attr("data") != "true" && gallery.is(":visible") == true)
      {
        is_empty = true;
        addError($(element).parents(".gallery"), empty_message);
      }
    });

    radio_list.each(function(index, element)
    {
      if($(element).find("input").is(":checked") == false)
      {
        is_empty = true;
        addError($(element).parent(), empty_message);
      }
    });
    return is_empty;
  }
  function addError(parent, message){
    parent.find(".form-error").remove();
    var error = $("<span>", {"text" : message, "class": "form-error", "style" : "padding-left: 0;"});
    parent.append(error);
    error.hide();
    error.fadeIn(300);
    parent.on("click keypress", function()
    {
      error.fadeOut(300);
    });
    if (!is_croll)
    {
      $('html, body').animate({
        scrollTop: parent.offset().top - 200,
        scrollLeft: 0
      });
      is_croll = true;
      parent.find("input").focus();
    }
  }
  var imagesPreview = function(input) {
    if (input.files) {
      var filesAmount = input.files.length;
      if( filesAmount == 0 ) return false;
      var reader = new FileReader();
      var gallery = $(input).parents(".gallery");
      gallery.find("img").remove();

      var maxExceededMessage = "This file exceeds the maximum allowed file size (5 MB)";
      var extErrorMessage = "Only image file with extension: jpg, jpeg, gif, png or pdf is allowed";
      var allowedExtension = ['jpg', 'jpeg', 'png', 'pdf', 'gif', 'JPG', 'JPEG', 'PNG', 'PDF', 'GIF'];

      var extName;
      var maxFileSize = 5 * 1024 * 1024;
      var sizeExceeded = false;
      var extError = false;
      var file = input.files[0];
      is_croll = false;
      if (file.size > maxFileSize) {
        sizeExceeded = true;
      };
      extName = file.name.split('.').pop();
      if ($.inArray(extName, allowedExtension) == -1) {
        extError = true;
      };

      if (sizeExceeded) {
        addError(gallery, maxExceededMessage);
        gallery.find(".form-error").show();
        $(input).val('');
        return 0;
      };

      if (extError) {
        addError(gallery, extErrorMessage);
        $(input).val('');
        return 0;
      };

      var imageView = $("<img>");
      reader.onload = function (e) {
        imageView.attr('src', e.target.result);
      }
      imageView.attr('data', "change");
      reader.readAsDataURL(file);
      gallery.append(imageView);
    }
  };
  function checkDocumentType()
  {
    var document_type = $(".tab-pane.active .id_document_id_document_type .form-input");
    is_croll = false;
    if (document_type.find("select option:selected").attr("value") == ""){
      addError(document_type, I18n.t('id_documents.errors.document_type_empty'));
      return false;
    }
    else return true;
  }

  var allowedExtension = "image/gif, image/jpg, image/jpeg, image/png, .pdf";
  $(".tab-pane .form-input input[type='file']").attr("accept", allowedExtension);

  var file = $('.form-input input.file');
  file.on('change', function() {
    imagesPreview(this);
  });

  function openFile(element, event){
    if ($(event.target).is(element) || $(event.target).prop("tagName") == "IMG")
    {
      var input = $(element).parent().find(".form-input input");
      if (input.parents(".document_file").length != 0 && !checkDocumentType())
      {
        return;
      }
      $(element).parent().find(".form-input input").click();
    }
  }

  $('.btn-file-upload').click(function(event){
    openFile(this, event);
  });

  $('.gallery').click(function(event) {
    openFile(this, event);
  });

  $('.input-foreign.radio .radio_buttons').removeClass('form-control');
  $('.document_submit').click(function(event) {
      event.preventDefault();
      var tab_current = $(".tab-pane.active form");
      if (!isEmpty())
        tab_current.submit();
  });

  $(".foreign label").click(function(event){
    var input = $(this).find("input");
    if ($(event.target).is(input))
      return;
    input.click();
  });

  getListImage();

  function getListImage()
  {
    types = ['IdDocumentInfor', 'IdDocumentFile', 'IdDocumentTrade']
    document_list = ['document_infor', 'document_file', 'document_trade']
    document_file_images = [];
    for (index = 0; index < 3; index++)
    {
      file = $("." + types[index]);
      for (index1 = 1; index1 <= file.length; index1++)
      {
        gallery = $("." + document_list[index] + " .gallery.file" + index1)
        gallery.attr("data", true);
        img_tag = $("img." + types[index] + ".file" + index1);
        gallery.append(img_tag);
        if (index == 1)
        {
          document_file_images.push(img_tag.attr("src"));
        }
      }
    }
  }

  function documentTypeChange(selectUploadType){
    var images = [null, null, null];
    var select_document = selectUploadType.val();
    var parent = selectUploadType.parents(".document_file");
    for (index = 0; index < document_file_images.length; index++)
    {
       if (document_file_images[index] != null)
      {
        parent.find(".gallery.file" + (index + 1)).attr("data", true);
        images[index] = document_file_images[index];
      }
      else 
        images[index] = null;
    }
    gallery = parent.find('.gallery');
    gallery.find('img').remove();

    parent.find('.image_upload1').first().removeClass("image_full");
    parent.find('.image_upload2').show();
    parent.find('.image_upload3').hide();
    parent.find('.image_upload4').hide();

    if(select_document == 'driver_license') {
      if(images[0] == null)
        images[0] = "/id-document/driver1.png";
      if(images[1] == null)
        images[1] = "/id-document/driver2.png";
    }
    else if(select_document == 'id_card') {
      if(images[0] == null)
        images[0] = "/id-document/id-card1.png";
      if(images[1] == null)
        images[1] = "/id-document/id-card2.png";
    }
    else if(select_document == 'passport') {
      if(images[0] == null)
        images[0] = "/id-document/passport1.png";
      if(images[1] == null)
        images[1] = "/id-document/passport2.png";
      if(images[2] == null)
        images[2] = "/id-document/passport3.png";
      parent.find('.image_upload3').show();
      parent.find('.image_upload4').show();
    } 
    else if(select_document == 'seal_certificate') {
      parent.find('.image_upload2').hide();
      parent.find('.image_upload1').first().addClass("image_full");
    } 
    gallery.each(function(index, element){
      if (images[index] != null)
      {
        var image_view = $('<img src= ' + images[index]  + '>');
        $(element).append(image_view);
        $(element).find(".form-error").remove();
      }
    });
  }

  $('.select-upload-type').on('change', function() {
    documentTypeChange($(this));
  });

  documentTypeChange($('#user .select-upload-type'));
  documentTypeChange($('#staff .select-upload-type'));

  if($(".document_submit").length == 0 && $("#foreign_state").val()){
    $(".tab-pane input").attr("disabled", "true");
    $(".tab-pane textarea").attr("disabled", "true");
    $(".tab-pane select").attr("disabled", "true");
  }

  function addBirthLabel(birth_date_class)
  {
    var formBirthday = $(".birth_date .form-input");
    var formLabel = $(".birth_date .form-label label");
    if(formLabel.text().indexOf("生年月日") >= 0){
      var optionMonth = formBirthday.find("select:eq(-2)").find("option");
      var labelDay = $("<label>", {"text" : '日'});
      var labelMonth = $("<label>", {"text" : '月'});
      var labelYear = $("<label>", {"text" : '年'});

      optionMonth.each(function(index){
        $(this).text((index  % 12) + 1);
      });
      labelDay.insertAfter(formBirthday.find("select:eq(-1)"));
      labelMonth.insertAfter(formBirthday.find("select:eq(-2)"));
      labelYear.insertAfter(formBirthday.find("select:eq(-3)"));
    }
    else formBirthday.addClass("english_birthday");
  }
  addBirthLabel();
  if ($("#user_type").attr("data") == "1"){
    $("#staff_tab").click();
  }

  if ($("#id_document_select").offset() != undefined || $(".flash-message").text() != ""){
     $('html, body').animate({
      scrollTop: $('.flash-message').offset().top - 55
    }, 1);
  }

  if ($("#is_empty").attr("data") == "true") {
    isEmpty();
  }
})

