(function webpackUniversalModuleDefinition(root, factory) {
	if(typeof exports === 'object' && typeof module === 'object')
		module.exports = factory();
	else if(typeof define === 'function' && define.amd)
		define([], factory);
	else if(typeof exports === 'object')
		exports["ReactDnDHTML5Backend"] = factory();
	else
		root["ReactDnDHTML5Backend"] = factory();
})(window, function() {
return /******/ (function(modules) { // webpackBootstrap
/******/ 	// The module cache
/******/ 	var installedModules = {};
/******/
/******/ 	// The require function
/******/ 	function __webpack_require__(moduleId) {
/******/
/******/ 		// Check if module is in cache
/******/ 		if(installedModules[moduleId]) {
/******/ 			return installedModules[moduleId].exports;
/******/ 		}
/******/ 		// Create a new module (and put it into the cache)
/******/ 		var module = installedModules[moduleId] = {
/******/ 			i: moduleId,
/******/ 			l: false,
/******/ 			exports: {}
/******/ 		};
/******/
/******/ 		// Execute the module function
/******/ 		modules[moduleId].call(module.exports, module, module.exports, __webpack_require__);
/******/
/******/ 		// Flag the module as loaded
/******/ 		module.l = true;
/******/
/******/ 		// Return the exports of the module
/******/ 		return module.exports;
/******/ 	}
/******/
/******/
/******/ 	// expose the modules object (__webpack_modules__)
/******/ 	__webpack_require__.m = modules;
/******/
/******/ 	// expose the module cache
/******/ 	__webpack_require__.c = installedModules;
/******/
/******/ 	// define getter function for harmony exports
/******/ 	__webpack_require__.d = function(exports, name, getter) {
/******/ 		if(!__webpack_require__.o(exports, name)) {
/******/ 			Object.defineProperty(exports, name, { enumerable: true, get: getter });
/******/ 		}
/******/ 	};
/******/
/******/ 	// define __esModule on exports
/******/ 	__webpack_require__.r = function(exports) {
/******/ 		if(typeof Symbol !== 'undefined' && Symbol.toStringTag) {
/******/ 			Object.defineProperty(exports, Symbol.toStringTag, { value: 'Module' });
/******/ 		}
/******/ 		Object.defineProperty(exports, '__esModule', { value: true });
/******/ 	};
/******/
/******/ 	// create a fake namespace object
/******/ 	// mode & 1: value is a module id, require it
/******/ 	// mode & 2: merge all properties of value into the ns
/******/ 	// mode & 4: return value when already ns object
/******/ 	// mode & 8|1: behave like require
/******/ 	__webpack_require__.t = function(value, mode) {
/******/ 		if(mode & 1) value = __webpack_require__(value);
/******/ 		if(mode & 8) return value;
/******/ 		if((mode & 4) && typeof value === 'object' && value && value.__esModule) return value;
/******/ 		var ns = Object.create(null);
/******/ 		__webpack_require__.r(ns);
/******/ 		Object.defineProperty(ns, 'default', { enumerable: true, value: value });
/******/ 		if(mode & 2 && typeof value != 'string') for(var key in value) __webpack_require__.d(ns, key, function(key) { return value[key]; }.bind(null, key));
/******/ 		return ns;
/******/ 	};
/******/
/******/ 	// getDefaultExport function for compatibility with non-harmony modules
/******/ 	__webpack_require__.n = function(module) {
/******/ 		var getter = module && module.__esModule ?
/******/ 			function getDefault() { return module['default']; } :
/******/ 			function getModuleExports() { return module; };
/******/ 		__webpack_require__.d(getter, 'a', getter);
/******/ 		return getter;
/******/ 	};
/******/
/******/ 	// Object.prototype.hasOwnProperty.call
/******/ 	__webpack_require__.o = function(object, property) { return Object.prototype.hasOwnProperty.call(object, property); };
/******/
/******/ 	// __webpack_public_path__
/******/ 	__webpack_require__.p = "";
/******/
/******/
/******/ 	// Load entry module and return exports
/******/ 	return __webpack_require__(__webpack_require__.s = "./lib/index.js");
/******/ })
/************************************************************************/
/******/ ({

/***/ "./lib/BrowserDetector.js":
/*!********************************!*\
  !*** ./lib/BrowserDetector.js ***!
  \********************************/
/*! exports provided: isFirefox, isSafari */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"isFirefox\", function() { return isFirefox; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"isSafari\", function() { return isSafari; });\n/* harmony import */ var _utils_js_utils__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./utils/js_utils */ \"./lib/utils/js_utils.js\");\n\nconst isFirefox = Object(_utils_js_utils__WEBPACK_IMPORTED_MODULE_0__[\"memoize\"])(() => /firefox/i.test(navigator.userAgent));\nconst isSafari = Object(_utils_js_utils__WEBPACK_IMPORTED_MODULE_0__[\"memoize\"])(() => Boolean(window.safari));\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/BrowserDetector.js?");

/***/ }),

/***/ "./lib/EnterLeaveCounter.js":
/*!**********************************!*\
  !*** ./lib/EnterLeaveCounter.js ***!
  \**********************************/
/*! exports provided: default */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"default\", function() { return EnterLeaveCounter; });\n/* harmony import */ var _utils_js_utils__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./utils/js_utils */ \"./lib/utils/js_utils.js\");\n\nclass EnterLeaveCounter {\n    constructor(isNodeInDocument) {\n        this.entered = [];\n        this.isNodeInDocument = isNodeInDocument;\n    }\n    enter(enteringNode) {\n        const previousLength = this.entered.length;\n        const isNodeEntered = (node) => this.isNodeInDocument(node) &&\n            (!node.contains || node.contains(enteringNode));\n        this.entered = Object(_utils_js_utils__WEBPACK_IMPORTED_MODULE_0__[\"union\"])(this.entered.filter(isNodeEntered), [enteringNode]);\n        return previousLength === 0 && this.entered.length > 0;\n    }\n    leave(leavingNode) {\n        const previousLength = this.entered.length;\n        this.entered = Object(_utils_js_utils__WEBPACK_IMPORTED_MODULE_0__[\"without\"])(this.entered.filter(this.isNodeInDocument), leavingNode);\n        return previousLength > 0 && this.entered.length === 0;\n    }\n    reset() {\n        this.entered = [];\n    }\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/EnterLeaveCounter.js?");

/***/ }),

/***/ "./lib/HTML5Backend.js":
/*!*****************************!*\
  !*** ./lib/HTML5Backend.js ***!
  \*****************************/
/*! exports provided: default */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"default\", function() { return HTML5Backend; });\n/* harmony import */ var _EnterLeaveCounter__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./EnterLeaveCounter */ \"./lib/EnterLeaveCounter.js\");\n/* harmony import */ var _BrowserDetector__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./BrowserDetector */ \"./lib/BrowserDetector.js\");\n/* harmony import */ var _OffsetUtils__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./OffsetUtils */ \"./lib/OffsetUtils.js\");\n/* harmony import */ var _NativeDragSources__WEBPACK_IMPORTED_MODULE_3__ = __webpack_require__(/*! ./NativeDragSources */ \"./lib/NativeDragSources/index.js\");\n/* harmony import */ var _NativeTypes__WEBPACK_IMPORTED_MODULE_4__ = __webpack_require__(/*! ./NativeTypes */ \"./lib/NativeTypes.js\");\n/* harmony import */ var _OptionsReader__WEBPACK_IMPORTED_MODULE_5__ = __webpack_require__(/*! ./OptionsReader */ \"./lib/OptionsReader.js\");\n\n\n\n\n\n\nclass HTML5Backend {\n    constructor(manager, globalContext) {\n        this.sourcePreviewNodes = new Map();\n        this.sourcePreviewNodeOptions = new Map();\n        this.sourceNodes = new Map();\n        this.sourceNodeOptions = new Map();\n        this.dragStartSourceIds = null;\n        this.dropTargetIds = [];\n        this.dragEnterTargetIds = [];\n        this.currentNativeSource = null;\n        this.currentNativeHandle = null;\n        this.currentDragSourceNode = null;\n        this.altKeyPressed = false;\n        this.mouseMoveTimeoutTimer = null;\n        this.asyncEndDragFrameId = null;\n        this.dragOverTargetIds = null;\n        this.getSourceClientOffset = (sourceId) => {\n            return Object(_OffsetUtils__WEBPACK_IMPORTED_MODULE_2__[\"getNodeClientOffset\"])(this.sourceNodes.get(sourceId));\n        };\n        this.endDragNativeItem = () => {\n            if (!this.isDraggingNativeItem()) {\n                return;\n            }\n            this.dispatcher.endDrag();\n            this.registry.removeSource(this.currentNativeHandle);\n            this.currentNativeHandle = null;\n            this.currentNativeSource = null;\n        };\n        this.isNodeInDocument = (node) => {\n            // Check the node either in the main document or in the current context\n            return this.document && this.document.body && document.body.contains(node);\n        };\n        this.endDragIfSourceWasRemovedFromDOM = () => {\n            const node = this.currentDragSourceNode;\n            if (this.isNodeInDocument(node)) {\n                return;\n            }\n            if (this.clearCurrentDragSourceNode()) {\n                this.dispatcher.endDrag();\n            }\n        };\n        this.handleTopDragStartCapture = () => {\n            this.clearCurrentDragSourceNode();\n            this.dragStartSourceIds = [];\n        };\n        this.handleTopDragStart = (e) => {\n            if (e.defaultPrevented) {\n                return;\n            }\n            const { dragStartSourceIds } = this;\n            this.dragStartSourceIds = null;\n            const clientOffset = Object(_OffsetUtils__WEBPACK_IMPORTED_MODULE_2__[\"getEventClientOffset\"])(e);\n            // Avoid crashing if we missed a drop event or our previous drag died\n            if (this.monitor.isDragging()) {\n                this.dispatcher.endDrag();\n            }\n            // Don't publish the source just yet (see why below)\n            this.dispatcher.beginDrag(dragStartSourceIds || [], {\n                publishSource: false,\n                getSourceClientOffset: this.getSourceClientOffset,\n                clientOffset,\n            });\n            const { dataTransfer } = e;\n            const nativeType = Object(_NativeDragSources__WEBPACK_IMPORTED_MODULE_3__[\"matchNativeItemType\"])(dataTransfer);\n            if (this.monitor.isDragging()) {\n                if (dataTransfer && typeof dataTransfer.setDragImage === 'function') {\n                    // Use custom drag image if user specifies it.\n                    // If child drag source refuses drag but parent agrees,\n                    // use parent's node as drag image. Neither works in IE though.\n                    const sourceId = this.monitor.getSourceId();\n                    const sourceNode = this.sourceNodes.get(sourceId);\n                    const dragPreview = this.sourcePreviewNodes.get(sourceId) || sourceNode;\n                    if (dragPreview) {\n                        const { anchorX, anchorY, offsetX, offsetY, } = this.getCurrentSourcePreviewNodeOptions();\n                        const anchorPoint = { anchorX, anchorY };\n                        const offsetPoint = { offsetX, offsetY };\n                        const dragPreviewOffset = Object(_OffsetUtils__WEBPACK_IMPORTED_MODULE_2__[\"getDragPreviewOffset\"])(sourceNode, dragPreview, clientOffset, anchorPoint, offsetPoint);\n                        dataTransfer.setDragImage(dragPreview, dragPreviewOffset.x, dragPreviewOffset.y);\n                    }\n                }\n                try {\n                    // Firefox won't drag without setting data\n                    dataTransfer.setData('application/json', {});\n                }\n                catch (err) {\n                    // IE doesn't support MIME types in setData\n                }\n                // Store drag source node so we can check whether\n                // it is removed from DOM and trigger endDrag manually.\n                this.setCurrentDragSourceNode(e.target);\n                // Now we are ready to publish the drag source.. or are we not?\n                const { captureDraggingState } = this.getCurrentSourcePreviewNodeOptions();\n                if (!captureDraggingState) {\n                    // Usually we want to publish it in the next tick so that browser\n                    // is able to screenshot the current (not yet dragging) state.\n                    //\n                    // It also neatly avoids a situation where render() returns null\n                    // in the same tick for the source element, and browser freaks out.\n                    setTimeout(() => this.dispatcher.publishDragSource(), 0);\n                }\n                else {\n                    // In some cases the user may want to override this behavior, e.g.\n                    // to work around IE not supporting custom drag previews.\n                    //\n                    // When using a custom drag layer, the only way to prevent\n                    // the default drag preview from drawing in IE is to screenshot\n                    // the dragging state in which the node itself has zero opacity\n                    // and height. In this case, though, returning null from render()\n                    // will abruptly end the dragging, which is not obvious.\n                    //\n                    // This is the reason such behavior is strictly opt-in.\n                    this.dispatcher.publishDragSource();\n                }\n            }\n            else if (nativeType) {\n                // A native item (such as URL) dragged from inside the document\n                this.beginDragNativeItem(nativeType);\n            }\n            else if (dataTransfer &&\n                !dataTransfer.types &&\n                ((e.target && !e.target.hasAttribute) ||\n                    !e.target.hasAttribute('draggable'))) {\n                // Looks like a Safari bug: dataTransfer.types is null, but there was no draggable.\n                // Just let it drag. It's a native type (URL or text) and will be picked up in\n                // dragenter handler.\n                return;\n            }\n            else {\n                // If by this time no drag source reacted, tell browser not to drag.\n                e.preventDefault();\n            }\n        };\n        this.handleTopDragEndCapture = () => {\n            if (this.clearCurrentDragSourceNode()) {\n                // Firefox can dispatch this event in an infinite loop\n                // if dragend handler does something like showing an alert.\n                // Only proceed if we have not handled it already.\n                this.dispatcher.endDrag();\n            }\n        };\n        this.handleTopDragEnterCapture = (e) => {\n            this.dragEnterTargetIds = [];\n            const isFirstEnter = this.enterLeaveCounter.enter(e.target);\n            if (!isFirstEnter || this.monitor.isDragging()) {\n                return;\n            }\n            const { dataTransfer } = e;\n            const nativeType = Object(_NativeDragSources__WEBPACK_IMPORTED_MODULE_3__[\"matchNativeItemType\"])(dataTransfer);\n            if (nativeType) {\n                // A native item (such as file or URL) dragged from outside the document\n                this.beginDragNativeItem(nativeType);\n            }\n        };\n        this.handleTopDragEnter = (e) => {\n            const { dragEnterTargetIds } = this;\n            this.dragEnterTargetIds = [];\n            if (!this.monitor.isDragging()) {\n                // This is probably a native item type we don't understand.\n                return;\n            }\n            this.altKeyPressed = e.altKey;\n            if (!Object(_BrowserDetector__WEBPACK_IMPORTED_MODULE_1__[\"isFirefox\"])()) {\n                // Don't emit hover in `dragenter` on Firefox due to an edge case.\n                // If the target changes position as the result of `dragenter`, Firefox\n                // will still happily dispatch `dragover` despite target being no longer\n                // there. The easy solution is to only fire `hover` in `dragover` on FF.\n                this.dispatcher.hover(dragEnterTargetIds, {\n                    clientOffset: Object(_OffsetUtils__WEBPACK_IMPORTED_MODULE_2__[\"getEventClientOffset\"])(e),\n                });\n            }\n            const canDrop = dragEnterTargetIds.some(targetId => this.monitor.canDropOnTarget(targetId));\n            if (canDrop) {\n                // IE requires this to fire dragover events\n                e.preventDefault();\n                if (e.dataTransfer) {\n                    e.dataTransfer.dropEffect = this.getCurrentDropEffect();\n                }\n            }\n        };\n        this.handleTopDragOverCapture = () => {\n            this.dragOverTargetIds = [];\n        };\n        this.handleTopDragOver = (e) => {\n            const { dragOverTargetIds } = this;\n            this.dragOverTargetIds = [];\n            if (!this.monitor.isDragging()) {\n                // This is probably a native item type we don't understand.\n                // Prevent default \"drop and blow away the whole document\" action.\n                e.preventDefault();\n                if (e.dataTransfer) {\n                    e.dataTransfer.dropEffect = 'none';\n                }\n                return;\n            }\n            this.altKeyPressed = e.altKey;\n            this.dispatcher.hover(dragOverTargetIds || [], {\n                clientOffset: Object(_OffsetUtils__WEBPACK_IMPORTED_MODULE_2__[\"getEventClientOffset\"])(e),\n            });\n            const canDrop = (dragOverTargetIds || []).some(targetId => this.monitor.canDropOnTarget(targetId));\n            if (canDrop) {\n                // Show user-specified drop effect.\n                e.preventDefault();\n                if (e.dataTransfer) {\n                    e.dataTransfer.dropEffect = this.getCurrentDropEffect();\n                }\n            }\n            else if (this.isDraggingNativeItem()) {\n                // Don't show a nice cursor but still prevent default\n                // \"drop and blow away the whole document\" action.\n                e.preventDefault();\n            }\n            else {\n                e.preventDefault();\n                if (e.dataTransfer) {\n                    e.dataTransfer.dropEffect = 'none';\n                }\n            }\n        };\n        this.handleTopDragLeaveCapture = (e) => {\n            if (this.isDraggingNativeItem()) {\n                e.preventDefault();\n            }\n            const isLastLeave = this.enterLeaveCounter.leave(e.target);\n            if (!isLastLeave) {\n                return;\n            }\n            if (this.isDraggingNativeItem()) {\n                this.endDragNativeItem();\n            }\n        };\n        this.handleTopDropCapture = (e) => {\n            this.dropTargetIds = [];\n            e.preventDefault();\n            if (this.isDraggingNativeItem()) {\n                this.currentNativeSource.mutateItemByReadingDataTransfer(e.dataTransfer);\n            }\n            this.enterLeaveCounter.reset();\n        };\n        this.handleTopDrop = (e) => {\n            const { dropTargetIds } = this;\n            this.dropTargetIds = [];\n            this.dispatcher.hover(dropTargetIds, {\n                clientOffset: Object(_OffsetUtils__WEBPACK_IMPORTED_MODULE_2__[\"getEventClientOffset\"])(e),\n            });\n            this.dispatcher.drop({ dropEffect: this.getCurrentDropEffect() });\n            if (this.isDraggingNativeItem()) {\n                this.endDragNativeItem();\n            }\n            else {\n                this.endDragIfSourceWasRemovedFromDOM();\n            }\n        };\n        this.handleSelectStart = (e) => {\n            const target = e.target;\n            // Only IE requires us to explicitly say\n            // we want drag drop operation to start\n            if (typeof target.dragDrop !== 'function') {\n                return;\n            }\n            // Inputs and textareas should be selectable\n            if (target.tagName === 'INPUT' ||\n                target.tagName === 'SELECT' ||\n                target.tagName === 'TEXTAREA' ||\n                target.isContentEditable) {\n                return;\n            }\n            // For other targets, ask IE\n            // to enable drag and drop\n            e.preventDefault();\n            target.dragDrop();\n        };\n        this.options = new _OptionsReader__WEBPACK_IMPORTED_MODULE_5__[\"OptionsReader\"](globalContext);\n        this.dispatcher = manager.getActions();\n        this.monitor = manager.getMonitor();\n        this.registry = manager.getRegistry();\n        this.enterLeaveCounter = new _EnterLeaveCounter__WEBPACK_IMPORTED_MODULE_0__[\"default\"](this.isNodeInDocument);\n    }\n    // public for test\n    get window() {\n        return this.options.window;\n    }\n    get document() {\n        return this.options.document;\n    }\n    setup() {\n        if (this.window === undefined) {\n            return;\n        }\n        if (this.window.__isReactDndBackendSetUp) {\n            throw new Error('Cannot have two HTML5 backends at the same time.');\n        }\n        this.window.__isReactDndBackendSetUp = true;\n        this.addEventListeners(this.window);\n    }\n    teardown() {\n        if (this.window === undefined) {\n            return;\n        }\n        this.window.__isReactDndBackendSetUp = false;\n        this.removeEventListeners(this.window);\n        this.clearCurrentDragSourceNode();\n        if (this.asyncEndDragFrameId) {\n            this.window.cancelAnimationFrame(this.asyncEndDragFrameId);\n        }\n    }\n    connectDragPreview(sourceId, node, options) {\n        this.sourcePreviewNodeOptions.set(sourceId, options);\n        this.sourcePreviewNodes.set(sourceId, node);\n        return () => {\n            this.sourcePreviewNodes.delete(sourceId);\n            this.sourcePreviewNodeOptions.delete(sourceId);\n        };\n    }\n    connectDragSource(sourceId, node, options) {\n        this.sourceNodes.set(sourceId, node);\n        this.sourceNodeOptions.set(sourceId, options);\n        const handleDragStart = (e) => this.handleDragStart(e, sourceId);\n        const handleSelectStart = (e) => this.handleSelectStart(e);\n        node.setAttribute('draggable', 'true');\n        node.addEventListener('dragstart', handleDragStart);\n        node.addEventListener('selectstart', handleSelectStart);\n        return () => {\n            this.sourceNodes.delete(sourceId);\n            this.sourceNodeOptions.delete(sourceId);\n            node.removeEventListener('dragstart', handleDragStart);\n            node.removeEventListener('selectstart', handleSelectStart);\n            node.setAttribute('draggable', 'false');\n        };\n    }\n    connectDropTarget(targetId, node) {\n        const handleDragEnter = (e) => this.handleDragEnter(e, targetId);\n        const handleDragOver = (e) => this.handleDragOver(e, targetId);\n        const handleDrop = (e) => this.handleDrop(e, targetId);\n        node.addEventListener('dragenter', handleDragEnter);\n        node.addEventListener('dragover', handleDragOver);\n        node.addEventListener('drop', handleDrop);\n        return () => {\n            node.removeEventListener('dragenter', handleDragEnter);\n            node.removeEventListener('dragover', handleDragOver);\n            node.removeEventListener('drop', handleDrop);\n        };\n    }\n    addEventListeners(target) {\n        // SSR Fix (https://github.com/react-dnd/react-dnd/pull/813\n        if (!target.addEventListener) {\n            return;\n        }\n        target.addEventListener('dragstart', this\n            .handleTopDragStart);\n        target.addEventListener('dragstart', this.handleTopDragStartCapture, true);\n        target.addEventListener('dragend', this.handleTopDragEndCapture, true);\n        target.addEventListener('dragenter', this\n            .handleTopDragEnter);\n        target.addEventListener('dragenter', this.handleTopDragEnterCapture, true);\n        target.addEventListener('dragleave', this.handleTopDragLeaveCapture, true);\n        target.addEventListener('dragover', this.handleTopDragOver);\n        target.addEventListener('dragover', this.handleTopDragOverCapture, true);\n        target.addEventListener('drop', this.handleTopDrop);\n        target.addEventListener('drop', this.handleTopDropCapture, true);\n    }\n    removeEventListeners(target) {\n        // SSR Fix (https://github.com/react-dnd/react-dnd/pull/813\n        if (!target.removeEventListener) {\n            return;\n        }\n        target.removeEventListener('dragstart', this.handleTopDragStart);\n        target.removeEventListener('dragstart', this.handleTopDragStartCapture, true);\n        target.removeEventListener('dragend', this.handleTopDragEndCapture, true);\n        target.removeEventListener('dragenter', this\n            .handleTopDragEnter);\n        target.removeEventListener('dragenter', this.handleTopDragEnterCapture, true);\n        target.removeEventListener('dragleave', this.handleTopDragLeaveCapture, true);\n        target.removeEventListener('dragover', this\n            .handleTopDragOver);\n        target.removeEventListener('dragover', this.handleTopDragOverCapture, true);\n        target.removeEventListener('drop', this.handleTopDrop);\n        target.removeEventListener('drop', this.handleTopDropCapture, true);\n    }\n    getCurrentSourceNodeOptions() {\n        const sourceId = this.monitor.getSourceId();\n        const sourceNodeOptions = this.sourceNodeOptions.get(sourceId);\n        return {\n            dropEffect: this.altKeyPressed ? 'copy' : 'move',\n            ...(sourceNodeOptions || {}),\n        };\n    }\n    getCurrentDropEffect() {\n        if (this.isDraggingNativeItem()) {\n            // It makes more sense to default to 'copy' for native resources\n            return 'copy';\n        }\n        return this.getCurrentSourceNodeOptions().dropEffect;\n    }\n    getCurrentSourcePreviewNodeOptions() {\n        const sourceId = this.monitor.getSourceId();\n        const sourcePreviewNodeOptions = this.sourcePreviewNodeOptions.get(sourceId);\n        return {\n            anchorX: 0.5,\n            anchorY: 0.5,\n            captureDraggingState: false,\n            ...(sourcePreviewNodeOptions || {}),\n        };\n    }\n    isDraggingNativeItem() {\n        const itemType = this.monitor.getItemType();\n        return Object.keys(_NativeTypes__WEBPACK_IMPORTED_MODULE_4__).some((key) => _NativeTypes__WEBPACK_IMPORTED_MODULE_4__[key] === itemType);\n    }\n    beginDragNativeItem(type) {\n        this.clearCurrentDragSourceNode();\n        this.currentNativeSource = Object(_NativeDragSources__WEBPACK_IMPORTED_MODULE_3__[\"createNativeDragSource\"])(type);\n        this.currentNativeHandle = this.registry.addSource(type, this.currentNativeSource);\n        this.dispatcher.beginDrag([this.currentNativeHandle]);\n    }\n    setCurrentDragSourceNode(node) {\n        this.clearCurrentDragSourceNode();\n        this.currentDragSourceNode = node;\n        // A timeout of > 0 is necessary to resolve Firefox issue referenced\n        // See:\n        //   * https://github.com/react-dnd/react-dnd/pull/928\n        //   * https://github.com/react-dnd/react-dnd/issues/869\n        const MOUSE_MOVE_TIMEOUT = 1000;\n        // Receiving a mouse event in the middle of a dragging operation\n        // means it has ended and the drag source node disappeared from DOM,\n        // so the browser didn't dispatch the dragend event.\n        //\n        // We need to wait before we start listening for mousemove events.\n        // This is needed because the drag preview needs to be drawn or else it fires an 'mousemove' event\n        // immediately in some browsers.\n        //\n        // See:\n        //   * https://github.com/react-dnd/react-dnd/pull/928\n        //   * https://github.com/react-dnd/react-dnd/issues/869\n        //\n        this.mouseMoveTimeoutTimer = setTimeout(() => {\n            return (this.window &&\n                this.window.addEventListener('mousemove', this.endDragIfSourceWasRemovedFromDOM, true));\n        }, MOUSE_MOVE_TIMEOUT);\n    }\n    clearCurrentDragSourceNode() {\n        if (this.currentDragSourceNode) {\n            this.currentDragSourceNode = null;\n            if (this.window) {\n                this.window.clearTimeout(this.mouseMoveTimeoutTimer || undefined);\n                this.window.removeEventListener('mousemove', this.endDragIfSourceWasRemovedFromDOM, true);\n            }\n            this.mouseMoveTimeoutTimer = null;\n            return true;\n        }\n        return false;\n    }\n    handleDragStart(e, sourceId) {\n        if (e.defaultPrevented) {\n            return;\n        }\n        if (!this.dragStartSourceIds) {\n            this.dragStartSourceIds = [];\n        }\n        this.dragStartSourceIds.unshift(sourceId);\n    }\n    handleDragEnter(e, targetId) {\n        this.dragEnterTargetIds.unshift(targetId);\n    }\n    handleDragOver(e, targetId) {\n        if (this.dragOverTargetIds === null) {\n            this.dragOverTargetIds = [];\n        }\n        this.dragOverTargetIds.unshift(targetId);\n    }\n    handleDrop(e, targetId) {\n        this.dropTargetIds.unshift(targetId);\n    }\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/HTML5Backend.js?");

/***/ }),

/***/ "./lib/MonotonicInterpolant.js":
/*!*************************************!*\
  !*** ./lib/MonotonicInterpolant.js ***!
  \*************************************/
/*! exports provided: default */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"default\", function() { return MonotonicInterpolant; });\nclass MonotonicInterpolant {\n    constructor(xs, ys) {\n        const { length } = xs;\n        // Rearrange xs and ys so that xs is sorted\n        const indexes = [];\n        for (let i = 0; i < length; i++) {\n            indexes.push(i);\n        }\n        indexes.sort((a, b) => (xs[a] < xs[b] ? -1 : 1));\n        // Get consecutive differences and slopes\n        const dys = [];\n        const dxs = [];\n        const ms = [];\n        let dx;\n        let dy;\n        for (let i = 0; i < length - 1; i++) {\n            dx = xs[i + 1] - xs[i];\n            dy = ys[i + 1] - ys[i];\n            dxs.push(dx);\n            dys.push(dy);\n            ms.push(dy / dx);\n        }\n        // Get degree-1 coefficients\n        const c1s = [ms[0]];\n        for (let i = 0; i < dxs.length - 1; i++) {\n            const m2 = ms[i];\n            const mNext = ms[i + 1];\n            if (m2 * mNext <= 0) {\n                c1s.push(0);\n            }\n            else {\n                dx = dxs[i];\n                const dxNext = dxs[i + 1];\n                const common = dx + dxNext;\n                c1s.push((3 * common) / ((common + dxNext) / m2 + (common + dx) / mNext));\n            }\n        }\n        c1s.push(ms[ms.length - 1]);\n        // Get degree-2 and degree-3 coefficients\n        const c2s = [];\n        const c3s = [];\n        let m;\n        for (let i = 0; i < c1s.length - 1; i++) {\n            m = ms[i];\n            const c1 = c1s[i];\n            const invDx = 1 / dxs[i];\n            const common = c1 + c1s[i + 1] - m - m;\n            c2s.push((m - c1 - common) * invDx);\n            c3s.push(common * invDx * invDx);\n        }\n        this.xs = xs;\n        this.ys = ys;\n        this.c1s = c1s;\n        this.c2s = c2s;\n        this.c3s = c3s;\n    }\n    interpolate(x) {\n        const { xs, ys, c1s, c2s, c3s } = this;\n        // The rightmost point in the dataset should give an exact result\n        let i = xs.length - 1;\n        if (x === xs[i]) {\n            return ys[i];\n        }\n        // Search for the interval x is in, returning the corresponding y if x is one of the original xs\n        let low = 0;\n        let high = c3s.length - 1;\n        let mid;\n        while (low <= high) {\n            mid = Math.floor(0.5 * (low + high));\n            const xHere = xs[mid];\n            if (xHere < x) {\n                low = mid + 1;\n            }\n            else if (xHere > x) {\n                high = mid - 1;\n            }\n            else {\n                return ys[mid];\n            }\n        }\n        i = Math.max(0, high);\n        // Interpolate\n        const diff = x - xs[i];\n        const diffSq = diff * diff;\n        return ys[i] + c1s[i] * diff + c2s[i] * diffSq + c3s[i] * diff * diffSq;\n    }\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/MonotonicInterpolant.js?");

/***/ }),

/***/ "./lib/NativeDragSources/NativeDragSource.js":
/*!***************************************************!*\
  !*** ./lib/NativeDragSources/NativeDragSource.js ***!
  \***************************************************/
/*! exports provided: NativeDragSource */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"NativeDragSource\", function() { return NativeDragSource; });\nclass NativeDragSource {\n    constructor(config) {\n        this.config = config;\n        this.item = {};\n        Object.keys(this.config.exposeProperties).forEach(property => {\n            Object.defineProperty(this.item, property, {\n                configurable: true,\n                enumerable: true,\n                get() {\n                    // eslint-disable-next-line no-console\n                    console.warn(`Browser doesn't allow reading \"${property}\" until the drop event.`);\n                    return null;\n                },\n            });\n        });\n    }\n    mutateItemByReadingDataTransfer(dataTransfer) {\n        const newProperties = {};\n        if (dataTransfer) {\n            Object.keys(this.config.exposeProperties).forEach(property => {\n                newProperties[property] = {\n                    value: this.config.exposeProperties[property](dataTransfer, this.config.matchesTypes),\n                };\n            });\n        }\n        Object.defineProperties(this.item, newProperties);\n    }\n    canDrag() {\n        return true;\n    }\n    beginDrag() {\n        return this.item;\n    }\n    isDragging(monitor, handle) {\n        return handle === monitor.getSourceId();\n    }\n    endDrag() {\n        // empty\n    }\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/NativeDragSources/NativeDragSource.js?");

/***/ }),

/***/ "./lib/NativeDragSources/getDataFromDataTransfer.js":
/*!**********************************************************!*\
  !*** ./lib/NativeDragSources/getDataFromDataTransfer.js ***!
  \**********************************************************/
/*! exports provided: getDataFromDataTransfer */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"getDataFromDataTransfer\", function() { return getDataFromDataTransfer; });\nfunction getDataFromDataTransfer(dataTransfer, typesToTry, defaultValue) {\n    const result = typesToTry.reduce((resultSoFar, typeToTry) => resultSoFar || dataTransfer.getData(typeToTry), '');\n    return result != null ? result : defaultValue;\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/NativeDragSources/getDataFromDataTransfer.js?");

/***/ }),

/***/ "./lib/NativeDragSources/index.js":
/*!****************************************!*\
  !*** ./lib/NativeDragSources/index.js ***!
  \****************************************/
/*! exports provided: createNativeDragSource, matchNativeItemType */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"createNativeDragSource\", function() { return createNativeDragSource; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"matchNativeItemType\", function() { return matchNativeItemType; });\n/* harmony import */ var _nativeTypesConfig__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./nativeTypesConfig */ \"./lib/NativeDragSources/nativeTypesConfig.js\");\n/* harmony import */ var _NativeDragSource__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./NativeDragSource */ \"./lib/NativeDragSources/NativeDragSource.js\");\n\n\nfunction createNativeDragSource(type) {\n    return new _NativeDragSource__WEBPACK_IMPORTED_MODULE_1__[\"NativeDragSource\"](_nativeTypesConfig__WEBPACK_IMPORTED_MODULE_0__[\"nativeTypesConfig\"][type]);\n}\nfunction matchNativeItemType(dataTransfer) {\n    if (!dataTransfer) {\n        return null;\n    }\n    const dataTransferTypes = Array.prototype.slice.call(dataTransfer.types || []);\n    return (Object.keys(_nativeTypesConfig__WEBPACK_IMPORTED_MODULE_0__[\"nativeTypesConfig\"]).filter(nativeItemType => {\n        const { matchesTypes } = _nativeTypesConfig__WEBPACK_IMPORTED_MODULE_0__[\"nativeTypesConfig\"][nativeItemType];\n        return matchesTypes.some(t => dataTransferTypes.indexOf(t) > -1);\n    })[0] || null);\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/NativeDragSources/index.js?");

/***/ }),

/***/ "./lib/NativeDragSources/nativeTypesConfig.js":
/*!****************************************************!*\
  !*** ./lib/NativeDragSources/nativeTypesConfig.js ***!
  \****************************************************/
/*! exports provided: nativeTypesConfig */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"nativeTypesConfig\", function() { return nativeTypesConfig; });\n/* harmony import */ var _NativeTypes__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ../NativeTypes */ \"./lib/NativeTypes.js\");\n/* harmony import */ var _getDataFromDataTransfer__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./getDataFromDataTransfer */ \"./lib/NativeDragSources/getDataFromDataTransfer.js\");\n\n\nconst nativeTypesConfig = {\n    [_NativeTypes__WEBPACK_IMPORTED_MODULE_0__[\"FILE\"]]: {\n        exposeProperties: {\n            files: (dataTransfer) => Array.prototype.slice.call(dataTransfer.files),\n            items: (dataTransfer) => dataTransfer.items,\n        },\n        matchesTypes: ['Files'],\n    },\n    [_NativeTypes__WEBPACK_IMPORTED_MODULE_0__[\"URL\"]]: {\n        exposeProperties: {\n            urls: (dataTransfer, matchesTypes) => Object(_getDataFromDataTransfer__WEBPACK_IMPORTED_MODULE_1__[\"getDataFromDataTransfer\"])(dataTransfer, matchesTypes, '').split('\\n'),\n        },\n        matchesTypes: ['Url', 'text/uri-list'],\n    },\n    [_NativeTypes__WEBPACK_IMPORTED_MODULE_0__[\"TEXT\"]]: {\n        exposeProperties: {\n            text: (dataTransfer, matchesTypes) => Object(_getDataFromDataTransfer__WEBPACK_IMPORTED_MODULE_1__[\"getDataFromDataTransfer\"])(dataTransfer, matchesTypes, ''),\n        },\n        matchesTypes: ['Text', 'text/plain'],\n    },\n};\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/NativeDragSources/nativeTypesConfig.js?");

/***/ }),

/***/ "./lib/NativeTypes.js":
/*!****************************!*\
  !*** ./lib/NativeTypes.js ***!
  \****************************/
/*! exports provided: FILE, URL, TEXT */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"FILE\", function() { return FILE; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"URL\", function() { return URL; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"TEXT\", function() { return TEXT; });\nconst FILE = '__NATIVE_FILE__';\nconst URL = '__NATIVE_URL__';\nconst TEXT = '__NATIVE_TEXT__';\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/NativeTypes.js?");

/***/ }),

/***/ "./lib/OffsetUtils.js":
/*!****************************!*\
  !*** ./lib/OffsetUtils.js ***!
  \****************************/
/*! exports provided: getNodeClientOffset, getEventClientOffset, getDragPreviewOffset */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"getNodeClientOffset\", function() { return getNodeClientOffset; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"getEventClientOffset\", function() { return getEventClientOffset; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"getDragPreviewOffset\", function() { return getDragPreviewOffset; });\n/* harmony import */ var _BrowserDetector__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./BrowserDetector */ \"./lib/BrowserDetector.js\");\n/* harmony import */ var _MonotonicInterpolant__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./MonotonicInterpolant */ \"./lib/MonotonicInterpolant.js\");\n\n\nconst ELEMENT_NODE = 1;\nfunction getNodeClientOffset(node) {\n    const el = node.nodeType === ELEMENT_NODE ? node : node.parentElement;\n    if (!el) {\n        return null;\n    }\n    const { top, left } = el.getBoundingClientRect();\n    return { x: left, y: top };\n}\nfunction getEventClientOffset(e) {\n    return {\n        x: e.clientX,\n        y: e.clientY,\n    };\n}\nfunction isImageNode(node) {\n    return (node.nodeName === 'IMG' &&\n        (Object(_BrowserDetector__WEBPACK_IMPORTED_MODULE_0__[\"isFirefox\"])() || !document.documentElement.contains(node)));\n}\nfunction getDragPreviewSize(isImage, dragPreview, sourceWidth, sourceHeight) {\n    let dragPreviewWidth = isImage ? dragPreview.width : sourceWidth;\n    let dragPreviewHeight = isImage ? dragPreview.height : sourceHeight;\n    // Work around @2x coordinate discrepancies in browsers\n    if (Object(_BrowserDetector__WEBPACK_IMPORTED_MODULE_0__[\"isSafari\"])() && isImage) {\n        dragPreviewHeight /= window.devicePixelRatio;\n        dragPreviewWidth /= window.devicePixelRatio;\n    }\n    return { dragPreviewWidth, dragPreviewHeight };\n}\nfunction getDragPreviewOffset(sourceNode, dragPreview, clientOffset, anchorPoint, offsetPoint) {\n    // The browsers will use the image intrinsic size under different conditions.\n    // Firefox only cares if it's an image, but WebKit also wants it to be detached.\n    const isImage = isImageNode(dragPreview);\n    const dragPreviewNode = isImage ? sourceNode : dragPreview;\n    const dragPreviewNodeOffsetFromClient = getNodeClientOffset(dragPreviewNode);\n    const offsetFromDragPreview = {\n        x: clientOffset.x - dragPreviewNodeOffsetFromClient.x,\n        y: clientOffset.y - dragPreviewNodeOffsetFromClient.y,\n    };\n    const { offsetWidth: sourceWidth, offsetHeight: sourceHeight } = sourceNode;\n    const { anchorX, anchorY } = anchorPoint;\n    const { dragPreviewWidth, dragPreviewHeight } = getDragPreviewSize(isImage, dragPreview, sourceWidth, sourceHeight);\n    const calculateYOffset = () => {\n        const interpolantY = new _MonotonicInterpolant__WEBPACK_IMPORTED_MODULE_1__[\"default\"]([0, 0.5, 1], [\n            // Dock to the top\n            offsetFromDragPreview.y,\n            // Align at the center\n            (offsetFromDragPreview.y / sourceHeight) * dragPreviewHeight,\n            // Dock to the bottom\n            offsetFromDragPreview.y + dragPreviewHeight - sourceHeight,\n        ]);\n        let y = interpolantY.interpolate(anchorY);\n        // Work around Safari 8 positioning bug\n        if (Object(_BrowserDetector__WEBPACK_IMPORTED_MODULE_0__[\"isSafari\"])() && isImage) {\n            // We'll have to wait for @3x to see if this is entirely correct\n            y += (window.devicePixelRatio - 1) * dragPreviewHeight;\n        }\n        return y;\n    };\n    const calculateXOffset = () => {\n        // Interpolate coordinates depending on anchor point\n        // If you know a simpler way to do this, let me know\n        const interpolantX = new _MonotonicInterpolant__WEBPACK_IMPORTED_MODULE_1__[\"default\"]([0, 0.5, 1], [\n            // Dock to the left\n            offsetFromDragPreview.x,\n            // Align at the center\n            (offsetFromDragPreview.x / sourceWidth) * dragPreviewWidth,\n            // Dock to the right\n            offsetFromDragPreview.x + dragPreviewWidth - sourceWidth,\n        ]);\n        return interpolantX.interpolate(anchorX);\n    };\n    // Force offsets if specified in the options.\n    const { offsetX, offsetY } = offsetPoint;\n    const isManualOffsetX = offsetX === 0 || offsetX;\n    const isManualOffsetY = offsetY === 0 || offsetY;\n    return {\n        x: isManualOffsetX ? offsetX : calculateXOffset(),\n        y: isManualOffsetY ? offsetY : calculateYOffset(),\n    };\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/OffsetUtils.js?");

/***/ }),

/***/ "./lib/OptionsReader.js":
/*!******************************!*\
  !*** ./lib/OptionsReader.js ***!
  \******************************/
/*! exports provided: OptionsReader */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"OptionsReader\", function() { return OptionsReader; });\nclass OptionsReader {\n    constructor(globalContext) {\n        this.globalContext = globalContext;\n    }\n    get window() {\n        if (this.globalContext) {\n            return this.globalContext;\n        }\n        else if (typeof window !== 'undefined') {\n            return window;\n        }\n        return undefined;\n    }\n    get document() {\n        if (this.window) {\n            return this.window.document;\n        }\n        return undefined;\n    }\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/OptionsReader.js?");

/***/ }),

/***/ "./lib/getEmptyImage.js":
/*!******************************!*\
  !*** ./lib/getEmptyImage.js ***!
  \******************************/
/*! exports provided: getEmptyImage */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"getEmptyImage\", function() { return getEmptyImage; });\nlet emptyImage;\nfunction getEmptyImage() {\n    if (!emptyImage) {\n        emptyImage = new Image();\n        emptyImage.src =\n            'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';\n    }\n    return emptyImage;\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/getEmptyImage.js?");

/***/ }),

/***/ "./lib/index.js":
/*!**********************!*\
  !*** ./lib/index.js ***!
  \**********************/
/*! exports provided: getEmptyImage, NativeTypes, default */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony import */ var _HTML5Backend__WEBPACK_IMPORTED_MODULE_0__ = __webpack_require__(/*! ./HTML5Backend */ \"./lib/HTML5Backend.js\");\n/* harmony import */ var _NativeTypes__WEBPACK_IMPORTED_MODULE_1__ = __webpack_require__(/*! ./NativeTypes */ \"./lib/NativeTypes.js\");\n/* harmony reexport (module object) */ __webpack_require__.d(__webpack_exports__, \"NativeTypes\", function() { return _NativeTypes__WEBPACK_IMPORTED_MODULE_1__; });\n/* harmony import */ var _getEmptyImage__WEBPACK_IMPORTED_MODULE_2__ = __webpack_require__(/*! ./getEmptyImage */ \"./lib/getEmptyImage.js\");\n/* harmony reexport (safe) */ __webpack_require__.d(__webpack_exports__, \"getEmptyImage\", function() { return _getEmptyImage__WEBPACK_IMPORTED_MODULE_2__[\"getEmptyImage\"]; });\n\n\n\n\n\nconst createHTML5Backend = (manager, context) => new _HTML5Backend__WEBPACK_IMPORTED_MODULE_0__[\"default\"](manager, context);\n/* harmony default export */ __webpack_exports__[\"default\"] = (createHTML5Backend);\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/index.js?");

/***/ }),

/***/ "./lib/utils/js_utils.js":
/*!*******************************!*\
  !*** ./lib/utils/js_utils.js ***!
  \*******************************/
/*! exports provided: memoize, without, union */
/***/ (function(module, __webpack_exports__, __webpack_require__) {

"use strict";
eval("__webpack_require__.r(__webpack_exports__);\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"memoize\", function() { return memoize; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"without\", function() { return without; });\n/* harmony export (binding) */ __webpack_require__.d(__webpack_exports__, \"union\", function() { return union; });\n// cheap lodash replacements\nfunction memoize(fn) {\n    let result = null;\n    const memoized = () => {\n        if (result == null) {\n            result = fn();\n        }\n        return result;\n    };\n    return memoized;\n}\n/**\n * drop-in replacement for _.without\n */\nfunction without(items, item) {\n    return items.filter(i => i !== item);\n}\nfunction union(itemsA, itemsB) {\n    const set = new Set();\n    const insertItem = (item) => set.add(item);\n    itemsA.forEach(insertItem);\n    itemsB.forEach(insertItem);\n    const result = [];\n    set.forEach(key => result.push(key));\n    return result;\n}\n\n\n//# sourceURL=webpack://ReactDnDHTML5Backend/./lib/utils/js_utils.js?");

/***/ })

/******/ });
});