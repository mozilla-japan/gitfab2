#= require fancybox

editor = null

setupEditor = ->
  editor = new nicEditor {
    buttonList: ["material", "tool", "blueprint", "attachment", "ol", "ul", "bold", "italic", "underline"]
  }
  editor.panelInstance "markup-area"
  $(".nicEdit-main").addClass "validate"

descriptionText = () ->
  for instance in editor.nicInstances
    html_text = instance.getContent()
    plain_text = html_text.replace /<("[^"]*"|'[^']*'|[^'">])*>/g, ''
    return plain_text

validateForm = (event, is_note_card_form) ->
  unless is_note_card_form
    if descriptionText().length > 300
      alert "Description text should be less than 300."
      event.preventDefault()

  validated = false
  $(".card-form:first-child .validate").each (index, element) ->
    if $(element).val() != "" || $(element).text() != ""
      validated = true
  unless validated
    alert "You cannot make empty card."
    event.preventDefault()

focusOnTitle = () ->
  $(".card-title").first().focus()

$ ->
  $.rails.ajax = (option) ->
    option.xhr =  ->
      xhr = $.ajaxSettings.xhr();
      form = $("form[action='" + option.url + "']")
      if form and xhr.upload
        xhr.upload.addEventListener "progress", (e) ->
          form.trigger "ajax:progress", [e]
      xhr
    $.ajax(option)

  formContainer = $ document.createElement("div")
  formContainer.attr "id", "card-form-container"
  formContainer.appendTo document.body

  cards_top = []

  getCardsTop = ->
    cards_top = []
    cards = $ "#making-list .state"
    #11 TODO: Show annotations index of focused status
    cards_top.push card.offsetTop for card in cards
  getCardsTop()

  reloadRecipeCardsList = ->
    owner_id = $("#recipes-show").data "owner"
    project_id = $("#recipes-show").data "project"
    recipe_cards_index_url = "/users/"+ owner_id + "/projects/" + project_id + "/recipe_cards_list"
    $.ajax
      type: "GET",
      url: recipe_cards_index_url,
      dataType: "json",
      success: (data) ->
        $("#recipe-cards-list").replaceWith data.html
        scrollTop = $(window).scrollTop()
        setSelectorPosition i for card_top, i in cards_top when scrollTop >= card_top
      ,
      error: (data) ->
        console.alert data.message

  setSelectorPosition = (n) ->
    link_height_in_card_index = 15
    $("#recipe-cards-list .selector").css "margin-top", (n * link_height_in_card_index + 1) + "px"

  $(window).on "load scroll resize", (event) ->
    scrollTop = $(window).scrollTop()
    setSelectorPosition i for card_top, i in cards_top when scrollTop >= card_top
    #11 TODO: Show annotations index of focused status

  $(document).on "ajax:beforeSend", ".delete-card", ->
    confirm "Are you sure to remove this item?"

  $(document).on "ajax:error", ".new-card, .edit-card, .delete-card", (event, xhr, status, error) ->
    alert error.message
    event.preventDefault()

  $(document).on "click", ".card-form .submit", (event) ->
    is_note_card_form = $(this).closest("form").attr("id").match new RegExp("note_card", "g")
    validateForm event, is_note_card_form

  $(document).on "submit", ".card-form", ->
    submitButton = $(this).find ".submit"
    .off()
    .fadeTo 80, 0.01
    $.fancybox.close()

  $(document).on "ajax:beforeSend", ".new-card, .edit-card", $.fancybox.showLoading

  $(document).on "ajax:success", ".new-card", (xhr, data) ->
    link = $ this
    list = $(link.attr "data-list")
    template = $(link.attr("data-template") + " > :first")
    className  = link.attr "data-classname"
    li = $ document.createElement("li")
    li.addClass "card-wrapper"
    li.addClass className
    card = null
    formContainer.html data.html
    setupEditor()
    setTimeout focusOnTitle, 1
    formContainer.find "form"
    .bind "submit", (e) ->
      card = template.clone()
      wait4save $(this), card
      li.append card
      list.append li
    .bind "ajax:success", (xhr, data) ->
      updateCard card, data
      fixCommentFormAction li if li.hasClass "state-wrapper"
    .bind "ajax:error", (xhr, status, error) ->
      li.remove()
      alert status

  $(document).on "ajax:success", ".edit-card", (xhr, data) ->
    link = $ this
    list = $(link.attr "data-list")
    li = $(this).closest "li"
    card = $(li).children().first()
    formContainer.html data.html
    setupEditor()
    setTimeout focusOnTitle, 1
    formContainer.find "form"
    .bind "submit", (e) ->
      wait4save $(this), card
    .bind "ajax:success", (xhr, data) ->
      updateCard card, data
      fixCommentFormAction li if li.hasClass "state-wrapper"
    .bind "ajax:error", (e, xhr, status, error) ->
      alert status

  $(document).on "ajax:success", ".new-card, .edit-card", ->
    $.fancybox.open
      padding: 0
      href: "#card-form-container"
      helpers:
        overlay:
          closeClick: false

  $(document).on "ajax:success", ".delete-card", (xhr, data) ->
    link = $ this
    li = link.closest "li"
    list = li.parent()
    li.remove()
    checkStateConvertiblity()
    setStateIndex()
    markup()
    setTimeout getCardsTop, 100
    reloadRecipeCardsList()

  $(document).on "click", ".cancel-btn", (event) ->
    event.preventDefault()
    $.fancybox.close()

  $(document).on "card-order-changed", "#recipe-card-list", (event) ->
    setStateIndex()

  $(document).on "click", ".fancybox-overlay", (event) ->
    event.preventDefault()
    if confirm "Are you sure to discard all changes on this dialog?"
      $.fancybox.close()

  $(document).on "click", ".fancybox-inner", (event) ->
    event.stopPropagation()

  $(document).on "keyup", "#inner_content .nicEdit-main", (event) ->
    description_text_length = descriptionText().length
    $("#inner_content .plain-text-length").html description_text_length
    if description_text_length > 300
      $(".text-length").css "color", "red"
    else
      $(".text-length").css "color", "black"

  $(document).on "click", ".convert-card", (event) ->
    event.preventDefault()
    state = $(this).closest ".state"
    src_data_position = state.data "position"
    state_id = state.attr "id"
    if $(".state").length > 2
      $("#state-convert-dialog .src").text src_data_position
      $("#state-convert-dialog").data "target", state_id

      select = $ "#target_state"
      select.empty()
      states = $ ".state"
      states.each (index, element) ->
        position = $(element).data "position"
        title = $(element).find(".title").first().text()
        text = position + ": " + title

        if (position isnt src_data_position) and (position isnt "")
          select.append $("<option>").html(text).val position

      $.fancybox.open
        href: "#state-convert-dialog"

    else
      alert "First, make 2 or more state."


  $(document).on "click", "#state-convert-dialog .ok-btn", (event) ->
    event.preventDefault()
    src_data_position = $("#state-convert-daialog .src").text()
    dst_data_position = $("#target_state").val()
    dst_state = $(".state[data-position=" + dst_data_position + "]")
    dst_state_id = dst_state.attr "id"

    recipe_url = $("#recipes-show").data "url"
    state_id = $("#state-convert-dialog").data "target"
    annotations_url = recipe_url + "/states/" + state_id + "/annotations/"
    convert_url = recipe_url + "/states/" + state_id + "/to_annotation"

    $.ajax
      url: convert_url,
      type: "GET",
      data: {
              dst_position: dst_data_position,
              dst_state_id: dst_state_id
            },
      dataType: "json",
      success: (data) ->
        new_annotation_id = data.$oid
        new_annotation_url = recipe_url + "/states/" + dst_state_id + "/annotations/" + new_annotation_id
        $.fancybox.close()
        loading = $ "#loading"
        img = loading.find "img"
        left = (loading.width() - img.width()) / 2
        top = (loading.height() - img.height()) / 2
        $(img).css("left", left + "px").css("top", top + "px")
        loading.show()

        $.ajax
          url: new_annotation_url,
          type: "GET",
          dataType: "json",
          success: (data) ->
            #TODO: refactoring: make card append function
            annotation_template = $("#annotation-template > :first")
            card = annotation_template.clone()
            li = $ document.createElement("li")
            li.addClass "card-wrapper"
            li.addClass "annotation-wrapper"
            li.append card
            $("#" + dst_state_id + " .annotation-list").append li

            article_id = $(data.html).find(".flexslider").closest("article").attr "id"
            selector = "#" + article_id + " .flexslider"
            card.replaceWith data.html
            setupFigureSlider selector
            $("#loading").hide()
            $("#" + state_id).closest(".state-wrapper").remove()
            checkStateConvertiblity()
            setStateIndex()
            markup()
          error: (data) ->
            alert data.message

      error: (data) ->
        alert data.message


  $(document).on "click", ".to-state", (event) ->
    event.preventDefault()
    convert_url = $(this).attr "href"
    recipe_url = $("#recipes-show").data "url"
    annotation_id = $(this).closest(".annotation").attr "id"

    $.ajax
      url: convert_url,
      type: "GET",
      dataType: "json",
      success: (data) ->
        new_state_id = data.$oid
        new_state_url = recipe_url + "/states/" + new_state_id
        loading = $ "#loading"
        img = loading.find "img"
        left = (loading.width() - img.width()) / 2
        top = (loading.height() - img.height()) / 2
        $(img).css("left", left + "px").css("top", top + "px")
        loading.show()

        $.ajax
          url: new_state_url,
          type: "GET",
          dataType: "json",
          success: (data) ->
            #TODO: refactoring: make card append function
            state_template = $ "#state-template > :first"
            card = state_template.clone()
            li = $ document.createElement("li")
            li.addClass "card-wrapper"
            li.addClass "state-wrapper"
            li.append card
            $("#recipe-card-list").append li

            article_id = $(data.html).find(".flexslider").closest("article").attr "id"
            selector = "#" + article_id + " .flexslider"
            card.replaceWith data.html
            setupFigureSlider selector
            $("#loading").hide()
            $("#" + annotation_id).closest("li").remove()
            checkStateConvertiblity()
            setStateIndex()
            markup()
          error: (data) ->
            alert data.message
      error: (data) ->
        alert data.message

  $(document).on "change", "input[type='file']", (event) ->
    file = event.target.files[0]
    reader = new FileReader()
    reader.onload = ->
      tmp_img = new Image
      tmp_img.src = reader.result
      $(event.target).siblings("img").attr "src", tmp_img.src
    reader.readAsDataURL file

  wait4save = (form, card) ->
    card.addClass "wait4save"
    card_content = card.find ".card-content:first"
    title = form.find(".card-title").val()
    card_content.find(".title").text title

    ul = card_content.find "figure ul"
    ul.empty()
    figures = form.find ".card-figure-content"
    for figure in figures
      if figure.files.length > 0
        src = window.URL.createObjectURL figure.files[0]
      else
        src = $(figure).val()
      img = $ document.createElement("img")
      img.attr "src", src
      li = $ document.createElement("li")
      li.append img
      ul.append li
    description = form.find(".card-description").val()
    card_content.find(".description").html description
    progress = $(document.createElement "progress")
    progress.attr "max", 1.0
    progress.attr "form", form.attr("id")
    card_content.append progress
    form.bind "ajax:progress", (e, progressEvent) ->
      progress.attr "value", progressEvent.loaded / progressEvent.total

  markup = ->
    attachments = $ ".attachment"
    for attachment in attachments
      markupid = attachment.getAttribute "data-markupid"
      content = attachment.getAttribute "data-content"
      if content && content.length > 0
        $("#" + markupid).attr "href", content
    $(document.body).trigger "attachment-markuped"
  markup()

  checkStateConvertiblity = ->
    states = $ ".state"
    states.each (index, element) ->
      if $(element).find(".annotation").length is 0
        $(element).find(".convert-card").show()
      else
        $(element).find(".convert-card").hide()
  checkStateConvertiblity()

  setStateIndex = ->
    states = $ ".state-wrapper"
    states.each (index, element) ->
      $(element).find("h1.number").text index + 1
      $(element).find(".state").data "position", index + 1
    if states.length > 1
      $(".order-change-btn").show()
    else
      $(".order-change-btn").hide()
  setStateIndex()

  setupFigureSlider = (selector) ->
    $(selector).flexslider {
      animation: "slider",
      animationSpeed: 300,
      controlNav: true,
      smoothHeight: true,
      slideshow: false,
    }

  updateCard = (card, data) ->
    formContainer.empty()
    article_id = $(data.html).find(".flexslider").closest("article").attr "id"
    selector = "#" + article_id + " .flexslider"
    card.replaceWith data.html
    checkStateConvertiblity()
    setStateIndex()
    markup()
    setupFigureSlider selector
    setTimeout getCardsTop, 100
    reloadRecipeCardsList()

    if card.length is 0
      location.reload()

  fixCommentFormAction = (li) ->
    card = li.find ".card"
    card_id = card.attr "id"
    comment_form = card.find "#new_comment"
    comment_form_action = comment_form.attr "action"
    new_comment_form_action = comment_form_action.replace /\/states\/.+\/comments/, "/states/" + card_id + "/comments"
    comment_form.attr "action", new_comment_form_action
