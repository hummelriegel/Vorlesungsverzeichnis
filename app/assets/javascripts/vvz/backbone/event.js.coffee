class Model extends vvz.Node.Model
    
  class: "Event:Model"
  
  urlRoot: "/events"

  initialize: ->
    # track request with google analytics 
    
  url: ->
    "#{@urlRoot}/#{@id}"
  
  vvzPath: ->
    "/vvz/#{@get("parent").id}#{@url()}"

  subscribe: ->
    console.log("subscribe", this)
    $.ajax
      dataType: "json"
      url: "#{@url()}/subscribe"
      success: (data) =>
        console.log("sub ok", data)
        @set "subscribed": true
      error: @error
   
  unsubscribe: ->
    console.log("unsubscribe", this)
    $.ajax
      dataType: "json"
      url: "#{@url()}/unsubscribe"
      success: (data) =>
        console.log("unsub ok", data)
        @set "subscribed": false
      error: @error

  toggleSubscription: ->
    if @get("subscribed") 
      @unsubscribe() 
    else
      @subscribe()

  toJSON: ->
    data = Backbone.Model.prototype.toJSON.call(this);
    # data.loggedIn = !!currentUser
    data

  error: (d, e, x) => 
    console.log("error", d, e, x)


class EventView extends vvz.Colum.CollumnView
  
  class: "Event:EventView"
  
  events:
   "click #subscribe" : "subscribe"

  template: HoganTemplates["vvz/templates/_event"]

  initialize: ->
    #$(@el).addClass("event")
  
    @delegateEvents(@events)
    model = @options.parent.toJSON()
     
    @model = new Model(model)
    @model.fetch()
    @model.bind('change', @render, this)

    if typeof _gaq != 'undefined' 
      _gaq.push(['_trackPageview', @model.vvzPath()])
  
  render: ->
    data = @model.toJSON()
    html = @template.render(data)
    $(@el).html(html)
    $(@el).find('a[rel=tooltip]').tooltip()

  subscribe: ->
    $(@el).find("#subscribe i").attr("class", "icon-spinner icon-spin")
    @model.toggleSubscription()
    false
    
  
class NodeView extends vvz.Node.View
  
  class: "Event:NodeView"
  


vvz.Event =
  Model: Model
  #Collection: Collection
  EventView: EventView
  NodeView: NodeView

