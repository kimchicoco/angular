library angular2.test.core.render.dom.events.event_manager_spec;

import "package:angular2/testing_internal.dart"
    show describe, ddescribe, it, iit, xit, xdescribe, expect, beforeEach, el;
import "package:angular2/core.dart" show EventManager, EventManagerPlugin;
import "package:angular2/src/platform/dom/events/dom_events.dart"
    show DomEventsPlugin;
import "package:angular2/src/core/zone/ng_zone.dart" show NgZone;
import "package:angular2/src/facade/collection.dart"
    show ListWrapper, Map, MapWrapper;
import "package:angular2/src/platform/dom/dom_adapter.dart" show DOM;

main() {
  var domEventPlugin;
  beforeEach(() {
    domEventPlugin = new DomEventsPlugin();
  });
  describe("EventManager", () {
    it("should delegate event bindings to plugins that are passed in from the most generic one to the most specific one",
        () {
      var element = el("<div></div>");
      var handler = (e) => e;
      var plugin = new FakeEventManagerPlugin(["click"]);
      var manager =
          new EventManager([domEventPlugin, plugin], new FakeNgZone());
      manager.addEventListener(element, "click", handler);
      expect(plugin._eventHandler["click"]).toBe(handler);
    });
    it("should delegate event bindings to the first plugin supporting the event",
        () {
      var element = el("<div></div>");
      var clickHandler = (e) => e;
      var dblClickHandler = (e) => e;
      var plugin1 = new FakeEventManagerPlugin(["dblclick"]);
      var plugin2 = new FakeEventManagerPlugin(["click", "dblclick"]);
      var manager = new EventManager([plugin2, plugin1], new FakeNgZone());
      manager.addEventListener(element, "click", clickHandler);
      manager.addEventListener(element, "dblclick", dblClickHandler);
      expect(plugin1._eventHandler.containsKey("click")).toBe(false);
      expect(plugin2._eventHandler["click"]).toBe(clickHandler);
      expect(plugin2._eventHandler.containsKey("dblclick")).toBe(false);
      expect(plugin1._eventHandler["dblclick"]).toBe(dblClickHandler);
    });
    it("should throw when no plugin can handle the event", () {
      var element = el("<div></div>");
      var plugin = new FakeEventManagerPlugin(["dblclick"]);
      var manager = new EventManager([plugin], new FakeNgZone());
      expect(() => manager.addEventListener(element, "click", null))
          .toThrowError("No event manager plugin found for event click");
    });
    it("events are caught when fired from a child", () {
      var element = el("<div><div></div></div>");
      // Workaround for https://bugs.webkit.org/show_bug.cgi?id=122755
      DOM.appendChild(DOM.defaultDoc().body, element);
      var child = DOM.firstChild(element);
      var dispatchedEvent = DOM.createMouseEvent("click");
      var receivedEvent = null;
      var handler = (e) {
        receivedEvent = e;
      };
      var manager = new EventManager([domEventPlugin], new FakeNgZone());
      manager.addEventListener(element, "click", handler);
      DOM.dispatchEvent(child, dispatchedEvent);
      expect(receivedEvent).toBe(dispatchedEvent);
    });
    it("should add and remove global event listeners", () {
      var element = el("<div><div></div></div>");
      DOM.appendChild(DOM.defaultDoc().body, element);
      var dispatchedEvent = DOM.createMouseEvent("click");
      var receivedEvent = null;
      var handler = (e) {
        receivedEvent = e;
      };
      var manager = new EventManager([domEventPlugin], new FakeNgZone());
      var remover =
          manager.addGlobalEventListener("document", "click", handler);
      DOM.dispatchEvent(element, dispatchedEvent);
      expect(receivedEvent).toBe(dispatchedEvent);
      receivedEvent = null;
      remover();
      DOM.dispatchEvent(element, dispatchedEvent);
      expect(receivedEvent).toBe(null);
    });
  });
}

class FakeEventManagerPlugin extends EventManagerPlugin {
  List<String> _supports;
  var _eventHandler = new Map<String, Function>();
  FakeEventManagerPlugin(this._supports) : super() {
    /* super call moved to initializer */;
  }
  bool supports(String eventName) {
    return ListWrapper.contains(this._supports, eventName);
  }

  addEventListener(element, String eventName, Function handler) {
    this._eventHandler[eventName] = handler;
    return () {
      (this._eventHandler.containsKey(eventName) &&
          (this._eventHandler.remove(eventName) != null || true));
    };
  }
}

class FakeNgZone extends NgZone {
  FakeNgZone() : super(enableLongStackTrace: false) {
    /* super call moved to initializer */;
  }
  run(fn) {
    fn();
  }

  runOutsideAngular(fn) {
    return fn();
  }
}
