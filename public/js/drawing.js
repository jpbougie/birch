var Drawing = function() {
  this.state = "idle"
  this.activatedTool = null
  this.paper = null
  this.backgroundImage = null
  this.objects = []
  this.listeners = {}

  this.replaceImage = function(image) {
    elem = $(image)
    src = elem.attr("src")
    width = elem.width()
    height = elem.height()

    this.paper = Raphael(elem.parent('div').get()[0], width, height)
    elem.hide()

    this.backgroundImage = this.paper.image(src, 0, 0, width, height)

    return this
  }
  
  this.activateTool = function(tool) {
    
    d = this
    if(this.activatedTool) {
      $.each(this.listeners, function(k, v) {
        d.paper.canvas.removeEventListener(k, v, false)
      })
    }
    this.activatedTool = tool
    
    this.listeners.click = function (event) { tool.onClick(event); event.preventDefault(); event.stopPropagation(); return false }
    this.listeners.mousedown = function (event) { tool.onMouseDown(event); event.preventDefault();  event.stopPropagation(); return false }
    this.listeners.mousemove = function (event) { tool.onMouseMove(event); event.preventDefault(); event.stopPropagation(); return false }
    this.listeners.mouseup = function (event) { tool.onMouseUp(event); event.preventDefault();  event.stopPropagation(); return false }
    
    this.paper.canvas.addEventListener("click", this.listeners.click , false)
    this.paper.canvas.addEventListener("mousedown", this.listeners.mousedown , false)
    this.paper.canvas.addEventListener("mousemove", this.listeners.mousemove, false)
    this.paper.canvas.addEventListener("mouseup", this.listeners.mouseup, false)
  }
  
  this.track = function(object) {
    this.objects.push(object)
  }
  
  this.toolCompleted = function(tool) {
    this.activatedTool
  }
}

var Toolbar = function(drawing) {
  this.tools = {}
  this.toolsCount = 0
  this.bar = null
  
  this.register = function(name, tool) {
    this.tools[name] = tool
    this.toolsCount++
  }
  
  this.resetSelected = function() {
    this.bar.attr("stroke", "#fff")
  }
  
  this.draw = function() {
    this.bar = drawing.paper.set()
    rect = drawing.paper.rect(0,0,28, 26 * this.toolsCount)
    rect.attr({fill: "#000", opacity: 0.5, "stroke-width": 0})
    this.bar.push(rect)
    
    toolbar = this
    bar = this.bar
    offset = new Pos(0, 0)
    $.each(this.tools, function(toolName, tool) {
      logo = tool.logo(new Pos(offset.x + 1, offset.y))
      fun = function(logo) {
        backdrop = drawing.paper.rect(offset.x + 1, offset.y, 24, 24)
        backdrop.attr({opacity: 0.5, fill:"#333", "stroke-width": 0})
        logo.push(backdrop)
        logo.items[0].toFront()

        $.each(logo.items, function() {
          
          f = function () {
            this[0].addEventListener("click", function(event) {
              event.preventDefault()
              event.cancelBubble = true
              event.stopPropagation()
              drawing.activateTool(tool)
              toolbar.resetSelected()
              logo.attr("stroke", "#00B4FF")
              return false
            }, false)
            this[0].addEventListener("mousedown", function(event) { event.stopPropagation; event.cancelBubble = true; return false}, false)
            this[0].addEventListener("mousemove", function(event) { event.stopPropagation; event.cancelBubble = true; return false}, false)
            this[0].addEventListener("mouseup", function(event) { event.stopPropagation; event.cancelBubble = true; return false}, false)
          }
          
          if(typeof(this.items) != "undefined") {
            $.each(this.items, f)
          }
          else
          {
            f.apply(this)
          }
        })


        bar.push(logo)
        offset = new Pos(offset.x, offset.y + 26)
      }
      
      fun(logo)
    })
  }
}

// Different tools can be used
// The drawing board allows you to activate a tool
// the object is created when a click is made
// some tools will require a drag and drop, while other work on a click

var Tool = function() {
  this.onMouseDown = function(event) {}
  this.onMouseMove = function(event) {}
  this.onMouseUp   = function(event) {}
  this.onClick     = function(event) {}
  
  // this should return a set that will be used for the toolbar
  this.logo = function(offset) {}
}

var Pos = function(x, y) { this.x = x; this.y = y }

var DragTool = function() {
  this.start = null
  this.drag = false
  
  this.insert = function() {}
  this.resize = function(pos) {}
  this.release = function() {}
  
  this.onMouseDown = function(event) {
    this.start = new Pos(event.offsetX, event.offsetY)
    this.drag = true
    this.insert()
  }
  
  this.onMouseMove = function(event) {
    if(this.drag) {
      this.resize(new Pos(event.offsetX, event.offsetY))
    }
  }
  
  this.onMouseUp = function(event) {
    this.release()
    this.drag = false
  }
}

DragTool.prototype = new Tool()

var Line = function(drawing) {
  this.object = null
  this.size = 20
  this.insert = function() {
    this.start = new Pos(this.start.x - (this.size / 2), this.start.y)
    this.object = drawing.paper.rect(this.start.x, this.start.y - this.size / 2, this.size, this.size, this.size / 2)
    this.object.attr("fill", "#00B4FF")
    this.object.attr("stroke-width", 0)
    
  }
  
  this.resize = function(pos) {
        
    // calculate the angle using tan(angle) = opposite/adjacent
    delta = new Pos(pos.x - this.start.x, pos.y - this.start.y)
        
    angle = Math.atan2(delta.y, delta.x) * 180 / Math.PI
    width = Math.sqrt(delta.x * delta.x + delta.y * delta.y)
    
    this.object.rotate(angle, this.start.x + (this.size / 2), this.start.y)
    this.object.attr("width", width)
  }
  
  this.release = function() {
    drawing.track(this.object)
  }
  
  this.logo = function(offset) {
    line = drawing.paper.path("M " + (offset.x + 4) + " " + (offset.y + 4) + " l 16 16")  
    line.attr({fill: "white", stroke: "white", "stroke-width": 3})
    set = drawing.paper.set()
    set.push(line)
    
    return set
  }
}

Line.prototype = new DragTool()


var Ellipse = function(drawing) {
  this.object = null
  
  this.insert = function() {
    this.object = drawing.paper.ellipse(this.start.x, this.start.y, 2, 2)
    this.object.attr("stroke-width", 10)
    this.object.attr("stroke", "#00B4FF")
  }
  
  this.resize = function(pos) {
    
    delta = new Pos(pos.x - this.start.x, pos.y - this.start.y)
    
    // x and y are given as the center of the ellipse
    this.object.attr("cx", pos.x - delta.x / 2)
    this.object.attr("cy", pos.y - delta.y / 2)
    
    this.object.attr("rx", Math.abs(delta.x) / 2)
    this.object.attr("ry", Math.abs(delta.y) / 2)
  }
  
  this.release = function() {
    drawing.track(this.object)
  }
  
  this.logo = function(offset) {
    set = drawing.paper.set()
    circle = drawing.paper.ellipse(offset.x + 12, offset.y + 12, 9, 7)
    circle.attr("stroke-width", 3)
    circle.attr("stroke", "#fff")
    set.push(circle)
    
    return set
  }
}

Ellipse.prototype = new DragTool()

var Arrow = function(drawing) {
  this.object = null
  this.path = "M 0 0 l -1 -8 l -3 1 l 4 -4 l 4 4 l -3 -1 z"
  this.tail = null
  
  this.insert = function() {
    this.object = drawing.paper.path(this.path)
    this.object.attr("fill", "#00B4FF")
    this.object.scale(10, 10)
    
    this.tail = new Pos(this.start.x, this.start.y + this.object.getBBox().height)
    this.object.translate(this.tail.x, this.tail.y - this.object.getBBox().height / 2)
  }
  
  this.resize = function(pos) {
        
    // calculate the angle using tan(angle) = opposite/adjacent
    delta = new Pos(pos.x - this.tail.x, pos.y - this.tail.y)
    
    angle = Math.atan2(delta.y, delta.x) * 180 / Math.PI
    
    
    //this.object.attr("cx", pos.x - delta.x / 2)
    //this.object.attr("cy", pos.y - delta.y / 2)
    
    this.object.scale(Math.abs(delta.x) / 8, Math.abs(delta.y) / 11, this.tail.x, this.tail.y)
    
    //this.object.rotate(angle, this.tail.x, this.tail.y)
  }
  
  this.release = function() {
    drawing.track(this.object)
  }
}

Arrow.prototype = new DragTool()