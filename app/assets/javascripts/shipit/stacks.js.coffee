$document = $(document)

$document.on 'click', '.commit-lock a', (event) ->
  event.preventDefault()
  $commit = $(event.target).closest('.commit')
  $link = $(event.target).closest('a')

  locked = $commit.hasClass('locked')
  $commit.toggleClass('locked')

  $.ajax($link.attr('href'), method: 'PATCH', data: {commit: {locked: !locked}})

$document.on 'click', '.action-set-release-status', (event) ->
  event.preventDefault()
  $link = $(event.target).closest('a')
  $deploy = $link.closest('.deploy')
  newStatus = $link.data('status')

  return if $deploy.attr('data-release-status') == newStatus

  $.ajax($link.attr('href'), method: 'POST', data: {status: newStatus}).success((last_status) ->
    $deploy.attr('data-release-status', last_status.state)
  )

$document.on 'click', '#add-new-variable', (event) ->
  event.preventDefault()
  formFields = $(event.target).closest('form').find('.field-list')[0]
  template = document.querySelector("template[id='stack-variable-form-input']")

  formFields.appendChild(document.importNode(template.content, true))

$document.on 'change', '#stack_extra_variables__key', (event) ->
  allOcurrences = (items, element) ->
    indexes = []
    idx = items.indexOf(element)
    while (idx != -1)
      indexes.push(idx)
      idx = items.indexOf(element, idx + 1)

    indexes

  $submit = $(event.target).closest('form').find("input[type='submit']")
  $keysInputs = $(event.target).closest('form').find('input#stack_extra_variables__key')

  allKeys = []
  $keysInputs.each ->
    allKeys.push($(this).val())

  $keysInputs.each ->
    if (allOcurrences(allKeys, $(this).val()).length > 1)
      $submit.addClass('btn--disabled')
      $submit.prop('disabled', true)
      $(this).addClass('field-invalid')
    else
      $submit.removeClass('btn--disabled')
      $submit.prop('disabled', false)
      $(this).removeClass('field-invalid')

$document.on 'click', '#remove-variable', (event) ->
  event.preventDefault()
  formField = $(event.target).closest('div')[0]
  formField.parentNode.removeChild(formField)

jQuery ($) ->
  displayIgnoreCiMessage = ->
    ignoreCiMessage = $(".ignoring-ci")
    return unless ignoreCiMessage
    $('.dismiss-ignore-ci-warning').click (event) ->
      event.preventDefault()
      dismissIgnoreCiMessage()

    if localStorage.getItem(getLocalStorageKey())
      ignoreCiMessage.hide()

  dismissIgnoreCiMessage = ->
    localStorage.setItem(getLocalStorageKey(), true)
    ignoreCiMessage = $(".ignoring-ci")
    ignoreCiMessage.hide() if ignoreCiMessage

  getLocalStorageKey = ->
    stackName = $('.repo-name').data('repo-full-name')
    "ignoreCIDismissed" + stackName

  displayIgnoreCiMessage()

  $(document).on 'click', '.setting-ccmenu input[type=submit]', (event) ->
    event.preventDefault()
    $(event.target).prop('disabled', true)
    $.get(event.target.dataset.remote).done((data) ->
      $('#ccmenu-url').val(data.ccmenu_url).removeClass('hidden')
      $(event.target).addClass('hidden')
    ).fail(->
      $(event.target).prop('disabled', false)
    )
