ip = null
port = null
rtsp_port = null
xhrRequestPortCheck = null

initNotification = ->
  Notification.init(".bb-alert");
  if notifyMessage
    Notification.show notifyMessage

sendAJAXRequest = (settings) ->
  token = $('meta[name="csrf-token"]')
  if token.size() > 0
    headers =
      "X-CSRF-Token": token.attr("content")
    settings.headers = headers
  xhrRequestChangeMonth = jQuery.ajax(settings)
  true

loadVendorModels = (vendor_id, stroke_key_up) ->
  NProgress.start()
  $("#camera-model option").remove()
  $("#camera-model").append('<option value="">Loading...</option>');
  if vendor_id is ""
    $("#camera-model option").remove()
    $("#camera-model").append('<option value="">Select Camera Model</option>');
    $("#snapshot").val("")
    $("#snapshot-readonly").val("")
    $("#snapshot").removeClass("hide")
    $("#snapshot-readonly").addClass("hide")
    NProgress.done()
    return

  data = {}
  data.vendor_id = vendor_id
  data.limit = 400
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    NProgress.done()
    false

  onSuccess = (result, status, jqXHR) ->
    $("#camera-model option").remove()
    if result.models.length == 0
      $("#camera-model").append('<option value="">No Model Found</option>');
      return

    models = sortByKey(result.models, "name")
    for model in models
      selected = if model.id is $("#last-selected-model").val() then 'selected="selected"' else ''
      jpg_url = if model.defaults.snapshots then model.defaults.snapshots.jpg else ''
      if jpg_url is "unknown"
        jpg_url = ""
      if selected is '' && model.name.toLowerCase().indexOf('default') isnt -1
        $("#camera-model").prepend("<option jpg-val='#{jpg_url}' value='#{model.id}' selected='selected'>#{model.name}</option>")
      else if model.name.toLowerCase().indexOf('other') isnt -1
        $("#camera-model").prepend("<option jpg-val='#{jpg_url}' value='#{model.id}' selected='selected'>#{model.name} - Custom URL</option>")
      else
        $("#camera-model").append("<option jpg-val='#{jpg_url}' value='#{model.id}' #{selected}>#{model.name}</option>")
    if $("#last-selected-model").val() is ''
      if model.id isnt "other_default"
        $("#snapshot").val(cleanAndSetJpegUrl($("#camera-model").find(":selected").attr("jpg-val")))
        $("#snapshot-readonly").val(cleanAndSetJpegUrl($("#camera-model").find(":selected").attr("jpg-val")))
        $("#snapshot").addClass("hide")
        $("#snapshot-readonly").removeClass("hide")
      else
        $("#snapshot").val("") if !stroke_key_up
        $("#snapshot-readonly").val("")
        $("#snapshot").removeClass("hide")
        $("#snapshot-readonly").addClass("hide")
    $("#last-selected-model").val('')
    NProgress.done()

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json; charset=utf-8"
    type: 'GET'
    url: "#{Evercam.API_URL}models.json"

  sendAJAXRequest(settings)
  true

sortByKey = (array, key) ->
  array.sort (a, b) ->
    x = a[key]
    y = b[key]
    (if (x < y) then -1 else ((if (x > y) then 1 else 0)))

loadVendors = ->
  data = {}
  data.api_id = Evercam.User.api_id
  data.api_key = Evercam.User.api_key

  onError = (jqXHR, status, error) ->
    false

  onSuccess = (result, status, jqXHR) ->
    vendors = sortByKey(result.vendors, "name")
    $("#camera-vendor option").remove()

    for vendor in vendors
      selected = ''
      if vendor.id is $("#last-selected-vendor").val()
        selected = 'selected="selected"'
        loadVendorModels(vendor.id)
        $("#last-selected-vendor").val('')
      if vendor.id is "other"
        $("#camera-vendor").prepend("<option value='#{vendor.id}' #{selected}>#{vendor.name} - Custom URL</option>")
      else
        $("#camera-vendor").append("<option value='#{vendor.id}' #{selected}>#{vendor.name}</option>")
    $("#camera-vendor").prepend('<option value="">Select Camera Vendor</option>');

  settings =
    cache: false
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/json; charset=utf-8"
    type: 'GET'
    url: "#{Evercam.API_URL}vendors.json"

  sendAJAXRequest(settings)
  true

validate_hostname = (str) ->
  ValidIpAddressRegex = /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$/
  ValidHostnameRegex = /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])$/
  ValidIpAddressRegex.test(str) or ValidHostnameRegex.test(str)

handleVendorModelEvents = ->
  $("#camera-vendor").on "change", ->
    loadVendorModels($(this).val())

  $(".camera-model").on "change", ->
    $("#snapshot").val(cleanAndSetJpegUrl($(this).find(":selected").attr("jpg-val")))
    $("#snapshot-readonly").val(cleanAndSetJpegUrl($(this).find(":selected").attr("jpg-val")))
    $("#snapshot").addClass("hide")
    $("#snapshot-readonly").removeClass("hide")

cleanAndSetJpegUrl = (jpeg_url) ->
  if jpeg_url.indexOf('/') == 0
    jpeg_url = jpeg_url.substr(1)
  return jpeg_url

onLoadPage = ->
  if $("#last-selected-model").val() isnt ''
    if $("#last-selected-model").val() is "other_default"
      $("#snapshot").removeClass("hide")
      $("#snapshot-readonly").addClass("hide")
    else
      $("#snapshot").addClass("hide")
      $("#snapshot-readonly").removeClass("hide")
    $("#snapshot").val(cleanAndSetJpegUrl($("#snapshot").val()))
    $("#snapshot-readonly").val(cleanAndSetJpegUrl($("#snapshot-readonly").val()))
  $(".settings").hide()
  #toggle the componenet with class msg_body
  $(".additional").click ->
    $(this).next(".settings").slideToggle 500

  $("#hide").click ->
    $("p").fadeOut()

  $("#reveal").click ->
    $(".this").fadeIn()

  $("#unreveal").click ->
    $(".this").fadeOut()

onAddCamera = ->
  $("#add-button").on 'click', ->
    if $("#camera-name").val().trim() is "" && $("#camera-id").val().trim() is "" && $("#camera-url").val().trim() is "" && $("#snapshot").val().trim() is ""
      Notification.show "Please enter required camera fields: Camera Name, Camera-Id, Camera URL and Snapshot Url."
      return false
    if $("#camera-name").val().trim() is ""
      Notification.show "Please enter required fields: Camera Name."
      return false
    if $("#camera-id").val().trim() is ""
      Notification.show "Please enter required fields: Camera-Id."
      return false
    if $("#camera-url").val().trim() is ""
      Notification.show "Please enter required fields: Camera URL."
      return false
    if $("#snapshot").val().trim() is ""
      Notification.show "Please enter required fields: Snapshot Url."
      return false
    regularExpression = /^(^127\.0\.0\.1)|(^192\.168\.)|(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)$/
    if regularExpression.test($("#camera-url").val())
      Notification.show "Its your local IP, please provide camera public IP."
      $("#camera-url").css("border-color", "red")
      return false
    if Evercam.ENV == 'production'
      if $('.col-sm-8 input').parent('.has-error').length > 0
        mixpanel.track_forms '#create-a-camera', 'Create a camera', 'Client-Type': 'Dash'

onCustomizedUrl = ->
  $("#snapshot").on "keyup", ->
    if $("#camera-vendor").val() isnt "other"
      $("#camera-vendor").val("other")
      loadVendorModels($("#camera-vendor").val(), true)

port_check = (external_port,type) ->
  ex_ip = $('#camera-url').val()
  ex_port = external_port
  if !ex_port
    $(".#{type}port-status").empty()
    return
  if !ex_ip
    $(".#{type}port-status").empty()
    return
  $(".#{type}port-status").empty()
  $(".#{type}refresh-gif").show()
  data = {}

  onError = (jqXHR, textStatus, ex) ->
    $(".#{type}refresh-gif").hide()
    $(".#{type}port-status").removeClass('green')
    $(".#{type}port-status").addClass('red')
    $(".#{type}port-status").text('Port is Closed')

  onSuccess = (result, status, jqXHR) ->
    if result.open is true
      $(".#{type}refresh-gif").hide()
      $(".#{type}port-status").removeClass('red')
      $(".#{type}port-status").addClass('green')
      $(".#{type}port-status").text('Port is Open')
    else
      $(".#{type}refresh-gif").hide()
      $(".#{type}port-status").removeClass('green')
      $(".#{type}port-status").addClass('red')
      $(".#{type}port-status").text('Port is Closed')


  settings =
    data: data
    dataType: 'json'
    error: onError
    success: onSuccess
    contentType: "application/x-www-form-urlencoded"
    type: 'GET'
    url: "#{Evercam.MEDIA_API_URL}cameras/port-check?address=#{ex_ip}&port=#{ex_port}"

  xhrRequestPortCheck = jQuery.ajax(settings)
  true

check_port = ->
  $('#port').on 'keyup', ->
    if xhrRequestPortCheck
      xhrRequestPortCheck.abort()
    port = $('#port').val()
    port_check(port,'')
  $('#camera-url').on 'keyup', ->
    if xhrRequestPortCheck
      xhrRequestPortCheck.abort()
    port_check(port,'')
    port_check(rtsp_port,'rtsp-')
  $('#ext-rtsp-port').on 'keyup', ->
    if xhrRequestPortCheck
      xhrRequestPortCheck.abort()
    rtsp_port = $('#ext-rtsp-port').val()
    port_check(rtsp_port,'rtsp-')

cursor_visible = ->
  $('.external-port').on 'click', ->
    $('#port').focus()
  $('#change').on 'click', ->
    $('#ext-rtsp-port').focus()

window.initializeAddCamera = ->
  ip = $('#camera-url').val()
  port = $('#port').val()
  rtsp_port = $('#ext-rtsp-port').val()
  Metronic.init()
  Layout.init()
  QuickSidebar.init()
  onLoadPage()
  $.validate()
  handleVendorModelEvents()
  initNotification()
  loadVendors()
  onAddCamera()
  onCustomizedUrl()
  cursor_visible()
  check_port()
  port_check(port,'')
  port_check(rtsp_port,'rtsp-')
  NProgress.done()

