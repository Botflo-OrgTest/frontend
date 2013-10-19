ko.bindingHandlers.popover =
  init: (el, valueAccessor, allBindingsAccessor, viewModel, bindingContext) =>
    options = valueAccessor()
    $(el).popover(options)

ko.bindingHandlers.slider =
  init: (el, valueAccessor, allBindingsAccessor, viewModel, bindingContext) =>
    options = valueAccessor()
    $(el).slider(options)

ko.bindingHandlers.track =
  init: (el, valueAccessor) =>
    $(el).click ->
      val = valueAccessor()
      if _.isString(val)
        mixpanel.track(val)
      else
        mixpanel.track(val.event, val.properties)

# Prefer track_link for links to external sites, like github, because the redirect prevents JS from running/completing
ko.bindingHandlers.track_link =
  init: (el, valueAccessor, allBindingsAccessor) =>
    $(el).click (event) ->
      event.preventDefault()
      redirect = () ->
        window.location.replace($(el).attr('href'))
      backup_redirect = setTimeout(redirect, 1000)

      val = ko.toJS(valueAccessor())
      console.log("track_link:", val)
      mixpanel.track val.event, val.properties, ->
        clearTimeout(backup_redirect)
        redirect()

# Takes a css selector, finds all child elements matching that selector and
# sets the width of all of the elements to the width of the max element
# Example:
# %div{data-bind: "foreach: items, equalizeWidth: '.item'"}
#   .item{data-bind: "text: $data"}
# Approach here: https://github.com/knockout/knockout/wiki/Bindings%3A-runafter
ko.bindingHandlers.equalizeWidth =
  update: (el, valueAccessor, allBindingsAccessor) =>
    ko.toJS(allBindingsAccessor()) # wait for other bindings to finish
    $(el).css('visibility', 'hidden')
    setTimeout () ->
      selector = valueAccessor()
      els = $(el).find(selector)
      max = Math.max.apply(null, $.map(els, (e) -> $(e).width()))
      $.each(els, (i, e) -> $(e).width(max))
      $(el).css('visibility', 'visible')

ko.bindingHandlers.scrollOnClick =
  update: (el, valueAccessor, allBindingsAccessor) =>
    options = ko.toJS(valueAccessor())

    $(el).click (e) ->
      $container = $(e.target).closest(options.selector)

      if options.position is 'top'
        scroll_top = $container.offset().top
      else if options.position is 'bottom'
        scroll_top = $container.offset().top + $container.height() - $(window).height()
      if scroll_top
        $("html, body").animate {scrollTop: scroll_top}, 0



# Takes any kind of jQueryExtension, e.g. popover, tooltip, etc.
jQueryExt = (type) =>
  init: (el, valueAccessor) =>
    options = ko.toJS(valueAccessor())
    $el = $(el)
    $el[type].call($el, options)

# Usage: %a{href: "#", tooltip: {title: myObservable}}
ko.bindingHandlers.popover = jQueryExt('popover')
ko.bindingHandlers.tooltip = jQueryExt('tooltip')
ko.bindingHandlers.typeahead = jQueryExt('typeahead')
ko.bindingHandlers.waypoint = { init: (el, valueAccessor) =>
                                    options = ko.toJS(valueAccessor())
                                    $(el).waypoint('sticky', options) }

## Money custom binding

# Add helper that was minified
ieVersion = () ->
  version = 3
  div = document.createElement('div')
  iElems = div.getElementsByTagName('i')
  null while (div.innerHTML = "<!--[if gt IE #{++version}]><i></i><![endif]-->" and iElems[0])

  if version > 4 then version else undefined

addCommas = (num) ->
  num_str = num.toString()
  i = num_str.length % 3
  prefix = num_str.substr(0, i) + if i > 0 and num_str.length > 3 then "," else ""
  suffix = num_str.substr(i).replace(/(\d{3})(?=\d)/g, "$1" + ",")
  prefix + suffix

# Copy of setTextContent in ko's utils
transformContent = (f, element, textContent) ->
  value = ko.utils.unwrapObservable(textContent)

  if not value?
    value = ""
  else
    value = f(value)

  if 'innerText' in element
    element.innerText = value
  else
    element.textContent = value

  if (ieVersion >= 9)
    element.style.display = element.style.display

ko.bindingHandlers.money =
  update: (el, valueAccessor) =>
    f = (value) -> "$#{addCommas(value)}"
    transformContent(f, el, valueAccessor())

ko.bindingHandlers.duration =
  update: (el, valueAccessor) =>
    f = (value) -> CI.time.as_duration(value)
    transformContent(f, el, valueAccessor())

ko.bindingHandlers.leadingZero =
  update: (el, valueAccessor) =>
    f = (value) -> "0#{value}"
    transformContent(f, el, valueAccessor())

ko.bindingHandlers.shaOne =
  update: (el, valueAccessor) =>
    f = (value) -> value.slice(0,7)
    transformContent(f, el, valueAccessor())
    $(el).attr("title", valueAccessor())

# Specify a haml template that depends on an observable
# Example: %div{data-bind: "haml: {template: myObservable, args: {}}"}
#   Renders the HAML.myObservable() template and will re-render when the
#   observable changes.
# Careful with performance: don't iterate in a haml binding in place of a knockout foreach loop if the array you're iterating over is an observableArray that is modified with knockout's array manipulation functions
ko.bindingHandlers.haml =
  init: () =>
    {controlsDescendantBindings: true}

  update: (el, valueAccessor, allBindingsAccessor, viewModel, bindingContext) =>
    options = valueAccessor()
    template = ko.toJS(options.template)
    args = ko.toJS(options.args)

    $(el).html HAML[template].call(undefined, args)
    ko.applyBindingsToDescendants bindingContext, el

ko.observableArray["fn"].setIndex = (index, newItem) ->
  @valueWillMutate()
  result = @()[index] = newItem
  @valueHasMutated()
  result

# Simple pluralizer, may want to look at
# https://github.com/jeremyruppel/underscore.inflection
ko.bindingHandlers.pluralize =
  update: (el, valueAccessor) =>
    f = (val) ->
      [number, singular, plural] = ko.toJS(val)
      "#{number} #{if number is 1 then singular else plural}"

    transformContent f, el, valueAccessor()
