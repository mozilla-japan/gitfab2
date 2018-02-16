$ ->
  $(document).on "ajax:success", ".delete-comment", (xhr, data) ->
    link = $ this
    li = link.closest "li"
    comments = li.closest "ul"
    li.remove()
    changeCommentNumbers comments
    countDownComment comments

  $(document).on "ajax:success", ".comment-form", (xhr, data) ->
    form = $ this
    comments = form.siblings ".comments"
    comments.append data.html
    form.find("#comment_body").val ""
    countUpComment comments

  $(document).on "ajax:error", ".comment-form, .delete-comment", (event, xhr, status, error) ->
    message = JSON.parse(xhr.responseText).message
    msg = ''
    for key, value of message
      msg = "#{key} #{value}"
    alert msg
    event.preventDefault()

  $(document).on "click", ".show-comments-btn", () ->
    card_content = $(this).closest ".card-content"
    comments = card_content.find(".comments-wrapper").first()
    if comments.hasClass "is-closed"
      comments.removeClass "is-closed"
    else
      comments.addClass "is-closed"

  $(document).on "click", ".close-comments-btn", () ->
    comments = $(this).closest(".comments-wrapper").first()
    comments.addClass "is-closed"

changeCommentNumbers = (comment_list) ->
  comments = comment_list.find ".comment"
  comments.each (index, comment) ->
    number = $(comment).find(".number").first()
    number.html "No." + zeroFormat(index + 1, 3)

zeroFormat = (value, figures) ->
  value_length = String(value).length
  if figures > value_length
    return (new Array( (figures - value_length) + 1).join(0) ) + value
  else
    return value

countUpComment = (comment_list) ->
  card_content = comment_list.closest ".card-content"
  count = card_content.find ".show-comments-btn .count"
  current_value = count.text()
  count.text current_value - 0 + 1

countDownComment = (comment_list) ->
  card_content = comment_list.closest ".card-content"
  count = card_content.find ".show-comments-btn .count"
  current_value = count.text()
  count.text current_value - 0 - 1
